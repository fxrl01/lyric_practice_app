import 'package:equatable/equatable.dart';

/// Entidad de dominio para secuencias de notas MIDI
///
/// Representa las notas musicales extraídas del audio usando
/// Basic Pitch u otro modelo de transcripción de audio a MIDI.
/// Se usa para mostrar piano roll, tabs de guitarra, etc.
///
/// Principio SRP: Solo modela datos de notas musicales.
class MidiTrack extends Equatable {
  /// ID único del track MIDI
  final String id;

  /// ID de la canción
  final String songId;

  /// ID del stem del que se extrajo (generalmente vocals o guitar)
  final String? stemId;

  /// Lista de notas MIDI
  final List<MidiNote> notes;

  /// Tempo en BPM (beats per minute)
  final double bpm;

  /// Compás (ej: 4/4, 3/4, 6/8)
  final TimeSignature timeSignature;

  /// Tonalidad detectada (ej: "C major", "A minor")
  final String? key;

  /// Duración total en milisegundos
  final int durationMs;

  /// Instrumento sugerido
  final MidiInstrument instrument;

  /// Modelo usado para la extracción
  final String model;

  /// Confianza general (0.0 - 1.0)
  final double confidence;

  const MidiTrack({
    required this.id,
    required this.songId,
    this.stemId,
    this.notes = const [],
    this.bpm = 120.0,
    this.timeSignature = const TimeSignature(),
    this.key,
    this.durationMs = 0,
    this.instrument = MidiInstrument.piano,
    this.model = 'basic_pitch',
    this.confidence = 0.0,
  });

  // ─── Computed Properties ───

  /// Número total de notas
  int get noteCount => notes.length;

  /// Rango de notas (nota más baja a más alta)
  (int, int)? get noteRange {
    if (notes.isEmpty) return null;
    int minNote = 127;
    int maxNote = 0;
    for (final note in notes) {
      if (note.pitch < minNote) minNote = note.pitch;
      if (note.pitch > maxNote) maxNote = note.pitch;
    }
    return (minNote, maxNote);
  }

