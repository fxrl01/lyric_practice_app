import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../song_recognition/domain/entities/song.dart';

/// Contrato para el datasource remoto de reconocimiento de canciones
abstract class SongRecognitionRemoteDataSource {
  Future<Song> recognizeSong({
    required List<int> audioBytes,
    required int durationMs,
  });

  Future<Song> recognizeByHumming({required List<int> audioBytes});
  Future<List<Song>> searchSong({required String query});
  Future<Song> getSongDetails({required String songId, required String source});
}

/// Implementación usando AudD.io API
///
/// AudD ofrece reconocimiento de canciones. Sin API key funciona
/// con límites bajos (perfecto para desarrollo/testing).
/// Con API key gratuita: más requests.
///
/// Registro gratuito: https://dashboard.audd.io/
class AuddRemoteDataSource implements SongRecognitionRemoteDataSource {
  final ApiClient _apiClient;
  final String _apiKey;
  static const _baseUrl = 'https://api.audd.io';

  AuddRemoteDataSource({
    required ApiClient apiClient,
    required String apiKey,
  })  : _apiClient = apiClient,
        _apiKey = apiKey;

  @override
  Future<Song> recognizeSong({
    required List<int> audioBytes,
    required int durationMs,
  }) async {
    try {
      // Si no hay API key, usar modo demo con respuesta aleatoria
      if (_apiKey.isEmpty) {
        return _getDemoSong();
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        _baseUrl,
        data: FormData.fromMap({
          'api_token': _apiKey,
          'audio': MultipartFile.fromBytes(
            audioBytes,
            filename: 'audio.wav',
          ),
          'return': 'spotify,apple_music,deezer',
        }),
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Respuesta vacía del servidor');
      }

      final status = data['status'] as String?;
      if (status == 'error') {
        final error = data['error'] as Map<String, dynamic>?;
        throw Exception(
          error?['error_message'] ?? 'Error en el reconocimiento',
        );
      }

      final result = data['result'];
      if (result == null) {
        throw Exception(
          'No se pudo reconocer la canción. Intenta en un ambiente más silencioso.',
        );
      }

      return _parseAuddResult(result as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Timeout: el servidor tardó demasiado. Intenta de nuevo.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Sin conexión a internet.');
      }
      throw Exception('Error de red: ${e.message}');
    }
  }

  @override
  Future<Song> recognizeByHumming({required List<int> audioBytes}) async {
    // AudD no soporta humming — usar recognizeSong como fallback
    return recognizeSong(audioBytes: audioBytes, durationMs: 5000);
  }

  @override
  Future<List<Song>> searchSong({required String query}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '$_baseUrl/findSong/',
        queryParameters: {
          if (_apiKey.isNotEmpty) 'api_token': _apiKey,
          'q': query,
        },
      );

      final data = response.data;
      if (data == null || data['result'] == null) return [];

