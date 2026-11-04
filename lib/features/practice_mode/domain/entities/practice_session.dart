import 'package:equatable/equatable.dart';

/// Entidad de dominio para sesiones de práctica
///
/// Registra el progreso del usuario en una sesión de
/// aprendizaje con letras. Soporta múltiples modos de práctica
/// y lleva puntuación para gamificación.
///
/// Principio SRP: Solo modela datos de una sesión de práctica.
class PracticeSession extends Equatable {
  /// ID único de la sesión
  final String id;

  /// ID de la canción que se practica
  final String songId;

  /// Título de la canción (para mostrar sin tener que cargar Song)
  final String songTitle;

  /// Artista de la canción
  final String songArtist;

  /// Modo de práctica activo
  final PracticeMode mode;

  /// Dificultad de la sesión
  final PracticeDifficulty difficulty;

  /// Lista de intentos/respuestas del usuario
  final List<PracticeAttempt> attempts;

  /// Puntuación total (0 - maxScore)
  final int score;

  /// Puntuación máxima posible
  final int maxScore;

  /// Racha actual (respuestas correctas consecutivas)
  final int currentStreak;

  /// Mejor racha en esta sesión
  final int bestStreak;

  /// Tiempo total de la sesión en milisegundos
  final int elapsedTimeMs;

  /// Estado de la sesión
  final PracticeSessionStatus status;

  /// Idioma de las letras que se practican
  final String language;

  /// Timestamp de inicio
  final DateTime startedAt;

  /// Timestamp de finalización (null si aún en progreso)
  final DateTime? completedAt;

  const PracticeSession({
    required this.id,
    required this.songId,
    required this.songTitle,
    required this.songArtist,
    this.mode = PracticeMode.fillBlanks,
    this.difficulty = PracticeDifficulty.medium,
    this.attempts = const [],
    this.score = 0,
    this.maxScore = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.elapsedTimeMs = 0,
    this.status = PracticeSessionStatus.inProgress,
    this.language = 'unknown',
    required this.startedAt,
    this.completedAt,
  });

  // ─── Computed Properties ───

  /// Porcentaje de aciertos (0.0 - 1.0)
  double get accuracy {
    if (attempts.isEmpty) return 0.0;
    final correct = attempts.where((a) => a.isCorrect).length;
    return correct / attempts.length;
  }

  /// Porcentaje de aciertos formateado
  String get accuracyPercent => '${(accuracy * 100).toStringAsFixed(0)}%';

  /// Porcentaje de progreso (0.0 - 1.0)
  double get progress {
    if (maxScore == 0) return 0.0;
    return score / maxScore;
  }

  /// Porcentaje de progreso formateado
  String get progressPercent => '${(progress * 100).toStringAsFixed(0)}%';

  /// Número de respuestas correctas
  int get correctCount => attempts.where((a) => a.isCorrect).length;

  /// Número de respuestas incorrectas
  int get incorrectCount => attempts.where((a) => !a.isCorrect).length;

  /// Número total de intentos
  int get totalAttempts => attempts.length;

  /// Tiempo formateado
  String get formattedElapsedTime {
    final minutes = elapsedTimeMs ~/ 60000;
    final seconds = (elapsedTimeMs % 60000) ~/ 1000;
    return '${minutes}m ${seconds}s';
  }

  /// ¿Se completó la sesión?
  bool get isCompleted => status == PracticeSessionStatus.completed;

  /// ¿Se abandonó la sesión?
  bool get isAbandoned => status == PracticeSessionStatus.abandoned;

  /// Calificación por estrellas (1-5)
  int get starRating {
    if (accuracy >= 0.95) return 5;
    if (accuracy >= 0.85) return 4;
    if (accuracy >= 0.70) return 3;
    if (accuracy >= 0.50) return 2;
    return 1;
  }

  /// Palabras nuevas aprendidas en esta sesión
  List<String> get newWordsLearned {
    return attempts
        .where((a) => a.isCorrect && a.isNewWord)
        .map((a) => a.word)
        .toList();
  }

  /// Palabras que necesitan más práctica
  List<String> get wordsToReview {
    return attempts
        .where((a) => !a.isCorrect)
        .map((a) => a.word)
        .toSet()
        .toList();
  }

  // ─── CopyWith ───