  /// Nota más alta
  MidiNote? get highestNote {
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a.pitch > b.pitch ? a : b);
  }

  /// Nota más baja
  MidiNote? get lowestNote {
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a.pitch < b.pitch ? a : b);
  }

  /// Obtener notas activas en un timestamp dado
  List<MidiNote> getNotesAtTime(int timestampMs) {
    return notes.where((note) {
      return note.startTimeMs <= timestampMs &&
          (note.startTimeMs + note.durationMs) >= timestampMs;
    }).toList();
  }

  /// Obtener notas en un rango de tiempo
  List<MidiNote> getNotesInRange(int startMs, int endMs) {
    return notes.where((note) {
      return note.startTimeMs < endMs &&
          (note.startTimeMs + note.durationMs) > startMs;
    }).toList();
  }

  /// Duración formateada
  String get formattedDuration {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // ─── CopyWith ───

  MidiTrack copyWith({
    String? id,
    String? songId,
    String? stemId,
    List<MidiNote>? notes,
    double? bpm,
    TimeSignature? timeSignature,
    String? key,
    int? durationMs,
    MidiInstrument? instrument,
    String? model,
    double? confidence,
  }) {
    return MidiTrack(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      stemId: stemId ?? this.stemId,
      notes: notes ?? this.notes,
      bpm: bpm ?? this.bpm,
      timeSignature: timeSignature ?? this.timeSignature,
      key: key ?? this.key,
      durationMs: durationMs ?? this.durationMs,
      instrument: instrument ?? this.instrument,
      model: model ?? this.model,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props => [
        id,
        songId,
        stemId,
        notes,
        bpm,
        timeSignature,
        key,
        durationMs,
        instrument,
        model,
        confidence,
      ];

  @override
  String toString() =>
      'MidiTrack(id: $id, notes: $noteCount, bpm: $bpm, key: $key)';
}

/// Una nota MIDI individual
class MidiNote extends Equatable {
  /// Nota MIDI (0-127, donde 60 = C4 / Do central)
  final int pitch;

  /// Velocidad/intensidad (0-127)
  final int velocity;

  /// Timestamp de inicio en milisegundos
  final int startTimeMs;

  /// Duración en milisegundos
  final int durationMs;

  /// Confianza de detección de esta nota (0.0 - 1.0)
  final double confidence;

  const MidiNote({
    required this.pitch,
    this.velocity = 80,
    required this.startTimeMs,
    required this.durationMs,
    this.confidence = 0.0,
  }) : assert(pitch >= 0 && pitch <= 127, 'MIDI pitch must be 0-127'),
       assert(velocity >= 0 && velocity <= 127, 'MIDI velocity must be 0-127');

  // ─── Computed Properties ───

  /// Timestamp de fin
  int get endTimeMs => startTimeMs + durationMs;

  /// Nombre de la nota (C, C#, D, etc.)
  String get noteName {
    const noteNames = [
      'C', 'C#', 'D', 'D#', 'E', 'F',
      'F#', 'G', 'G#', 'A', 'A#', 'B'
    ];
    return noteNames[pitch % 12];
  }

  /// Octava de la nota
  int get octave => (pitch ~/ 12) - 1;

  /// Nombre completo con octava (ej: "C4", "A#3")
  String get fullName => '$noteName$octave';

  /// Nombre en notación latina (Do, Re, Mi...)
  String get latinName {
    const names = [
      'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa',
      'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'
    ];
    return '${names[pitch % 12]}$octave';
  }

  /// Frecuencia en Hz (A4 = 440Hz)
  double get frequencyHz => 440.0 * _pow2((pitch - 69) / 12.0);

  /// ¿Es una tecla negra en el piano?
  bool get isBlackKey {
    final note = pitch % 12;
    return [1, 3, 6, 8, 10].contains(note);
  }

  /// Intensidad normalizada (0.0 - 1.0)
  double get normalizedVelocity => velocity / 127.0;

  static double _pow2(double x) {
    // 2^x implementation
    return 1.0 * _exp(x * 0.6931471805599453); // ln(2) ≈ 0.693
  }

  static double _exp(double x) {
    // Simple exp approximation
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  MidiNote copyWith({
    int? pitch,
    int? velocity,
    int? startTimeMs,
    int? durationMs,
    double? confidence,
  }) {
    return MidiNote(
      pitch: pitch ?? this.pitch,
      velocity: velocity ?? this.velocity,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      durationMs: durationMs ?? this.durationMs,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props =>
      [pitch, velocity, startTimeMs, durationMs, confidence];

  @override
  String toString() =>
      'MidiNote($fullName, start: ${startTimeMs}ms, dur: ${durationMs}ms)';
}

/// Compás musical
class TimeSignature extends Equatable {
  /// Numerador (ej: 4 en 4/4)
  final int numerator;

  /// Denominador (ej: 4 en 4/4)
  final int denominator;

  const TimeSignature({
    this.numerator = 4,
    this.denominator = 4,
  });

  String get display => '$numerator/$denominator';

  @override
  List<Object?> get props => [numerator, denominator];

  @override
  String toString() => display;
}

/// Instrumentos MIDI
enum MidiInstrument {
  piano,
  guitar,
  bass,
  vocals,
  drums,
  strings,
  synth,
  other;

  String get displayName {
    switch (this) {
      case MidiInstrument.piano:
        return 'Piano';
      case MidiInstrument.guitar:
        return 'Guitarra';
      case MidiInstrument.bass:
        return 'Bajo';
      case MidiInstrument.vocals:
        return 'Voz';
      case MidiInstrument.drums:
        return 'Batería';
      case MidiInstrument.strings:
        return 'Cuerdas';
      case MidiInstrument.synth:
        return 'Sintetizador';
      case MidiInstrument.other:
        return 'Otro';
    }
  }
}
