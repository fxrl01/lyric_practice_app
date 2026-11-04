import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/stem.dart';
import '../../domain/entities/midi_track.dart';
import '../../domain/entities/practice_session.dart';
import '../../domain/repositories/i_practice_repository.dart';
import '../datasources/practice_datasources.dart';

/// Implementación concreta del repositorio de modo práctica
///
/// Coordina tres subdominios:
/// 1. Stems (Demucs via microservicio Python)
/// 2. MIDI (Basic Pitch via microservicio Python)
/// 3. Sesiones de práctica (almacenamiento local)
class PracticeRepositoryImpl implements IPracticeRepository {
  final PracticeRemoteDataSource _remoteDataSource;
  final PracticeLocalDataSource _localDataSource;
  final Logger _logger;
  final Uuid _uuid;

  PracticeRepositoryImpl({
    required PracticeRemoteDataSource remoteDataSource,
    required PracticeLocalDataSource localDataSource,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _logger = logger,
        _uuid = const Uuid();

  // ═══════════════════════════════════════════
  // STEMS
  // ═══════════════════════════════════════════

  @override
  Future<Either<AppFailure, String>> requestStemSeparation({
    required List<int> audioBytes,
    required String songId,
    String audioFormat = 'wav',
    String model = 'htdemucs',
  }) async {
    try {
      _logger.i('🎛️ Requesting stem separation for song: $songId');

      final jobId = await _remoteDataSource.requestStemSeparation(
        audioBytes: audioBytes,
        songId: songId,
        audioFormat: audioFormat,
        model: model,
      );

      _logger.i('✅ Stem job created: $jobId');
      return Right(jobId);
    } catch (e) {
      _logger.e('❌ Stem separation request failed: $e');
      return Left(ServerFailure(
        message: 'Error al solicitar separación de stems: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, StemSeparationResult>> getStemSeparationStatus({
    required String jobId,
  }) async {
    try {
      final result = await _remoteDataSource.getStemSeparationStatus(jobId);
      _logger.d('📊 Stem job $jobId: ${result.status.name} (${(result.progress * 100).toInt()}%)');
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error al consultar estado de stems: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, StemSeparationResult?>> getCachedStems({
    required String songId,
  }) async {
    // TODO: Implementar caché de stems procesados
    return const Right(null);
  }

  // ═══════════════════════════════════════════
  // MIDI
  // ═══════════════════════════════════════════

  @override
  Future<Either<AppFailure, String>> requestMidiExtraction({
    required String stemId,
    required String audioUrl,
    required String songId,
  }) async {
    try {
      _logger.i('🎹 Requesting MIDI extraction for stem: $stemId');

      final jobId = await _remoteDataSource.requestMidiExtraction(
        stemId: stemId,
        audioUrl: audioUrl,
        songId: songId,
      );

      _logger.i('✅ MIDI job created: $jobId');
      return Right(jobId);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error al solicitar extracción MIDI: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, MidiTrack>> getMidiExtractionStatus({
    required String jobId,
  }) async {
    try {
      final track = await _remoteDataSource.getMidiExtractionStatus(jobId);
      return Right(track);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Error al consultar estado de MIDI: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, MidiTrack?>> getCachedMidiTrack({
    required String songId,
    required String stemId,
  }) async {
    // TODO: Implementar caché de MIDI tracks
    return const Right(null);
  }

  // ═══════════════════════════════════════════
  // PRACTICE SESSIONS
  // ═══════════════════════════════════════════

  @override
  Future<Either<AppFailure, PracticeSession>> createSession({
    required String songId,
    required String songTitle,
    required String songArtist,
    required PracticeMode mode,
    required PracticeDifficulty difficulty,
    required String language,
  }) async {
    try {
      final session = PracticeSession(
        id: _uuid.v4(),
        songId: songId,
        songTitle: songTitle,
        songArtist: songArtist,
        mode: mode,
        difficulty: difficulty,
        language: language,
        startedAt: DateTime.now(),
        status: PracticeSessionStatus.inProgress,
      );

      await _localDataSource.saveSession(session);
      _logger.i('🎓 Practice session created: ${session.id} (${mode.displayName})');
      return Right(session);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Error al crear sesión de práctica: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, PracticeSession>> updateSession({
    required PracticeSession session,
  }) async {
    try {
      await _localDataSource.saveSession(session);
      return Right(session);
    } on CacheException catch (e) {
      return Left(CacheFailure(
        message: e.message,
        originalError: e,
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Error al actualizar sesión: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, PracticeSession>> completeSession({
    required String sessionId,
  }) async {
    try {
      final session = await _localDataSource.getSession(sessionId);
      if (session == null) {
        return const Left(CacheFailure(
          message: 'Sesión no encontrada.',
          code: 'SESSION_NOT_FOUND',
        ));
      }

      final completed = session.copyWith(
        status: PracticeSessionStatus.completed,
        completedAt: DateTime.now(),
      );

      await _localDataSource.saveSession(completed);

      _logger.i(
        '🏆 Session completed: $sessionId '
        '(score: ${completed.score}/${completed.maxScore}, '
        'accuracy: ${completed.accuracyPercent})',
      );

      return Right(completed);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Error al completar sesión: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, List<PracticeSession>>> getSessionHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final sessions = await _localDataSource.getSessionHistory(
        limit: limit,
        offset: offset,
      );
      return Right(sessions);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, originalError: e));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Error al obtener historial: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, PracticeStats>> getPracticeStats() async {
    try {
      final stats = await _localDataSource.getPracticeStats();
      return Right(stats);
    } catch (e) {
      return const Right(PracticeStats()); // Degradar con stats vacías
    }
  }

  @override
  Future<Either<AppFailure, List<PracticeSession>>> getSessionsBySong({
    required String songId,
  }) async {
    try {
      final sessions = await _localDataSource.getSessionsBySong(songId);
      return Right(sessions);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Error al obtener sesiones: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<AppFailure, void>> deleteSession({
    required String sessionId,
  }) async {
    try {
      await _localDataSource.deleteSession(sessionId);
      _logger.d('🗑️ Session deleted: $sessionId');
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Error al eliminar sesión: $e',
        originalError: e,
      ));
    }
  }
}