  PracticeSession copyWith({
    String? id,
    String? songId,
    String? songTitle,
    String? songArtist,
    PracticeMode? mode,
    PracticeDifficulty? difficulty,
    List<PracticeAttempt>? attempts,
    int? score,
    int? maxScore,
    int? currentStreak,
    int? bestStreak,
    int? elapsedTimeMs,
    PracticeSessionStatus? status,
    String? language,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return PracticeSession(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      songTitle: songTitle ?? this.songTitle,
      songArtist: songArtist ?? this.songArtist,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      attempts: attempts ?? this.attempts,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      elapsedTimeMs: elapsedTimeMs ?? this.elapsedTimeMs,
      status: status ?? this.status,
      language: language ?? this.language,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        songId,
        songTitle,
        songArtist,
        mode,
        difficulty,
        attempts,
        score,
        maxScore,
        currentStreak,
        bestStreak,
        elapsedTimeMs,
        status,
        language,
        startedAt,
        completedAt,
      ];

  @override
  String toString() =>
      'PracticeSession(id: $id, song: "$songTitle", score: $score/$maxScore, accuracy: $accuracyPercent)';
}

/// Un intento individual de respuesta
class PracticeAttempt extends Equatable {
  /// Palabra que se pidió
  final String word;

  /// Respuesta del usuario
  final String userAnswer;

  /// ¿Fue correcta?
  final bool isCorrect;

  /// Tiempo que tardó en responder (milisegundos)
  final int responseTimeMs;

  /// Posición en la letra (línea)
  final int lineIndex;

  /// Posición en la línea (índice de palabra)
  final int wordIndex;

  /// ¿Es una palabra nueva para el usuario?
  final bool isNewWord;

  /// Hint que se mostró (si alguno)
  final String? hintUsed;

  const PracticeAttempt({
    required this.word,
    required this.userAnswer,
    required this.isCorrect,
    this.responseTimeMs = 0,
    this.lineIndex = 0,
    this.wordIndex = 0,
    this.isNewWord = false,
    this.hintUsed,
  });

  /// ¿Se usó una pista?
  bool get usedHint => hintUsed != null;

  /// Tiempo de respuesta formateado
  String get formattedResponseTime {
    if (responseTimeMs < 1000) return '${responseTimeMs}ms';
    return '${(responseTimeMs / 1000).toStringAsFixed(1)}s';
  }

  @override
  List<Object?> get props => [
        word,
        userAnswer,
        isCorrect,
        responseTimeMs,
        lineIndex,
        wordIndex,
        isNewWord,
        hintUsed,
      ];
}

/// Modos de práctica disponibles
enum PracticeMode {
  /// Rellenar palabras que faltan
  fillBlanks,

  /// Se muestra solo la primera letra
  firstLetter,

  /// Escribir la línea completa
  fullLine,

  /// Escuchar y escribir (dictado)
  listening,

  /// Elegir la traducción correcta
  translation,

  /// Ordenar palabras desordenadas
  wordOrder;

  String get displayName {
    switch (this) {
      case PracticeMode.fillBlanks:
        return 'Completar Palabras';
      case PracticeMode.firstLetter:
        return 'Primera Letra';
      case PracticeMode.fullLine:
        return 'Línea Completa';
      case PracticeMode.listening:
        return 'Dictado';
      case PracticeMode.translation:
        return 'Traducción';
      case PracticeMode.wordOrder:
        return 'Ordenar Palabras';
    }
  }

  String get description {
    switch (this) {
      case PracticeMode.fillBlanks:
        return 'Completa las palabras que faltan en la letra';
      case PracticeMode.firstLetter:
        return 'Adivina la palabra con solo la primera letra';
      case PracticeMode.fullLine:
        return 'Escribe la línea completa de memoria';
      case PracticeMode.listening:
        return 'Escucha el audio y transcribe lo que oyes';
      case PracticeMode.translation:
        return 'Elige la traducción correcta de cada línea';
      case PracticeMode.wordOrder:
        return 'Ordena las palabras para formar la línea correcta';
    }
  }

  String get iconName {
    switch (this) {
      case PracticeMode.fillBlanks:
        return 'edit_note';
      case PracticeMode.firstLetter:
        return 'text_fields';
      case PracticeMode.fullLine:
        return 'notes';
      case PracticeMode.listening:
        return 'headphones';
      case PracticeMode.translation:
        return 'translate';
      case PracticeMode.wordOrder:
        return 'sort';
    }
  }
}

/// Niveles de dificultad
enum PracticeDifficulty {
  easy,
  medium,
  hard,
  expert;

  String get displayName {
    switch (this) {
      case PracticeDifficulty.easy:
        return 'Fácil';
      case PracticeDifficulty.medium:
        return 'Normal';
      case PracticeDifficulty.hard:
        return 'Difícil';
      case PracticeDifficulty.expert:
        return 'Experto';
    }
  }

  /// Porcentaje de palabras ocultas según dificultad
  double get blankPercentage {
    switch (this) {
      case PracticeDifficulty.easy:
        return 0.2; // 20% de palabras ocultas
      case PracticeDifficulty.medium:
        return 0.4;
      case PracticeDifficulty.hard:
        return 0.6;
      case PracticeDifficulty.expert:
        return 0.8;
    }
  }

  /// Multiplicador de puntuación
  double get scoreMultiplier {
    switch (this) {
      case PracticeDifficulty.easy:
        return 1.0;
      case PracticeDifficulty.medium:
        return 1.5;
      case PracticeDifficulty.hard:
        return 2.0;
      case PracticeDifficulty.expert:
        return 3.0;
    }
  }
}

/// Estados de una sesión de práctica
enum PracticeSessionStatus {
  inProgress,
  paused,
  completed,
  abandoned;
}
