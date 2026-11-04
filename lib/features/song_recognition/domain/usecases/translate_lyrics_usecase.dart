import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/lyrics.dart';
import '../repositories/i_lyrics_repository.dart';

/// Caso de uso: Traducir letras a otro idioma
///
/// Útil para el modo práctica de aprendizaje de idiomas.
/// El usuario puede ver las letras originales junto con la traducción.
class TranslateLyricsUseCase extends UseCase<Lyrics, TranslateLyricsParams> {
  final ILyricsRepository _repository;

  TranslateLyricsUseCase({required ILyricsRepository repository})
      : _repository = repository;

  @override
  Future<Either<AppFailure, Lyrics>> call(TranslateLyricsParams params) async {
    // Validación
    if (params.lyrics.isEmpty) {
      return const Left(ValidationFailure(
        message: 'No hay letras para traducir.',
        code: 'EMPTY_LYRICS',
      ));
    }

    if (params.targetLanguage.length != 2) {
      return const Left(ValidationFailure(
        message: 'Idioma de destino inválido. Usa formato ISO 639-1 (ej: "es").',
        code: 'INVALID_LANGUAGE',
      ));
    }

    // No traducir si ya está en el idioma destino
    if (params.lyrics.language == params.targetLanguage) {
      return Right(params.lyrics);
    }

    return _repository.getTranslation(
      lyrics: params.lyrics,
      targetLanguage: params.targetLanguage,
    );
  }
}

/// Parámetros para TranslateLyricsUseCase
class TranslateLyricsParams extends Equatable {
  final Lyrics lyrics;
  final String targetLanguage;

  const TranslateLyricsParams({
    required this.lyrics,
    required this.targetLanguage,
  });

  @override
  List<Object?> get props => [lyrics.songId, targetLanguage];
}
