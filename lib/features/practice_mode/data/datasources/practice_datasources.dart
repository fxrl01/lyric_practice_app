import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/stem.dart';
import '../../domain/entities/midi_track.dart';
import '../../domain/entities/practice_session.dart';
import '../../domain/repositories/i_practice_repository.dart';

/// Datasource remoto para el microservicio Python (Demucs + Basic Pitch)
abstract class PracticeRemoteDataSource {
  /// Solicitar separación de stems
  Future<String> requestStemSeparation({
    required List<int> audioBytes,
    required String songId,
    String audioFormat,
    String model,
  });

  /// Obtener estado del job de stems
  Future<StemSeparationResult> getStemSeparationStatus(String jobId);

  /// Solicitar extracción MIDI
  Future<String> requestMidiExtraction({
    required String stemId,
    required String audioUrl,
    required String songId,
  });

  /// Obtener estado de extracción MIDI
  Future<MidiTrack> getMidiExtractionStatus(String jobId);
}

/// Implementación demo del microservicio Python
///
/// En producción, esto se conectará a un FastAPI + Celery + Redis
/// que ejecuta Demucs y Basic Pitch en workers con GPU.
class PracticeRemoteDataSourceImpl implements PracticeRemoteDataSource {
  final dynamic _apiClient;
  final String _baseUrl;

  PracticeRemoteDataSourceImpl({
    required dynamic apiClient,
    String baseUrl = 'http://localhost:8000/api/v1',
  })  : _apiClient = apiClient,
        _baseUrl = baseUrl;

  @override
  Future<String> requestStemSeparation({
    required List<int> audioBytes,
    required String songId,
    String audioFormat = 'wav',
    String model = 'htdemucs',
  }) async {
    // TODO: POST /stems/separate
    // Body: multipart { audio, songId, model }
    // Response: { jobId: "..." }
    await Future.delayed(const Duration(seconds: 1));
    return 'stem_job_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<StemSeparationResult> getStemSeparationStatus(String jobId) async {
    // TODO: GET /stems/status/{jobId}
    await Future.delayed(const Duration(seconds: 1));

    return StemSeparationResult(
      jobId: jobId,
      songId: 'demo_song',
      status: StemProcessingStatus.completed,
      progress: 1.0,
      stems: [
        Stem(
          id: '${jobId}_vocals',
          songId: 'demo_song',
          type: StemType.vocals,
          audioUrl: 'https://example.com/stems/vocals.wav',
          durationMs: 354000,
        ),
        Stem(
          id: '${jobId}_drums',
          songId: 'demo_song',
          type: StemType.drums,
          audioUrl: 'https://example.com/stems/drums.wav',
          durationMs: 354000,
        ),
        Stem(
          id: '${jobId}_bass',
          songId: 'demo_song',
          type: StemType.bass,
          audioUrl: 'https://example.com/stems/bass.wav',
          durationMs: 354000,
        ),
        Stem(
          id: '${jobId}_other',
          songId: 'demo_song',
          type: StemType.other,
          audioUrl: 'https://example.com/stems/other.wav',
          durationMs: 354000,
        ),
      ],
      createdAt: DateTime.now(),
      processingTimeMs: 45000,
    );
  }

  @override
  Future<String> requestMidiExtraction({
    required String stemId,
    required String audioUrl,
    required String songId,
  }) async {
    // TODO: POST /midi/extract
    await Future.delayed(const Duration(seconds: 1));
    return 'midi_job_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<MidiTrack> getMidiExtractionStatus(String jobId) async {
    // TODO: GET /midi/status/{jobId}
    await Future.delayed(const Duration(seconds: 1));

    return MidiTrack(
      id: jobId,
      songId: 'demo_song',
      notes: const [
        MidiNote(pitch: 60, startTimeMs: 0, durationMs: 500, confidence: 0.9),
        MidiNote(pitch: 64, startTimeMs: 500, durationMs: 500, confidence: 0.85),
        MidiNote(pitch: 67, startTimeMs: 1000, durationMs: 750, confidence: 0.88),
        MidiNote(pitch: 72, startTimeMs: 1750, durationMs: 500, confidence: 0.92),
      ],
      bpm: 72.0,
      key: 'Bb major',
      durationMs: 354000,
      confidence: 0.85,
    );
  }
}

/// Datasource local para sesiones de práctica y caché de stems
abstract class PracticeLocalDataSource {
  Future<List<PracticeSession>> getSessionHistory({int limit, int offset});
  Future<PracticeSession?> getSession(String sessionId);
  Future<void> saveSession(PracticeSession session);
  Future<void> deleteSession(String sessionId);
  Future<List<PracticeSession>> getSessionsBySong(String songId);
  Future<PracticeStats> getPracticeStats();
}

