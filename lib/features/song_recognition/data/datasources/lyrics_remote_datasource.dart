import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/lyrics.dart';

/// Datasource remoto para obtener letras de canciones
abstract class LyricsRemoteDataSource {
  Future<Lyrics> getLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
    int? duration,
  });

  Future<Lyrics> getSyncedLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
  });

  Future<List<Lyrics>> searchByLyricText({required String query});

  Future<bool> hasLyrics({
    required String songTitle,
    required String artist,
  });
}

/// Adaptador de letras a través del backend propio.
class BackendLyricsRemoteDataSource implements LyricsRemoteDataSource {
  final ApiClient _apiClient;
  final String _baseUrl;

  BackendLyricsRemoteDataSource({
    required ApiClient apiClient,
    required String baseUrl,
  })  : _apiClient = apiClient,
        _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  @override
  Future<Lyrics> getLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
    int? duration,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_baseUrl/api/v1/lyrics',
      queryParameters: {'title': songTitle, 'artist': artist},
    );
    return _parse(response.data);
  }

  @override
  Future<Lyrics> getSyncedLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
  }) {
    return getLyrics(songTitle: songTitle, artist: artist, isrc: isrc);
  }

  @override
  Future<List<Lyrics>> searchByLyricText({required String query}) {
    throw UnimplementedError(
      'Lyric text search is not available through the backend yet.',
    );
  }

  @override
  Future<bool> hasLyrics({
    required String songTitle,
    required String artist,
  }) async {
    try {
      await getLyrics(songTitle: songTitle, artist: artist);
      return true;
    } catch (_) {
      return false;
    }
  }

  Lyrics _parse(Map<String, dynamic>? data) {
    if (data == null || data['lines'] is! List) {
      throw Exception('El backend devolvió letras inválidas.');
    }
    final lines = (data['lines'] as List)
        .whereType<String>()
        .map((text) => LyricLine(text: text))
        .toList();
    return Lyrics(
      songId: data['song_id'] as String? ?? '',
      lines: lines,
      language: data['language'] as String? ?? 'unknown',
      source: LyricsSource.userContributed,
      attribution: data['attribution'] as String?,
    );
  }
}

/// Implementación usando lyrics.ovh + Musixmatch como fallback
///
/// lyrics.ovh es 100% gratis, sin API key, sin registro.
/// Musixmatch requiere API key gratuita para letras sincronizadas.
class MusixmatchRemoteDataSource implements LyricsRemoteDataSource {
  final ApiClient _apiClient;
  final String _apiKey;
  final String _musixmatchBaseUrl;

  // lyrics.ovh es gratis y sin key
  static const _lyricsOvhBaseUrl = 'https://api.lyrics.ovh/v1';

  MusixmatchRemoteDataSource({
    required ApiClient apiClient,
    required String apiKey,
    String baseUrl = 'https://api.musixmatch.com/ws/1.1',
  })  : _apiClient = apiClient,
        _apiKey = apiKey,
        _musixmatchBaseUrl = baseUrl;

