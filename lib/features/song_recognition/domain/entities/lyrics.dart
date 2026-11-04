import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa las letras de una canción
///
/// Soporta letras sincronizadas (con timestamps) y no sincronizadas.
/// El modelo pass-through garantiza que NO se almacenan letras
/// en el servidor — solo se muestran al usuario en tiempo real.
///
/// Principio SRP: Solo modela datos de letras y su sincronización.
class Lyrics extends Equatable {
  /// ID de la canción a la que pertenecen
  final String songId;

  /// Lista de líneas de la letra (con timestamps opcionales)
  final List<LyricLine> lines;

  /// Idioma de las letras (ISO 639-1: "en", "es", "ja", etc.)
  final String language;

  /// Fuente de las letras (musixmatch, lyricfind, ai_transcription)
  final LyricsSource source;

  /// ¿Están sincronizadas con timestamps?
  final bool isSynced;

  /// Copyright / Atribución requerida
  final String? copyright;

  /// Texto de atribución (ej: "Powered by Musixmatch")
  final String? attribution;

  /// ¿Fueron generadas por IA?
  final bool isAiGenerated;

  /// Confianza de la transcripción IA (0.0 - 1.0)
  final double? aiConfidence;

  const Lyrics({
    required this.songId,
    required this.lines,
    this.language = 'unknown',
    this.source = LyricsSource.unknown,
    this.isSynced = false,
    this.copyright,
    this.attribution,
    this.isAiGenerated = false,
    this.aiConfidence,
  });

  // ─── Computed Properties ───

  /// Texto plano completo (sin timestamps)
  String get plainText => lines.map((l) => l.text).join('\n');

  /// Número total de líneas
  int get lineCount => lines.length;

  /// Número total de palabras
  int get wordCount =>
      lines.fold(0, (sum, line) => sum + line.text.split(' ').length);

  /// ¿Las letras están vacías?
  bool get isEmpty => lines.isEmpty;

  /// ¿Las letras tienen contenido?
  bool get isNotEmpty => lines.isNotEmpty;

  /// Obtener la línea activa dado un timestamp en milisegundos
  LyricLine? getActiveLineAt(int timestampMs) {
    if (!isSynced) return null;
    
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (line.startTimeMs != null && line.startTimeMs! <= timestampMs) {
        // Verificar que no haya pasado el fin de esta línea
        if (line.endTimeMs == null || line.endTimeMs! >= timestampMs) {
          return line;
        }
      }
    }
    return null;
  }

  /// Obtener el índice de la línea activa
  int? getActiveLineIndex(int timestampMs) {
    if (!isSynced) return null;

    for (int i = lines.length - 1; i >= 0; i--) {
      if (lines[i].startTimeMs != null &&
          lines[i].startTimeMs! <= timestampMs) {
        return i;
      }
    }
    return null;
  }

  /// Obtener palabras únicas para vocabulario
  List<String> get uniqueWords {
    final words = <String>{};
    for (final line in lines) {
      for (final word in line.text.split(RegExp(r'\s+'))) {
        final cleaned = word
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .toLowerCase()
            .trim();
        if (cleaned.isNotEmpty && cleaned.length > 2) {
          words.add(cleaned);
        }
      }
    }
    return words.toList()..sort();
  }

  // ─── CopyWith ───

  Lyrics copyWith({
    String? songId,
    List<LyricLine>? lines,
    String? language,
    LyricsSource? source,
    bool? isSynced,
    String? copyright,
    String? attribution,
    bool? isAiGenerated,
    double? aiConfidence,
  }) {
    return Lyrics(
      songId: songId ?? this.songId,
      lines: lines ?? this.lines,
      language: language ?? this.language,
      source: source ?? this.source,
      isSynced: isSynced ?? this.isSynced,
      copyright: copyright ?? this.copyright,
      attribution: attribution ?? this.attribution,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiConfidence: aiConfidence ?? this.aiConfidence,
    );
  }

  @override
  List<Object?> get props => [
        songId,
        lines,
        language,
        source,
        isSynced,
        copyright,
        attribution,
        isAiGenerated,
        aiConfidence,
      ];

  @override
  String toString() =>
      'Lyrics(songId: $songId, lines: ${lines.length}, synced: $isSynced, source: $source)';
}

/// Una línea individual de la letra
///
/// Puede tener timestamps de inicio y fin para sincronización,
/// y opcionalmente palabras individuales con sus propios timestamps.
class LyricLine extends Equatable {
  /// Texto de la línea
  final String text;

  /// Timestamp de inicio en milisegundos
  final int? startTimeMs;

  /// Timestamp de fin en milisegundos
  final int? endTimeMs;

  /// Palabras individuales con timestamps (para word-by-word sync)
  final List<LyricWord>? words;

  /// ¿Es un coro/estribillo?
  final bool isChorus;

  /// ¿Es una línea vacía (separador de secciones)?
  final bool isBlank;

  const LyricLine({
    required this.text,
    this.startTimeMs,
    this.endTimeMs,
    this.words,
    this.isChorus = false,
    this.isBlank = false,
  });

  /// Duración de la línea en milisegundos
  int? get durationMs {
    if (startTimeMs != null && endTimeMs != null) {
      return endTimeMs! - startTimeMs!;
    }
    return null;
  }

  /// Timestamp de inicio formateado como "m:ss"
  String get formattedStartTime {
    if (startTimeMs == null) return '';
    final minutes = startTimeMs! ~/ 60000;
    final seconds = (startTimeMs! % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  LyricLine copyWith({
    String? text,
    int? startTimeMs,
    int? endTimeMs,
    List<LyricWord>? words,
    bool? isChorus,
    bool? isBlank,
  }) {
    return LyricLine(
      text: text ?? this.text,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      words: words ?? this.words,
      isChorus: isChorus ?? this.isChorus,
      isBlank: isBlank ?? this.isBlank,
    );
  }

  @override
  List<Object?> get props =>
      [text, startTimeMs, endTimeMs, words, isChorus, isBlank];
}

/// Una palabra individual con timestamp para sincronización word-by-word
class LyricWord extends Equatable {
  final String text;
  final int startTimeMs;
  final int endTimeMs;

  const LyricWord({
    required this.text,
    required this.startTimeMs,
    required this.endTimeMs,
  });

  int get durationMs => endTimeMs - startTimeMs;

  @override
  List<Object?> get props => [text, startTimeMs, endTimeMs];
}

/// Fuente de las letras
enum LyricsSource {
  musixmatch,
  lyricfind,
  genius,
  aiTranscription,
  userContributed,
  unknown;

  /// Texto de atribución requerido
  String get attributionText {
    switch (this) {
      case LyricsSource.musixmatch:
        return 'Powered by Musixmatch';
      case LyricsSource.lyricfind:
        return 'Licensed by LyricFind';
      case LyricsSource.genius:
        return 'Via Genius';
      case LyricsSource.aiTranscription:
        return 'Transcripción generada por IA — puede contener errores';
      case LyricsSource.userContributed:
        return 'Contribución de la comunidad';
      case LyricsSource.unknown:
        return '';
    }
  }

  /// ¿Requiere disclaimer legal?
  bool get requiresDisclaimer =>
      this == LyricsSource.aiTranscription ||
      this == LyricsSource.userContributed;
}
