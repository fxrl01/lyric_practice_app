import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/transcription.dart';

/// Datasource remoto para transcripción con IA (OpenAI Whisper)
abstract class TranscriptionRemoteDataSource {
  /// Transcribir audio a texto
  Future<Transcription> transcribeAudio({
    required List<int> audioBytes,
    String audioFormat = 'wav',
    String? language,
    String model = 'whisper-1',
  });

  /// Transcribir desde URL
  Future<Transcription> transcribeFromUrl({
    required String audioUrl,
    String? language,
    String model = 'whisper-1',
  });

  /// Verificar disponibilidad del servicio
  Future<bool> isServiceAvailable();

  /// Obtener idiomas soportados
  Future<List<String>> getSupportedLanguages();
}

/// Implementación con OpenAI Whisper API
class WhisperRemoteDataSource implements TranscriptionRemoteDataSource {
  final dynamic _apiClient;
  final String _apiKey;
  final String _baseUrl;

  WhisperRemoteDataSource({
    required dynamic apiClient,
    required String apiKey,
    String baseUrl = 'https://api.openai.com/v1',
  })  : _apiClient = apiClient,
        _apiKey = apiKey,
        _baseUrl = baseUrl;

  @override
  Future<Transcription> transcribeAudio({
    required List<int> audioBytes,
    String audioFormat = 'wav',
    String? language,
    String model = 'whisper-1',
  }) async {
    // TODO: Implementar llamada real
    // POST /audio/transcriptions
    // Headers: Authorization: Bearer {apiKey}
    // Body (multipart): file, model, response_format=verbose_json, timestamp_granularities[]=segment
    final startTime = DateTime.now();
    await Future.delayed(const Duration(seconds: 3));
    final processingTime = DateTime.now().difference(startTime).inMilliseconds;

    return Transcription(
      id: 'trans_${DateTime.now().millisecondsSinceEpoch}',
      songId: 'unknown',
      fullText: _demoTranscriptionText(),
      segments: _demoSegments(),
      detectedLanguage: language ?? 'en',
      confidence: 0.87,
      model: model,
      audioDurationMs: audioBytes.length ~/ 44,
      processingTimeMs: processingTime,
      status: TranscriptionStatus.completed,
      createdAt: DateTime.now(),
      ttlMinutes: 60,
    );
  }

  @override
  Future<Transcription> transcribeFromUrl({
    required String audioUrl,
    String? language,
    String model = 'whisper-1',
  }) async {
    // TODO: Descargar audio de URL y luego transcribir
    await Future.delayed(const Duration(seconds: 4));

    return Transcription(
      id: 'trans_url_${DateTime.now().millisecondsSinceEpoch}',
      songId: 'unknown',
      fullText: _demoTranscriptionText(),
      segments: _demoSegments(),
      detectedLanguage: language ?? 'en',
      confidence: 0.82,
      model: model,
      audioDurationMs: 180000,
      processingTimeMs: 4000,
      status: TranscriptionStatus.completed,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<bool> isServiceAvailable() async {
    if (_apiKey.isEmpty) return false;
    // TODO: Ping OpenAI API
    return true;
  }

  @override
  Future<List<String>> getSupportedLanguages() async {
    return [
      'en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh',
      'ru', 'ar', 'hi', 'nl', 'pl', 'sv', 'da', 'fi', 'no',
    ];
  }

  String _demoTranscriptionText() {
    return 'Is this the real life?\n'
        'Is this just fantasy?\n'
        'Caught in a landslide\n'
        'No escape from reality';
  }

  List<TranscriptionSegment> _demoSegments() {
    return const [
      TranscriptionSegment(
        text: 'Is this the real life?',
        startTimeMs: 0,
        endTimeMs: 3500,
        confidence: 0.92,
      ),
      TranscriptionSegment(
        text: 'Is this just fantasy?',
        startTimeMs: 3500,
        endTimeMs: 7200,
        confidence: 0.88,
      ),
      TranscriptionSegment(
        text: 'Caught in a landslide',
        startTimeMs: 7200,
        endTimeMs: 10800,
        confidence: 0.85,
      ),
      TranscriptionSegment(
        text: 'No escape from reality',
        startTimeMs: 10800,
        endTimeMs: 15000,
        confidence: 0.90,
      ),
    ];
  }
}

/// Datasource local para cachear transcripciones con TTL
abstract class TranscriptionLocalDataSource {
  Future<Transcription?> getCachedTranscription(String songId);
  Future<void> cacheTranscription(Transcription transcription);
  Future<void> deleteCachedTranscription(String songId);
  Future<void> cleanExpired();
}

/// Implementación con SharedPreferences
class TranscriptionLocalDataSourceImpl implements TranscriptionLocalDataSource {
  static const _prefix = 'lyricflow_trans_';
  final SharedPreferences _prefs;

  TranscriptionLocalDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  @override
  Future<Transcription?> getCachedTranscription(String songId) async {
    try {
      final jsonStr = _prefs.getString('$_prefix$songId');
      if (jsonStr == null) return null;

      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final createdAt = DateTime.parse(data['createdAt'] as String);
      final ttl = data['ttlMinutes'] as int? ?? 60;

      // Verificar TTL
      if (DateTime.now().difference(createdAt).inMinutes > ttl) {
        await deleteCachedTranscription(songId);
        return null;
      }

      return Transcription(
        id: data['id'] as String,
        songId: data['songId'] as String,
        fullText: data['fullText'] as String,
        detectedLanguage: data['detectedLanguage'] as String? ?? 'unknown',
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        model: data['model'] as String? ?? 'whisper-1',
        status: TranscriptionStatus.completed,
        createdAt: createdAt,
        ttlMinutes: ttl,
      );
    } catch (e) {
      throw CacheException(message: 'Error reading cached transcription: $e');
    }
  }

  @override
  Future<void> cacheTranscription(Transcription transcription) async {
    try {
      final data = {
        'id': transcription.id,
        'songId': transcription.songId,
        'fullText': transcription.fullText,
        'detectedLanguage': transcription.detectedLanguage,
        'confidence': transcription.confidence,
        'model': transcription.model,
        'createdAt': transcription.createdAt.toIso8601String(),
        'ttlMinutes': transcription.ttlMinutes,
      };
      await _prefs.setString(
        '$_prefix${transcription.songId}',
        json.encode(data),
      );
    } catch (e) {
      throw CacheException(message: 'Error caching transcription: $e');
    }
  }

  @override
  Future<void> deleteCachedTranscription(String songId) async {
    await _prefs.remove('$_prefix$songId');
  }

  @override
  Future<void> cleanExpired() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      final songId = key.replaceFirst(_prefix, '');
      await getCachedTranscription(songId); // Auto-deletes if expired
    }
  }
}
