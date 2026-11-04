import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/i_song_recognition_repository.dart';
import '../datasources/song_recognition_remote_datasource.dart';
import '../datasources/song_recognition_local_datasource.dart';

/// Implementación concreta del repositorio de reconocimiento
///
/// Coordina entre datasources remotos y locales.
/// Transforma excepciones de la capa de datos en [AppFailure].
///
/// Principio DIP: depende de abstracciones (interfaces de datasources),
/// no de implementaciones concretas.
class SongRecognitionRepositoryImpl implements ISongRecognitionRepository {
  final SongRecognitionRemoteDataSource _remoteDataSource;
  final SongRecognitionLocalDataSource _localDataSource;
  final Logger _logger;

  SongRecognitionRepositoryImpl({
    required SongRecognitionRemoteDataSource remoteDataSource,
    required SongRecognitionLocalDataSource localDataSource,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _logger = logger;

  @override
  Future<Either<AppFailure, Song>> recognizeSong({
    required List<int> audioBytes,
    required int durationMs,
  }) async {
    try {
      _logger.i('🎵 Recognizing song (${audioBytes.length} bytes)...');

      final song = await _remoteDataSource.recognizeSong(
        audioBytes: audioBytes,
        durationMs: durationMs,
      );

      // Guardar automáticamente en historial
      await _localDataSource.addToHistory(song);

      _logger.i('✅ Recognized: "${song.title}" by ${song.artist}');
      return Right(song);
    } on RecognitionException catch (e) {
      _logger.w('⚠️ Recognition failed: ${e.message}');
      return Left(RecognitionFailure(
        message: e.message,
        originalError: e,
      ));
    } on NetworkException catch (e) {
      _logger.e('❌ Network error during recognition: ${e.message}');
      return Left(NetworkFailure(
        message: e.message,
        originalError: e,
      ));
    } on ServerException catch (e) {
      _logger.e('❌ Server error during recognition: ${e.message}');
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        originalError: e,
      ));
    } catch (e) {
      _logger.e('🔥 Unexpected error during recognition: $e');
      return Left(UnknownFailure(
        message: 'Error inesperado al reconocer la canción: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, Song>> recognizeByHumming({
    required List<int> audioBytes,
  }) async {
    try {
      _logger.i('🎤 Recognizing by humming...');
      final song = await _remoteDataSource.recognizeByHumming(
        audioBytes: audioBytes,
      );
      await _localDataSource.addToHistory(song);
      return Right(song);
    } on UnimplementedError catch (e) {
      return Left(RecognitionFailure(
        message: 'El reconocimiento por tarareo no está disponible '
            'con el proveedor actual.',
        originalError: e,
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Error al reconocer por tarareo: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, List<Song>>> searchSong({
    required String query,
  }) async {
    try {
      _logger.i('🔍 Searching: "$query"');
      final results = await _remoteDataSource.searchSong(query: query);
      return Right(results);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Error al buscar canciones: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, Song>> getSongDetails({
    required String songId,
    required String source,
  }) async {
    try {
      final song = await _remoteDataSource.getSongDetails(
        songId: songId,
        source: source,
      );
      return Right(song);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Error al obtener detalles de la canción: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, List<Song>>> getRecognitionHistory() async {
    try {
      final history = await _localDataSource.getHistory();
      return Right(history);
    } on CacheException catch (e) {
      return Left(CacheFailure(
        message: e.message,
        originalError: e,
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Error al leer historial: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, void>> saveToHistory(Song song) async {
    try {
      await _localDataSource.addToHistory(song);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Error al guardar en historial: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, void>> clearHistory() async {
    try {
      await _localDataSource.clearHistory();
      _logger.i('🗑️ History cleared');
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Error al limpiar historial: $e',
        originalError: e,
      ));
    }
  }
}
