import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/practice_session.dart';
import '../../domain/entities/stem.dart';
import '../../domain/entities/midi_track.dart';
import '../../domain/repositories/i_practice_repository.dart';
import '../../domain/usecases/get_practice_resources_usecase.dart';
import '../../domain/usecases/separate_stems_usecase.dart';
import '../../domain/usecases/generate_midi_usecase.dart';
import '../../../../core/providers/app_providers.dart';

/// ═══════════════════════════════════════════
/// Estado del modo práctica
/// ═══════════════════════════════════════════

class PracticeModeState {
  /// Recursos cargados para práctica
  final AsyncValue<PracticeResources?> resources;

  /// Sesión activa
  final PracticeSession? activeSession;

  /// Estado de stems
  final AsyncValue<StemSeparationResult?> stemsResult;

  /// Estado de MIDI
  final AsyncValue<MidiTrack?> midiResult;

  /// Historial de sesiones
  final AsyncValue<List<PracticeSession>> sessionHistory;

  /// Estadísticas
  final AsyncValue<PracticeStats?> stats;

  /// Modo de práctica seleccionado
  final PracticeMode selectedMode;

  /// Dificultad seleccionada
  final PracticeDifficulty selectedDifficulty;

  /// Índice de la línea actual en práctica
  final int currentLineIndex;

  /// ¿Está en pausa?
  final bool isPaused;

  const PracticeModeState({
    this.resources = const AsyncValue.data(null),
    this.activeSession,
    this.stemsResult = const AsyncValue.data(null),
    this.midiResult = const AsyncValue.data(null),
    this.sessionHistory = const AsyncValue.data([]),
    this.stats = const AsyncValue.data(null),
    this.selectedMode = PracticeMode.fillBlanks,
    this.selectedDifficulty = PracticeDifficulty.medium,
    this.currentLineIndex = 0,
    this.isPaused = false,
  });

  bool get isLoading => resources.isLoading;
  bool get hasResources => resources.valueOrNull != null;
  bool get isInSession => activeSession != null;
  bool get hasError => resources.hasError;

  PracticeModeState copyWith({
    AsyncValue<PracticeResources?>? resources,
    PracticeSession? activeSession,
    AsyncValue<StemSeparationResult?>? stemsResult,
    AsyncValue<MidiTrack?>? midiResult,
    AsyncValue<List<PracticeSession>>? sessionHistory,
    AsyncValue<PracticeStats?>? stats,
    PracticeMode? selectedMode,
    PracticeDifficulty? selectedDifficulty,
    int? currentLineIndex,
    bool? isPaused,
  }) {
    return PracticeModeState(
      resources: resources ?? this.resources,
      activeSession: activeSession ?? this.activeSession,
      stemsResult: stemsResult ?? this.stemsResult,
      midiResult: midiResult ?? this.midiResult,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      stats: stats ?? this.stats,
      selectedMode: selectedMode ?? this.selectedMode,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      currentLineIndex: currentLineIndex ?? this.currentLineIndex,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

/// ═══════════════════════════════════════════
/// Notifier del modo práctica
/// ═══════════════════════════════════════════

class PracticeModeNotifier extends Notifier<PracticeModeState> {
  @override
  PracticeModeState build() {
    _loadSessionHistory();
    _loadStats();
    return const PracticeModeState();
  }

  /// Seleccionar modo de práctica
  void selectMode(PracticeMode mode) {
    state = state.copyWith(selectedMode: mode);
  }

  /// Seleccionar dificultad
  void selectDifficulty(PracticeDifficulty difficulty) {
    state = state.copyWith(selectedDifficulty: difficulty);
  }

  /// Iniciar sesión de práctica con todos los recursos
  Future<void> startPractice({
    required String songId,
    required String songTitle,
    required String songArtist,
    String? isrc,
  }) async {
    state = state.copyWith(
      resources: const AsyncValue.loading(),
    );

    final useCase = ref.read(getPracticeResourcesUseCaseProvider);
    final result = await useCase(GetPracticeResourcesParams(
      songId: songId,
      songTitle: songTitle,
      songArtist: songArtist,
      isrc: isrc,
      mode: state.selectedMode,
      difficulty: state.selectedDifficulty,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          resources: AsyncValue.error(failure.message, StackTrace.current),
        );
      },
      (resources) {
        state = state.copyWith(
          resources: AsyncValue.data(resources),
          activeSession: resources.session,
          currentLineIndex: 0,
        );
      },
    );
  }

  /// Registrar un intento de respuesta
  void submitAnswer({
    required String word,
    required String userAnswer,
    required int lineIndex,
    required int wordIndex,
    required int responseTimeMs,
  }) {
    if (state.activeSession == null) return;

    final isCorrect = word.toLowerCase().trim() == userAnswer.toLowerCase().trim();

    final attempt = PracticeAttempt(
      word: word,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      lineIndex: lineIndex,
      wordIndex: wordIndex,
    );

    final currentSession = state.activeSession!;
    final newAttempts = [...currentSession.attempts, attempt];
    final newScore = isCorrect
        ? currentSession.score + (10 * currentSession.difficulty.scoreMultiplier).round()
        : currentSession.score;
    final newStreak = isCorrect ? currentSession.currentStreak + 1 : 0;
    final newBestStreak = newStreak > currentSession.bestStreak
        ? newStreak
        : currentSession.bestStreak;

    final updatedSession = currentSession.copyWith(
      attempts: newAttempts,
      score: newScore,
      maxScore: currentSession.maxScore + 10,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
    );

    state = state.copyWith(activeSession: updatedSession);

    // Guardar progreso
    _saveSession(updatedSession);
  }

  /// Avanzar a la siguiente línea
  void nextLine() {
    final lyrics = state.resources.valueOrNull?.lyrics;
    if (lyrics == null) return;

    final nextIndex = state.currentLineIndex + 1;
    if (nextIndex >= lyrics.lineCount) {
      // Sesión completada
      completeSession();
      return;
    }

    state = state.copyWith(currentLineIndex: nextIndex);
  }

  /// Retroceder a la línea anterior
  void previousLine() {
    if (state.currentLineIndex > 0) {
      state = state.copyWith(currentLineIndex: state.currentLineIndex - 1);
    }
  }

  /// Pausar/reanudar sesión
  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  /// Completar sesión
  Future<void> completeSession() async {
    if (state.activeSession == null) return;

    final completed = state.activeSession!.copyWith(
      status: PracticeSessionStatus.completed,
      completedAt: DateTime.now(),
    );

    final repo = ref.read(practiceRepositoryProvider);
    await repo.completeSession(sessionId: completed.id);

    state = state.copyWith(activeSession: completed);
    _loadSessionHistory();
    _loadStats();
  }

  /// Abandonar sesión
  Future<void> abandonSession() async {
    if (state.activeSession == null) return;

    final abandoned = state.activeSession!.copyWith(
      status: PracticeSessionStatus.abandoned,
      completedAt: DateTime.now(),
    );

    await _saveSession(abandoned);
    state = state.copyWith(
      activeSession: null,
      resources: const AsyncValue.data(null),
      currentLineIndex: 0,
    );
    _loadSessionHistory();
  }

  /// Separar stems de una canción
  Future<void> requestStemSeparation({
    required List<int> audioBytes,
    required String songId,
  }) async {
    state = state.copyWith(
      stemsResult: const AsyncValue.loading(),
    );

    final useCase = ref.read(separateStemsUseCaseProvider);
    final result = await useCase(SeparateStemsParams(
      audioBytes: audioBytes,
      songId: songId,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          stemsResult: AsyncValue.error(failure.message, StackTrace.current),
        );
      },
      (stemResult) {
        state = state.copyWith(
          stemsResult: AsyncValue.data(stemResult),
        );
      },
    );
  }

  /// Extraer MIDI de un stem
  Future<void> requestMidiExtraction({
    required String stemId,
    required String audioUrl,
    required String songId,
  }) async {
    state = state.copyWith(
      midiResult: const AsyncValue.loading(),
    );

    final useCase = ref.read(generateMidiUseCaseProvider);
    final result = await useCase(GenerateMidiParams(
      stemId: stemId,
      audioUrl: audioUrl,
      songId: songId,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          midiResult: AsyncValue.error(failure.message, StackTrace.current),
        );
      },
      (midiTrack) {
        state = state.copyWith(
          midiResult: AsyncValue.data(midiTrack),
        );
      },
    );
  }

