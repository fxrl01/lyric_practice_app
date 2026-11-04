import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/song.dart';
import '../repositories/i_song_recognition_repository.dart';

/// Caso de uso: Reconocer una canción a partir de audio grabado
///
/// Flujo principal de la app:
/// 1. El usuario graba audio (micrófono)
/// 2. Se envía al servicio de reconocimiento (AudD/ACRCloud)
/// 3. Se retorna la canción identificada
/// 4. Se guarda automáticamente en historial
///
/// Principio SRP: Solo se encarga de orquestar el reconocimiento.
class RecognizeSongUseCase extends UseCase<Song, RecognizeSongParams> {
  final ISongRecognitionRepository _repository;

  RecognizeSongUseCase({required ISongRecognitionRepository repository})
      : _repository = repository;

  @override
  Future<Either<AppFailure, Song>> call(RecognizeSongParams params) async {
    // Validaciones previas
    if (params.audioBytes.isEmpty) {
      return const Left(ValidationFailure(
        message: 'No se recibió audio. Intenta grabar de nuevo.',
        code: 'EMPTY_AUDIO',
      ));
    }

    if (params.durationMs < 2000) {
      return const Left(ValidationFailure(
        message: 'La grabación es muy corta. Graba al menos 3 segundos.',
        code: 'SHORT_AUDIO',
      ));
    }

    // Reconocer canción
    if (params.isHumming) {
      return _repository.recognizeByHumming(audioBytes: params.audioBytes);
    }

    return _repository.recognizeSong(
      audioBytes: params.audioBytes,
      durationMs: params.durationMs,
    );
  }
}

/// Parámetros para RecognizeSongUseCase
class RecognizeSongParams extends Equatable {
  /// Audio grabado como bytes
  final List<int> audioBytes;

  /// Duración de la grabación en milisegundos
  final int durationMs;

  /// ¿El usuario está tarareando?
  final bool isHumming;

  const RecognizeSongParams({
    required this.audioBytes,
    required this.durationMs,
    this.isHumming = false,
  });

  @override
  List<Object?> get props => [audioBytes.length, durationMs, isHumming];
}