      final results = data['result'] as List<dynamic>;
      return results
          .map((r) => _parseAuddResult(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Song> getSongDetails({
    required String songId,
    required String source,
  }) async {
    return Song(id: songId, title: '', artist: '', source: source);
  }

  /// Parsear respuesta de AudD a nuestra entidad Song
  Song _parseAuddResult(Map<String, dynamic> result) {
    // Links externos de plataformas
    final externalLinks = <String, String>{};

    // Spotify
    final spotify = result['spotify'] as Map<String, dynamic>?;
    if (spotify != null) {
      final spotifyUrl = spotify['external_urls']?['spotify'] as String?;
      if (spotifyUrl != null) externalLinks['spotify'] = spotifyUrl;
    }

    // Apple Music
    final appleMusic = result['apple_music'] as Map<String, dynamic>?;
    if (appleMusic != null) {
      final appleUrl = appleMusic['url'] as String?;
      if (appleUrl != null) externalLinks['apple_music'] = appleUrl;
    }

    // Deezer
    final deezer = result['deezer'] as Map<String, dynamic>?;
    if (deezer != null) {
      final deezerLink = deezer['link'] as String?;
      if (deezerLink != null) externalLinks['deezer'] = deezerLink;
    }

    // Cover URL
    String? coverUrl;
    if (spotify != null && spotify['album']?['images'] != null) {
      final images = spotify['album']['images'] as List<dynamic>;
      if (images.isNotEmpty) {
        coverUrl = images.first['url'] as String?;
      }
    }

    // Release date
    DateTime? releaseDate;
    final releaseDateStr = result['release_date'] as String?;
    if (releaseDateStr != null && releaseDateStr.isNotEmpty) {
      try {
        releaseDate = DateTime.parse(releaseDateStr);
      } catch (_) {}
    }

    // Duration
    int? durationMs;
    if (spotify != null && spotify['duration_ms'] != null) {
      durationMs = spotify['duration_ms'] as int;
    }

    // Genre
    String? genre;
    if (result['genre'] != null) {
      genre = result['genre'] as String;
    } else if (spotify != null && spotify['album']?['album_type'] != null) {
      genre = spotify['album']['album_type'] as String;
    }

    return Song(
      id: 'audd_${result['song_link'] ?? DateTime.now().millisecondsSinceEpoch}',
      title: result['title'] as String? ?? 'Desconocido',
      artist: result['artist'] as String? ?? 'Artista desconocido',
      album: result['album'] as String?,
      durationMs: durationMs,
      releaseDate: releaseDate,
      coverUrl: coverUrl,
      genre: genre,
      isrc: result['isrc'] as String?,
      source: 'audd',
      hasLyrics: true,
      confidence: 0.90, // AudD no provee score, asumimos alto
      externalLinks: externalLinks,
    );
  }

  /// Canciones demo para cuando no hay API key
  Song _getDemoSong() {
    final demoSongs = [
      {
        'title': 'Bohemian Rhapsody',
        'artist': 'Queen',
        'album': 'A Night at the Opera',
        'release_date': '1975-10-31',
        'genre': 'Rock',
        'duration': 354000,
        'isrc': 'GBANL7500001',
        'confidence': 0.95,
      },
      {
        'title': 'Blinding Lights',
        'artist': 'The Weeknd',
        'album': 'After Hours',
        'release_date': '2019-11-29',
        'genre': 'Synth-pop',
        'duration': 200000,
        'isrc': 'USUG11904757',
        'confidence': 0.92,
      },
      {
        'title': 'Despacito',
        'artist': 'Luis Fonsi ft. Daddy Yankee',
        'album': 'Despacito & Mis Grandes Éxitos',
        'release_date': '2017-01-12',
        'genre': 'Reggaeton',
        'duration': 228000,
        'isrc': 'USQ4E1700001',
        'confidence': 0.89,
      },
      {
        'title': 'Bad Guy',
        'artist': 'Billie Eilish',
        'album': 'When We All Fall Asleep, Where Do We Go?',
        'release_date': '2019-03-29',
        'genre': 'Electropop',
        'duration': 194000,
        'isrc': 'USUM71900914',
        'confidence': 0.91,
      },
      {
        'title': 'Shape of You',
        'artist': 'Ed Sheeran',
        'album': '÷ (Divide)',
        'release_date': '2017-01-06',
        'genre': 'Pop',
        'duration': 233000,
        'isrc': 'GBUM71700207',
        'confidence': 0.93,
      },
    ];

    // Seleccionar canción demo aleatoria
    final randomIndex = DateTime.now().millisecond % demoSongs.length;
    final demo = demoSongs[randomIndex];

    return Song(
      id: 'demo_${demo['title'].toString().toLowerCase().replaceAll(' ', '_')}',
      title: demo['title'] as String,
      artist: demo['artist'] as String,
      album: demo['album'] as String,
      durationMs: demo['duration'] as int,
      releaseDate: DateTime.parse(demo['release_date'] as String),
      genre: demo['genre'] as String,
      isrc: demo['isrc'] as String,
      source: 'demo',
      hasLyrics: true,
      confidence: (demo['confidence'] as num).toDouble(),
      recognizedAt: DateTime.now(),
    );
  }
}

/// Implementación usando ACRCloud API
/// Requiere registro gratuito en https://www.acrcloud.com/
class AcrCloudRemoteDataSource implements SongRecognitionRemoteDataSource {
  // Variables marked as unused but needed for future ACRCloud implementation
  final ApiClient _apiClient;
  final String _accessKey;
  final String _accessSecret;
  final String _host;

  AcrCloudRemoteDataSource({
    required ApiClient apiClient,
    required String accessKey,
    required String accessSecret,
    required String host,
  })  : _apiClient = apiClient,
        _accessKey = accessKey,
        _accessSecret = accessSecret,
        _host = host;

  @override
  Future<Song> recognizeSong({
    required List<int> audioBytes,
    required int durationMs,
  }) async {
    // ACRCloud requiere HMAC-SHA1 signing
    // TODO: Implementar firma HMAC cuando se tenga API key
    throw UnimplementedError(
      'ACRCloud requiere API keys configuradas. '
      'Registra una cuenta gratuita en https://www.acrcloud.com/',
    );
  }

  @override
  Future<Song> recognizeByHumming({required List<int> audioBytes}) async {
    throw UnimplementedError('Configura ACRCloud primero');
  }

  @override
  Future<List<Song>> searchSong({required String query}) async => [];

  @override
  Future<Song> getSongDetails({
    required String songId,
    required String source,
  }) async {
    return Song(id: songId, title: '', artist: '', source: source);
  }
}
