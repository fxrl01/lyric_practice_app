import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/transcription.dart';

/// Contrato abstracto para el repositorio de transcripción IA
///
/// Define operaciones para transcribir audio usando modelos de IA
/// (OpenAI Whisper, etc.) cuando no hay letras disponibles en APIs.
///
/// ⚠️ LEGAL: Las transcripciones son contenido derivado generado por IA.
/// Deben marcarse como tal y tener un TTL (Time To Live) limitado.
abstract class ITranscriptionRepository {
  /// Transcribir audio a texto usando IA
  ///
  /// [audioBytes] - Audio del segmento a transcribir
  /// [audioFormat] - Formato del audio (wav, mp3, webm, etc.)
  /// [language] - Idioma esperado (opcional, auto-detect si null)
  /// [model] - Modelo a usar (whisper-1, whisper-large-v3, etc.)
  ///
  /// Returns Either con Transcription incluyendo segmentos con timestamps
  Future<Either<AppFailure, Transcription>> transcribeAudio({
    required List<int> audioBytes,
    String audioFormat = 'wav',
    String? language,
    String model = 'whisper-1',
  });

  /// Transcribir audio desde una URL
  ///
  /// [audioUrl] - URL del audio a transcribir
  /// Útil cuando ya tenemos una preview URL de la canción
  Future<Either<AppFailure, Transcription>> transcribeFromUrl({
    required String audioUrl,
    String? language,
    String model = 'whisper-1',
  });

  /// Obtener una transcripción previamente generada (si no ha expirado)
  ///
  /// [songId] - ID de la canción
  /// Returns null si la transcripción expiró o no existe
  Future<Either<AppFailure, Transcription?>> getCachedTranscription({
    required String songId,
  });

  /// Guardar transcripción temporalmente (con TTL)
  ///
  /// [transcription] - Transcripción a cachear
  /// Se elimina automáticamente después del TTL
  Future<Either<AppFailure, void>> cacheTranscription(
    Transcription transcription,
  );

  /// Eliminar transcripción cacheada
  Future<Either<AppFailure, void>> deleteCachedTranscription({
    required String songId,
  });

  /// Verificar si el servicio de transcripción está disponible
  Future<Either<AppFailure, bool>> isServiceAvailable();

  /// Obtener idiomas soportados por el modelo
  Future<Either<AppFailure, List<String>>> getSupportedLanguages();
}