  /// Reset completo
  void reset() {
    state = const PracticeModeState();
    _loadSessionHistory();
    _loadStats();
  }

  // ─── Private ───

  Future<void> _saveSession(PracticeSession session) async {
    final repo = ref.read(practiceRepositoryProvider);
    await repo.updateSession(session: session);
  }

  Future<void> _loadSessionHistory() async {
    final repo = ref.read(practiceRepositoryProvider);
    final result = await repo.getSessionHistory();
    result.fold(
      (_) {},
      (sessions) {
        state = state.copyWith(
          sessionHistory: AsyncValue.data(sessions),
        );
      },
    );
  }

  Future<void> _loadStats() async {
    final repo = ref.read(practiceRepositoryProvider);
    final result = await repo.getPracticeStats();
    result.fold(
      (_) {},
      (stats) {
        state = state.copyWith(
          stats: AsyncValue.data(stats),
        );
      },
    );
  }
}

/// Provider del modo práctica
final practiceModeProvider =
    NotifierProvider<PracticeModeNotifier, PracticeModeState>(
  PracticeModeNotifier.new,
);

/// ═══════════════════════════════════════════
/// Providers de conveniencia (selectors)
/// ═══════════════════════════════════════════

/// Sesión activa
final activeSessionProvider = Provider<PracticeSession?>((ref) {
  return ref.watch(practiceModeProvider).activeSession;
});

/// Historial de sesiones
final practiceHistoryProvider =
    Provider<AsyncValue<List<PracticeSession>>>((ref) {
  return ref.watch(practiceModeProvider).sessionHistory;
});

/// Estadísticas de práctica
final practiceStatsProvider = Provider<AsyncValue<PracticeStats?>>((ref) {
  return ref.watch(practiceModeProvider).stats;
});

/// Modo seleccionado
final selectedPracticeModeProvider = Provider<PracticeMode>((ref) {
  return ref.watch(practiceModeProvider).selectedMode;
});

/// Dificultad seleccionada
final selectedDifficultyProvider = Provider<PracticeDifficulty>((ref) {
  return ref.watch(practiceModeProvider).selectedDifficulty;
});
