import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/transcription.dart';
import '../../domain/repositories/i_transcription_repository.dart';
import '../datasources/transcription_datasources.dart';

/// Implementación concreta del repositorio de transcripción IA
///
/// Coordina entre Whisper API (remoto) y caché con TTL (local).
/// Las transcripciones se cachean temporalmente (default 60 min)
/// y se regeneran bajo demanda para cumplimiento legal.
class TranscriptionRepositoryImpl implements ITranscriptionRepository {
  final TranscriptionRemoteDataSource _remoteDataSource;
  final TranscriptionLocalDataSource _localDataSource;
  final Logger _logger;

  TranscriptionRepositoryImpl({
    required TranscriptionRemoteDataSource remoteDataSource,
    required TranscriptionLocalDataSource localDataSource,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _logger = logger;

  @override
  Future<Either<AppFailure, Transcription>> transcribeAudio({
    required List<int> audioBytes,
    String audioFormat = 'wav',
    String? language,
    String model = 'whisper-1',
  }) async {
    try {
      _logger.i('🤖 Transcribing audio (${audioBytes.length} bytes, model: $model)');

      final transcription = await _remoteDataSource.transcribeAudio(
        audioBytes: audioBytes,
        audioFormat: audioFormat,
        language: language,
        model: model,
      );

      // Cachear con TTL
      await _localDataSource.cacheTranscription(transcription);

      _logger.i(
        '✅ Transcription complete: ${transcription.wordCount} words, '
        'confidence: ${transcription.confidencePercent}, '
        'quality: ${transcription.qualityLabel}',
      );

      return Right(transcription);
    } on TranscriptionException catch (e) {
      _logger.e('❌ Transcription failed: ${e.message}');
      return Left(TranscriptionFailure(
        message: e.message,
        originalError: e,
      ));
    } on NetworkException catch (e) {
      _logger.e('❌ Network error during transcription: ${e.message}');
      return Left(NetworkFailure(
        message: 'Sin conexión para transcribir. Verifica tu internet.',
        originalError: e,
      ));
    } catch (e) {
      _logger.e('🔥 Unexpected transcription error: $e');
      return Left(UnknownFailure(
        message: 'Error inesperado al transcribir: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, Transcription>> transcribeFromUrl({
    required String audioUrl,
    String? language,
    String model = 'whisper-1',
  }) async {
    try {
      _logger.i('🤖 Transcribing from URL: $audioUrl');

      final transcription = await _remoteDataSource.transcribeFromUrl(
        audioUrl: audioUrl,
        language: language,
        model: model,
      );

      await _localDataSource.cacheTranscription(transcription);

      _logger.i('✅ URL transcription complete: ${transcription.confidencePercent}');
      return Right(transcription);
    } catch (e) {
      _logger.e('❌ URL transcription error: $e');
      return Left(TranscriptionFailure(
        message: 'Error al transcribir desde URL: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, Transcription?>> getCachedTranscription({
    required String songId,
  }) async {
    try {
      final cached = await _localDataSource.getCachedTranscription(songId);

      if (cached != null) {
        _logger.d('📦 Cache hit for transcription: $songId');
      } else {
        _logger.d('📦 Cache miss for transcription: $songId');
      }

      return Right(cached);
    } on CacheException catch (e) {
      _logger.w('⚠️ Cache read error: ${e.message}');
      return const Right(null); // Degradar graciosamente
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<AppFailure, void>> cacheTranscription(
    Transcription transcription,
  ) async {
    try {
      await _localDataSource.cacheTranscription(transcription);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Error al cachear transcripción: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, void>> deleteCachedTranscription({
    required String songId,
  }) async {
    try {
      await _localDataSource.deleteCachedTranscription(songId);
      _logger.d('🗑️ Cached transcription deleted: $songId');
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Error al eliminar transcripción: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, bool>> isServiceAvailable() async {
    try {
      final available = await _remoteDataSource.isServiceAvailable();
      return Right(available);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<AppFailure, List<String>>> getSupportedLanguages() async {
    try {
      final languages = await _remoteDataSource.getSupportedLanguages();
      return Right(languages);
    } catch (e) {
      // Retornar lista por defecto si falla
      return const Right(['en', 'es', 'fr', 'de', 'pt', 'ja', 'ko', 'zh']);
    }
  }
}
