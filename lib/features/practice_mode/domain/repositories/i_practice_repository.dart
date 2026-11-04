import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/stem.dart';
import '../entities/midi_track.dart';
import '../entities/practice_session.dart';

/// Contrato abstracto para el repositorio de modo práctica
///
/// Abarca tres subdominios:
/// 1. Separación de stems (Demucs)
/// 2. Extracción de notas MIDI (Basic Pitch)
/// 3. Gestión de sesiones de práctica
///
/// La separación de stems y MIDI se procesan en un microservicio
/// Python externo (FastAPI + Celery), por lo que estas operaciones
/// son asíncronas con polling de estado.
abstract class IPracticeRepository {
  // ═══════════════════════════════════════════
  // STEMS — Separación de audio con Demucs
  // ═══════════════════════════════════════════

  /// Solicitar separación de stems para una canción
  ///
  /// [audioBytes] - Audio de la canción completa
  /// [audioFormat] - Formato (wav, mp3, etc.)
  /// [model] - Modelo Demucs (htdemucs, htdemucs_ft)
  ///
  /// Returns el jobId para polling del estado
  Future<Either<AppFailure, String>> requestStemSeparation({
    required List<int> audioBytes,
    required String songId,
    String audioFormat = 'wav',
    String model = 'htdemucs',
  });

  /// Consultar el estado de un job de separación de stems
  ///
  /// [jobId] - ID del job retornado por requestStemSeparation
  Future<Either<AppFailure, StemSeparationResult>> getStemSeparationStatus({
    required String jobId,
  });

  /// Obtener stems ya procesados de una canción
  ///
  /// [songId] - ID de la canción
  Future<Either<AppFailure, StemSeparationResult?>> getCachedStems({
    required String songId,
  });

  // ═══════════════════════════════════════════
  // MIDI — Extracción de notas con Basic Pitch
  // ═══════════════════════════════════════════

  /// Solicitar extracción de notas MIDI de un stem
  ///
  /// [stemId] - ID del stem a analizar (generalmente vocals o guitar)
  /// [audioUrl] - URL del stem
  Future<Either<AppFailure, String>> requestMidiExtraction({
    required String stemId,
    required String audioUrl,
    required String songId,
  });

  /// Consultar estado de extracción MIDI
  Future<Either<AppFailure, MidiTrack>> getMidiExtractionStatus({
    required String jobId,
  });

  /// Obtener MIDI track ya procesado
  Future<Either<AppFailure, MidiTrack?>> getCachedMidiTrack({
    required String songId,
    required String stemId,
  });

  // ═══════════════════════════════════════════
  // PRACTICE SESSIONS — Gestión de práctica
  // ═══════════════════════════════════════════

  /// Crear una nueva sesión de práctica
  Future<Either<AppFailure, PracticeSession>> createSession({
    required String songId,
    required String songTitle,
    required String songArtist,
    required PracticeMode mode,
    required PracticeDifficulty difficulty,
    required String language,
  });

  /// Actualizar una sesión en progreso (guardar intento)
  Future<Either<AppFailure, PracticeSession>> updateSession({
    required PracticeSession session,
  });

  /// Completar una sesión
  Future<Either<AppFailure, PracticeSession>> completeSession({
    required String sessionId,
  });

  /// Obtener historial de sesiones de práctica
  Future<Either<AppFailure, List<PracticeSession>>> getSessionHistory({
    int limit = 20,
    int offset = 0,
  });

  /// Obtener estadísticas de práctica del usuario
  Future<Either<AppFailure, PracticeStats>> getPracticeStats();

  /// Obtener sesiones por canción
  Future<Either<AppFailure, List<PracticeSession>>> getSessionsBySong({
    required String songId,
  });

  /// Eliminar una sesión
  Future<Either<AppFailure, void>> deleteSession({
    required String sessionId,
  });
}

/// Estadísticas agregadas de práctica del usuario
class PracticeStats {
  /// Total de sesiones completadas
  final int totalSessions;

  /// Total de palabras practicadas
  final int totalWordsPracticed;

  /// Precisión promedio general
  final double averageAccuracy;

  /// Mejor racha global
  final int bestStreak;

  /// Tiempo total de práctica en minutos
  final int totalPracticeMinutes;

  /// Canciones únicas practicadas
  final int uniqueSongsPracticed;

  /// Días consecutivos de práctica (racha actual)
  final int currentDayStreak;

  /// Distribución por modo de práctica
  final Map<PracticeMode, int> sessionsByMode;

  /// Distribución por idioma
  final Map<String, int> sessionsByLanguage;

  const PracticeStats({
    this.totalSessions = 0,
    this.totalWordsPracticed = 0,
    this.averageAccuracy = 0.0,
    this.bestStreak = 0,
    this.totalPracticeMinutes = 0,
    this.uniqueSongsPracticed = 0,
    this.currentDayStreak = 0,
    this.sessionsByMode = const {},
    this.sessionsByLanguage = const {},
  });
}
