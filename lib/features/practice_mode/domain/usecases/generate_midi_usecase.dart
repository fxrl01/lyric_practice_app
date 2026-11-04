import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/midi_track.dart';
import '../repositories/i_practice_repository.dart';

/// Caso de uso: Extraer notas MIDI de un stem de audio
///
/// Usa Basic Pitch para convertir audio en secuencia de notas MIDI.
/// Útil para:
/// - Mostrar piano roll en modo práctica
/// - Generar tabs de guitarra/bajo
/// - Visualizar melodía vocal
///
/// Similar a SeparateStems, usa patrón async job con polling.
class GenerateMidiFromAudioUseCase extends UseCase<MidiTrack, GenerateMidiParams> {
  final IPracticeRepository _repository;

  GenerateMidiFromAudioUseCase({required IPracticeRepository repository})
      : _repository = repository;

  @override
  Future<Either<AppFailure, MidiTrack>> call(GenerateMidiParams params) async {
    // Validación
    if (params.audioUrl.isEmpty) {
      return const Left(ValidationFailure(
        message: 'Se requiere URL del audio para extraer MIDI.',
        code: 'MISSING_AUDIO_URL',
      ));
    }

    // 1. Verificar caché
    final cachedResult = await _repository.getCachedMidiTrack(
      songId: params.songId,
      stemId: params.stemId,
    );

    if (cachedResult.isRight()) {
      final cached = cachedResult.getOrElse(() => null);
      if (cached != null && cached.notes.isNotEmpty) {
        return Right(cached);
      }
    }

    // 2. Si hay job existente, verificar estado
    if (params.existingJobId != null) {
      return _repository.getMidiExtractionStatus(
        jobId: params.existingJobId!,
      );
    }

    // 3. Solicitar nueva extracción
    final jobResult = await _repository.requestMidiExtraction(
      stemId: params.stemId,
      audioUrl: params.audioUrl,
      songId: params.songId,
    );

    return jobResult.fold(
      Left.new,
      (jobId) async {
        // Retornar track vacío con el jobId para polling
        return Right(MidiTrack(
          id: jobId,
          songId: params.songId,
          stemId: params.stemId,
          durationMs: 0,
          confidence: 0.0,
        ));
      },
    );
  }
}

/// Parámetros para GenerateMidiFromAudioUseCase
class GenerateMidiParams extends Equatable {
  final String stemId;
  final String audioUrl;
  final String songId;
  final String? existingJobId;

  const GenerateMidiParams({
    required this.stemId,
    required this.audioUrl,
    required this.songId,
    this.existingJobId,
  });

  @override
  List<Object?> get props => [stemId, audioUrl, songId, existingJobId];
}
