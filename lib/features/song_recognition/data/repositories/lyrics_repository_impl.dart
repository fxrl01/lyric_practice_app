import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/repositories/i_lyrics_repository.dart';
import '../datasources/lyrics_remote_datasource.dart';

/// Implementación concreta del repositorio de letras
///
/// ⚠️ LEGAL: Modelo pass-through.
/// Las letras se obtienen en tiempo real de la API y se muestran
/// al usuario. NO se almacenan en caché permanente ni en el servidor.
///
/// Cada vez que el usuario solicita letras, se hace una nueva
/// llamada a la API para cumplir con los ToS de Musixmatch/LyricFind.
class LyricsRepositoryImpl implements ILyricsRepository {
  final LyricsRemoteDataSource _remoteDataSource;
  final Logger _logger;

  LyricsRepositoryImpl({
    required LyricsRemoteDataSource remoteDataSource,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _logger = logger;

  @override
  Future<Either<AppFailure, Lyrics>> getLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
    int? duration,
  }) async {
    try {
      _logger.i('📝 Fetching lyrics: "$songTitle" by $artist');

      final lyrics = await _remoteDataSource.getLyrics(
        songTitle: songTitle,
        artist: artist,
        isrc: isrc,
        duration: duration,
      );

      if (lyrics.isEmpty) {
        _logger.w('⚠️ No lyrics found for "$songTitle"');
        return const Left(RecognitionFailure(
          message: 'No se encontraron letras para esta canción.',
          code: 'LYRICS_NOT_FOUND',
        ));
      }

      _logger.i('✅ Lyrics found: ${lyrics.lineCount} lines (${lyrics.source.name})');
      return Right(lyrics);
    } catch (e) {
      _logger.e('❌ Error fetching lyrics: $e');
      return Left(ServerFailure(
        message: 'Error al obtener las letras: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, Lyrics>> getSyncedLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
  }) async {
    try {
      _logger.i('🎶 Fetching synced lyrics: "$songTitle"');

      final lyrics = await _remoteDataSource.getSyncedLyrics(
        songTitle: songTitle,
        artist: artist,
        isrc: isrc,
      );

      if (lyrics.isEmpty) {
        // Fallback a letras sin sincronizar
        _logger.w('⚠️ No synced lyrics, falling back to unsynced');
        return getLyrics(
          songTitle: songTitle,
          artist: artist,
          isrc: isrc,
        );
      }

      _logger.i('✅ Synced lyrics: ${lyrics.lineCount} lines');
      return Right(lyrics);
    } catch (e) {
      // Fallback a letras normales si las sincronizadas fallan
      _logger.w('⚠️ Synced lyrics failed, trying unsynced: $e');
      return getLyrics(
        songTitle: songTitle,
        artist: artist,
        isrc: isrc,
      );
    }
  }

  @override
  Future<Either<AppFailure, List<Lyrics>>> searchByLyricText({
    required String query,
  }) async {
    try {
      _logger.i('🔍 Searching lyrics by text: "$query"');
      final results = await _remoteDataSource.searchByLyricText(query: query);
      return Right(results);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error al buscar letras: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, Lyrics>> getTranslation({
    required Lyrics lyrics,
    required String targetLanguage,
  }) async {
    // TODO: Integrar con Google Translate o DeepL API
    // Por ahora retornamos un error indicando que no está implementado
    _logger.w('⚠️ Translation not yet implemented');
    return const Left(ServerFailure(
      message: 'La traducción de letras estará disponible próximamente.',
      code: 'TRANSLATION_NOT_IMPLEMENTED',
    ));
  }

  @override
  Future<Either<AppFailure, bool>> hasLyrics({
    required String songTitle,
    required String artist,
  }) async {
    try {
      final result = await _remoteDataSource.hasLyrics(
        songTitle: songTitle,
        artist: artist,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error al verificar letras: $e',
        originalError: e,
      ));
    }
  }
}
