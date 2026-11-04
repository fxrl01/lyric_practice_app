import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transcription.dart';
import '../repositories/i_transcription_repository.dart';

/// Caso de uso: Transcribir audio con IA (Whisper)
///
/// Se usa cuando una canción NO tiene letras disponibles en APIs.
/// Flujo:
/// 1. Verificar si hay transcripción cacheada (no expirada)
/// 2. Si no hay, enviar audio a Whisper para transcripción
/// 3. Cachear resultado con TTL
/// 4. Retornar con disclaimer de IA
///
/// ⚠️ LEGAL: El resultado se marca como "Generado por IA"
/// y tiene TTL limitado para cumplimiento de copyright.
class TranscribeAudioUseCase extends UseCase<Transcription, TranscribeAudioParams> {
  final ITranscriptionRepository _repository;

  TranscribeAudioUseCase({required ITranscriptionRepository repository})
      : _repository = repository;

  @override
  Future<Either<AppFailure, Transcription>> call(TranscribeAudioParams params) async {
    // Validación
    if (params.audioBytes.isEmpty && params.audioUrl == null) {
      return const Left(ValidationFailure(
        message: 'Se requiere audio o URL para transcribir.',
        code: 'MISSING_AUDIO',
      ));
    }

    // 1. Verificar caché primero
    if (params.songId != null) {
      final cachedResult = await _repository.getCachedTranscription(
        songId: params.songId!,
      );

      if (cachedResult.isRight()) {
        final cached = cachedResult.getOrElse(() => null);
        if (cached != null && !cached.isExpired) {
          return Right(cached);
        }
      }
    }

    // 2. Verificar servicio disponible
    final serviceCheck = await _repository.isServiceAvailable();
    final isAvailable = serviceCheck.getOrElse(() => false);
    if (!isAvailable) {
      return const Left(ApiKeyMissingFailure(
        message: 'El servicio de transcripción no está disponible. '
            'Configura tu API key de OpenAI en el archivo .env',
      ));
    }

    // 3. Transcribir
    Either<AppFailure, Transcription> result;

    if (params.audioUrl != null) {
      result = await _repository.transcribeFromUrl(
        audioUrl: params.audioUrl!,
        language: params.language,
        model: params.model,
      );
    } else {
      result = await _repository.transcribeAudio(
        audioBytes: params.audioBytes,
        audioFormat: params.audioFormat,
        language: params.language,
        model: params.model,
      );
    }

    // 4. Si tiene songId, actualizar la transcripción con él
    return result.map((transcription) {
      if (params.songId != null && transcription.songId == 'unknown') {
        return transcription.copyWith(songId: params.songId);
      }
      return transcription;
    });
  }
}

/// Parámetros para TranscribeAudioUseCase
class TranscribeAudioParams extends Equatable {
  /// Audio en bytes (si se tiene el archivo)
  final List<int> audioBytes;

  /// URL del audio (alternativa a bytes)
  final String? audioUrl;

  /// ID de la canción (para caché)
  final String? songId;

  /// Formato del audio
  final String audioFormat;

  /// Idioma esperado (null = auto-detect)
  final String? language;

  /// Modelo de IA a usar
  final String model;

  const TranscribeAudioParams({
    this.audioBytes = const [],
    this.audioUrl,
    this.songId,
    this.audioFormat = 'wav',
    this.language,
    this.model = 'whisper-1',
  });

  @override
  List<Object?> get props => [
        audioBytes.length,
        audioUrl,
        songId,
        audioFormat,
        language,
        model,
      ];
}