  @override
  Future<Lyrics> getLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
    int? duration,
  }) async {
    // Estrategia: lyrics.ovh primero (gratis), Musixmatch fallback
    try {
      return await _getLyricsFromLyricsOvh(songTitle, artist);
    } catch (e) {
      // Fallback a Musixmatch si hay API key
      if (_apiKey.isNotEmpty) {
        try {
          return await _getLyricsFromMusixmatch(songTitle, artist, isrc);
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// lyrics.ovh — 100% gratis, sin key
  Future<Lyrics> _getLyricsFromLyricsOvh(String title, String artist) async {
    try {
      // Limpiar caracteres especiales
      final cleanArtist = Uri.encodeComponent(artist.trim());
      final cleanTitle = Uri.encodeComponent(title.trim());

      final response = await _apiClient.get<Map<String, dynamic>>(
        '$_lyricsOvhBaseUrl/$cleanArtist/$cleanTitle',
      );

      final data = response.data;
      if (data == null || data['lyrics'] == null) {
        throw Exception('Letras no encontradas');
      }

      final lyricsText = data['lyrics'] as String;
      if (lyricsText.trim().isEmpty) {
        throw Exception('Letras vacías');
      }

      // Parsear texto a líneas
      final lines = lyricsText
          .split('\n')
          .map((line) => LyricLine(text: line.trim()))
          .toList();

      // Detectar idioma basado en caracteres comunes
      final lang = _detectLanguage(lyricsText);

      return Lyrics(
        songId: '${artist}_$title'.replaceAll(' ', '_').toLowerCase(),
        lines: lines,
        language: lang,
        source: LyricsSource.userContributed,
        isSynced: false,
        attribution: 'Lyrics via lyrics.ovh',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Letras no encontradas para "$title" de $artist');
      }
      throw Exception('Error al buscar letras: ${e.message}');
    }
  }

  /// Musixmatch — requiere API key gratuita
  Future<Lyrics> _getLyricsFromMusixmatch(
    String title,
    String artist,
    String? isrc,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_musixmatchBaseUrl/matcher.lyrics.get',
      queryParameters: {
        'q_track': title,
        'q_artist': artist,
        if (isrc != null) 'track_isrc': isrc,
        'apikey': _apiKey,
      },
    );

    final data = response.data;
    final body = data?['message']?['body'] as Map<String, dynamic>?;
    final lyricsData = body?['lyrics'] as Map<String, dynamic>?;

    if (lyricsData == null || lyricsData['lyrics_body'] == null) {
      throw Exception('Letras no disponibles en Musixmatch');
    }

    final lyricsText = lyricsData['lyrics_body'] as String;
    final lines = lyricsText
        .split('\n')
        .map((line) => LyricLine(text: line.trim()))
        .toList();

    return Lyrics(
      songId: '${artist}_$title'.replaceAll(' ', '_').toLowerCase(),
      lines: lines,
      language: lyricsData['lyrics_language'] as String? ?? 'unknown',
      source: LyricsSource.musixmatch,
      isSynced: false,
      copyright: lyricsData['lyrics_copyright'] as String?,
      attribution: 'Powered by Musixmatch',
    );
  }

  @override
  Future<Lyrics> getSyncedLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
  }) async {
    // Letras sincronizadas solo disponibles con Musixmatch API key
    if (_apiKey.isEmpty) {
      throw Exception(
        'Letras sincronizadas requieren Musixmatch API key. '
        'Regístrate gratis en https://developer.musixmatch.com',
      );
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '$_musixmatchBaseUrl/matcher.subtitle.get',
        queryParameters: {
          'q_track': songTitle,
          'q_artist': artist,
          if (isrc != null) 'track_isrc': isrc,
          'apikey': _apiKey,
          'f_subtitle_length_max_deviation': 1,
        },
      );

      final data = response.data;
      final body = data?['message']?['body'] as Map<String, dynamic>?;
      final subtitleData = body?['subtitle'] as Map<String, dynamic>?;

      if (subtitleData == null) {
        throw Exception('Letras sincronizadas no disponibles');
      }

      final subtitleBody = subtitleData['subtitle_body'] as String? ?? '';

      // Parsear formato LRC "[mm:ss.xx] texto"
      final lines = _parseLrcFormat(subtitleBody);

      return Lyrics(
        songId: '${artist}_$songTitle'.replaceAll(' ', '_').toLowerCase(),
        lines: lines,
        language: subtitleData['subtitle_language'] as String? ?? 'unknown',
        source: LyricsSource.musixmatch,
        isSynced: true,
        attribution: 'Powered by Musixmatch',
      );
    } catch (e) {
      throw Exception('Letras sincronizadas no disponibles: $e');
    }
  }

  @override
  Future<List<Lyrics>> searchByLyricText({required String query}) async {
    if (_apiKey.isEmpty) return [];

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '$_musixmatchBaseUrl/track.search',
        queryParameters: {
          'q_lyrics': query,
          'apikey': _apiKey,
          'page_size': 5,
        },
      );

      // Simplificado: retornar lista vacía por ahora
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> hasLyrics({
    required String songTitle,
    required String artist,
  }) async {
    try {
      await getLyrics(songTitle: songTitle, artist: artist);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Parsear formato LRC a lista de LyricLine
  List<LyricLine> _parseLrcFormat(String lrc) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]\s*(.*)');

    for (final line in lrc.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);
        final text = match.group(4)?.trim() ?? '';

        final startMs = (minutes * 60 + seconds) * 1000 +
            centiseconds * (match.group(3)!.length == 2 ? 10 : 1);

        lines.add(LyricLine(
          text: text,
          startTimeMs: startMs,
        ));
      }
    }

    // Calcular endTimeMs basado en el siguiente startTime
    for (int i = 0; i < lines.length - 1; i++) {
      lines[i] = LyricLine(
        text: lines[i].text,
        startTimeMs: lines[i].startTimeMs,
        endTimeMs: lines[i + 1].startTimeMs,
      );
    }

    return lines;
  }

  /// Detección simple de idioma
  String _detectLanguage(String text) {
    final lower = text.toLowerCase();
    // Español
    if (lower.contains('que ') || lower.contains('corazón') ||
        lower.contains('amor') || lower.contains('porque')) {
      return 'es';
    }
    // Portugués
    if (lower.contains('não') || lower.contains('você') ||
        lower.contains('coração')) {
      return 'pt';
    }
    // Default: inglés
    return 'en';
  }
}