/// Implementación con SharedPreferences
class PracticeLocalDataSourceImpl implements PracticeLocalDataSource {
  static const _sessionsKey = 'lyricflow_practice_sessions';
  final SharedPreferences _prefs;

  PracticeLocalDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  @override
  Future<List<PracticeSession>> getSessionHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final sessions = await _loadAllSessions();
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      final end = (offset + limit).clamp(0, sessions.length);
      return sessions.sublist(offset.clamp(0, sessions.length), end);
    } catch (e) {
      throw CacheException(message: 'Error loading sessions: $e');
    }
  }

  @override
  Future<PracticeSession?> getSession(String sessionId) async {
    final sessions = await _loadAllSessions();
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession(PracticeSession session) async {
    try {
      final sessions = await _loadAllSessions();
      sessions.removeWhere((s) => s.id == session.id);
      sessions.insert(0, session);
      await _saveAllSessions(sessions);
    } catch (e) {
      throw CacheException(message: 'Error saving session: $e');
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final sessions = await _loadAllSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await _saveAllSessions(sessions);
  }

  @override
  Future<List<PracticeSession>> getSessionsBySong(String songId) async {
    final sessions = await _loadAllSessions();
    return sessions.where((s) => s.songId == songId).toList();
  }

  @override
  Future<PracticeStats> getPracticeStats() async {
    final sessions = await _loadAllSessions();
    final completed = sessions.where((s) => s.isCompleted).toList();

    if (completed.isEmpty) return const PracticeStats();

    final totalAccuracy = completed.fold<double>(
      0.0,
      (sum, s) => sum + s.accuracy,
    );

    final sessionsByMode = <PracticeMode, int>{};
    final sessionsByLang = <String, int>{};
    int bestStreak = 0;
    int totalWords = 0;
    int totalMinutes = 0;
    final songIds = <String>{};

    for (final s in completed) {
      sessionsByMode[s.mode] = (sessionsByMode[s.mode] ?? 0) + 1;
      sessionsByLang[s.language] = (sessionsByLang[s.language] ?? 0) + 1;
      if (s.bestStreak > bestStreak) bestStreak = s.bestStreak;
      totalWords += s.totalAttempts;
      totalMinutes += s.elapsedTimeMs ~/ 60000;
      songIds.add(s.songId);
    }

    return PracticeStats(
      totalSessions: completed.length,
      totalWordsPracticed: totalWords,
      averageAccuracy: totalAccuracy / completed.length,
      bestStreak: bestStreak,
      totalPracticeMinutes: totalMinutes,
      uniqueSongsPracticed: songIds.length,
      sessionsByMode: sessionsByMode,
      sessionsByLanguage: sessionsByLang,
    );
  }

  // ─── Helpers ───

  Future<List<PracticeSession>> _loadAllSessions() async {
    final jsonStr = _prefs.getString(_sessionsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    final list = json.decode(jsonStr) as List<dynamic>;
    return List<PracticeSession>.from(list.map((item) => _sessionFromJson(item as Map<String, dynamic>)));
  }

  Future<void> _saveAllSessions(List<PracticeSession> sessions) async {
    final list = sessions.map(_sessionToJson).toList();
    await _prefs.setString(_sessionsKey, json.encode(list));
  }

  Map<String, dynamic> _sessionToJson(PracticeSession s) => {
        'id': s.id,
        'songId': s.songId,
        'songTitle': s.songTitle,
        'songArtist': s.songArtist,
        'mode': s.mode.index,
        'difficulty': s.difficulty.index,
        'score': s.score,
        'maxScore': s.maxScore,
        'currentStreak': s.currentStreak,
        'bestStreak': s.bestStreak,
        'elapsedTimeMs': s.elapsedTimeMs,
        'status': s.status.index,
        'language': s.language,
        'startedAt': s.startedAt.toIso8601String(),
        'completedAt': s.completedAt?.toIso8601String(),
        'correctCount': s.correctCount,
        'totalAttempts': s.totalAttempts,
      };

  PracticeSession _sessionFromJson(Map<String, dynamic> j) => PracticeSession(
        id: j['id'] as String,
        songId: j['songId'] as String,
        songTitle: j['songTitle'] as String,
        songArtist: j['songArtist'] as String,
        mode: PracticeMode.values[j['mode'] as int? ?? 0],
        difficulty: PracticeDifficulty.values[j['difficulty'] as int? ?? 1],
        score: j['score'] as int? ?? 0,
        maxScore: j['maxScore'] as int? ?? 0,
        currentStreak: j['currentStreak'] as int? ?? 0,
        bestStreak: j['bestStreak'] as int? ?? 0,
        elapsedTimeMs: j['elapsedTimeMs'] as int? ?? 0,
        status: PracticeSessionStatus.values[j['status'] as int? ?? 0],
        language: j['language'] as String? ?? 'unknown',
        startedAt: DateTime.parse(j['startedAt'] as String),
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
      );
}
