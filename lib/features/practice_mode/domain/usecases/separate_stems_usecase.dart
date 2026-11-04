import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/stem.dart';
import '../repositories/i_practice_repository.dart';

/// Caso de uso: Separar stems de una canción con Demucs
///
/// La separación de stems es un proceso pesado que se ejecuta
/// en un microservicio Python con GPU. Este use case:
/// 1. Verifica si ya hay stems cacheados
/// 2. Si no, envía request al microservicio
/// 3. Retorna el jobId para polling o el resultado final
///
/// El UI usará polling para mostrar progreso.
class SeparateStemsUseCase extends UseCase<StemSeparationResult, SeparateStemsParams> {
  final IPracticeRepository _repository;

  SeparateStemsUseCase({required IPracticeRepository repository})
      : _repository = repository;

  @override
  Future<Either<AppFailure, StemSeparationResult>> call(
    SeparateStemsParams params,
  ) async {
    // Validación
    if (params.audioBytes.isEmpty) {
      return const Left(ValidationFailure(
        message: 'Se requiere audio para separar stems.',
        code: 'MISSING_AUDIO',
      ));
    }

    // 1. Verificar caché
    final cachedResult = await _repository.getCachedStems(
      songId: params.songId,
    );

    if (cachedResult.isRight()) {
      final cached = cachedResult.getOrElse(() => null);
      if (cached != null && cached.isComplete) {
        return Right(cached);
      }
    }

    // 2. Si hay un jobId existente, verificar estado
    if (params.existingJobId != null) {
      return _repository.getStemSeparationStatus(
        jobId: params.existingJobId!,
      );
    }

    // 3. Solicitar nueva separación
    final jobResult = await _repository.requestStemSeparation(
      audioBytes: params.audioBytes,
      songId: params.songId,
      audioFormat: params.audioFormat,
      model: params.model,
    );

    // 4. Si se creó el job, verificar estado inmediato
    return jobResult.fold(
      Left.new,
      (jobId) async {
        // Retornar resultado pending con el jobId
        return Right(StemSeparationResult(
          jobId: jobId,
          songId: params.songId,
          status: StemProcessingStatus.processing,
          progress: 0.0,
          createdAt: DateTime.now(),
        ));
      },
    );
  }
}

/// Parámetros para SeparateStemsUseCase
class SeparateStemsParams extends Equatable {
  final List<int> audioBytes;
  final String songId;
  final String audioFormat;
  final String model;

  /// Si ya hay un job en progreso, pasar su ID para verificar estado
  final String? existingJobId;

  const SeparateStemsParams({
    required this.audioBytes,
    required this.songId,
    this.audioFormat = 'wav',
    this.model = 'htdemucs',
    this.existingJobId,
  });

  @override
  List<Object?> get props => [audioBytes.length, songId, model, existingJobId];
}
