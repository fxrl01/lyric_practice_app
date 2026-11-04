import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../song_recognition/domain/entities/song.dart';

/// Datasource local para almacenar historial de canciones reconocidas
///
/// Usa SharedPreferences para persistencia simple.
/// Solo almacena metadata (título, artista, etc.), NUNCA letras.
abstract class SongRecognitionLocalDataSource {
  /// Obtener historial de canciones
  Future<List<Song>> getHistory();

  /// Agregar canción al historial
  Future<void> addToHistory(Song song);

  /// Limpiar todo el historial
  Future<void> clearHistory();

  /// Verificar si una canción ya fue reconocida
  Future<bool> isInHistory(String songId);
}

/// Implementación con SharedPreferences
class SongRecognitionLocalDataSourceImpl
    implements SongRecognitionLocalDataSource {
  static const _historyKey = 'lyricflow_recognition_history';
  static const _maxHistoryItems = 50;

  final SharedPreferences _prefs;

  SongRecognitionLocalDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  @override
  Future<List<Song>> getHistory() async {
    try {
      final jsonString = _prefs.getString(_historyKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final jsonList = json.decode(jsonString) as List<dynamic>;
      return List<Song>.from(jsonList.map((item) => _songFromJson(item as Map<String, dynamic>)));
    } catch (e) {
      throw CacheException(
        message: 'Error al leer historial: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> addToHistory(Song song) async {
    try {
      final history = await getHistory();

      // Remover duplicado si existe
      history.removeWhere((s) => s.id == song.id);

      // Insertar al inicio
      history.insert(0, song);

      // Limitar tamaño
      final trimmed = history.take(_maxHistoryItems).toList();

      // Serializar y guardar
      final jsonList = trimmed.map(_songToJson).toList();
      await _prefs.setString(_historyKey, json.encode(jsonList));
    } catch (e) {
      throw CacheException(
        message: 'Error al guardar en historial: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> clearHistory() async {
    try {
      await _prefs.remove(_historyKey);
    } catch (e) {
      throw CacheException(
        message: 'Error al limpiar historial: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isInHistory(String songId) async {
    final history = await getHistory();
    return history.any((s) => s.id == songId);
  }

  // ─── Serialización manual (sin code gen) ───

  Map<String, dynamic> _songToJson(Song song) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'durationMs': song.durationMs,
      'releaseDate': song.releaseDate?.toIso8601String(),
      'coverUrl': song.coverUrl,
      'genre': song.genre,
      'isrc': song.isrc,
      'source': song.source,
      'hasLyrics': song.hasLyrics,
      'confidence': song.confidence,
      'recognizedAt': song.recognizedAt.toIso8601String(),
      'externalLinks': song.externalLinks,
    };
  }

  Song _songFromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      durationMs: json['durationMs'] as int?,
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'])
          : null,
      coverUrl: json['coverUrl'] as String?,
      genre: json['genre'] as String?,
      isrc: json['isrc'] as String?,
      source: json['source'] as String? ?? 'unknown',
      hasLyrics: json['hasLyrics'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble(),
      recognizedAt: json['recognizedAt'] != null
          ? DateTime.tryParse(json['recognizedAt'])
          : null,
      externalLinks: json['externalLinks'] != null
          ? Map<String, String>.from(json['externalLinks'])
          : const {},
    );
  }
}
