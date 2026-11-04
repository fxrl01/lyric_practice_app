import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/lyrics.dart';
import '../repositories/i_lyrics_repository.dart';

/// Caso de uso: Obtener letras de una canción
///
/// Flujo:
/// 1. Recibe título + artista (y opcionalmente ISRC)
/// 2. Intenta obtener letras sincronizadas primero
/// 3. Si no hay synced, obtiene letras normales
/// 4. Si no hay letras, retorna failure para activar transcripción IA
///
/// ⚠️ LEGAL: Las letras se obtienen via pass-through.
/// No se almacenan en el servidor — solo se muestran al usuario.
class GetLyricsUseCase extends UseCase<Lyrics, GetLyricsParams> {
  final ILyricsRepository _repository;

  GetLyricsUseCase({required ILyricsRepository repository})
      : _repository = repository;

  @override
  Future<Either<AppFailure, Lyrics>> call(GetLyricsParams params) async {
    // Validación
    if (params.songTitle.trim().isEmpty) {
      return const Left(ValidationFailure(
        message: 'Se requiere el título de la canción.',
        code: 'MISSING_TITLE',
      ));
    }

    if (params.artist.trim().isEmpty) {
      return const Left(ValidationFailure(
        message: 'Se requiere el nombre del artista.',
        code: 'MISSING_ARTIST',
      ));
    }

    // Intentar synced primero, luego normal
    if (params.preferSynced) {
      final syncedResult = await _repository.getSyncedLyrics(
        songTitle: params.songTitle,
        artist: params.artist,
        isrc: params.isrc,
      );

      // Si obtuvimos synced lyrics, retornar
      if (syncedResult.isRight()) {
        final lyrics = syncedResult.getOrElse(() => throw Exception());
        if (lyrics.isSynced && lyrics.isNotEmpty) {
          return syncedResult;
        }
      }
    }

    // Fallback a letras normales
    return _repository.getLyrics(
      songTitle: params.songTitle,
      artist: params.artist,
      isrc: params.isrc,
      duration: params.durationMs,
    );
  }
}

/// Parámetros para GetLyricsUseCase
class GetLyricsParams extends Equatable {
  final String songTitle;
  final String artist;
  final String? isrc;
  final int? durationMs;

  /// Intentar obtener letras sincronizadas primero
  final bool preferSynced;

  const GetLyricsParams({
    required this.songTitle,
    required this.artist,
    this.isrc,
    this.durationMs,
    this.preferSynced = true,
  });

  @override
  List<Object?> get props => [songTitle, artist, isrc, durationMs, preferSynced];
}
