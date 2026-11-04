import 'package:equatable/equatable.dart';

/// Entidad de dominio para transcripciones generadas por IA
///
/// Representa el resultado de procesar audio con Whisper u otro
/// modelo de transcripción. Incluye confianza, idioma detectado,
/// y segmentos con timestamps para sincronización.
///
/// ⚠️ LEGAL: Las transcripciones IA son contenido derivado.
/// Siempre mostrar disclaimer y no almacenar permanentemente.
class Transcription extends Equatable {
  /// ID único de la transcripción
  final String id;

  /// ID de la canción asociada
  final String songId;

  /// Texto completo de la transcripción
  final String fullText;

  /// Segmentos con timestamps y confianza individual
  final List<TranscriptionSegment> segments;

  /// Idioma detectado (ISO 639-1)
  final String detectedLanguage;

  /// Confianza general de la transcripción (0.0 - 1.0)
  final double confidence;

  /// Modelo utilizado (whisper-1, whisper-large-v3, etc.)
  final String model;

  /// Duración del audio procesado en milisegundos
  final int audioDurationMs;

  /// Tiempo que tomó procesar en milisegundos
  final int processingTimeMs;

  /// Estado de la transcripción
  final TranscriptionStatus status;

  /// Timestamp de creación
  final DateTime createdAt;

  /// TTL: Tiempo de vida antes de expirar (en minutos)
  /// Para cumplimiento legal, las transcripciones no se almacenan
  /// permanentemente — se regeneran bajo demanda.
  final int ttlMinutes;

  const Transcription({
    required this.id,
    required this.songId,
    required this.fullText,
    this.segments = const [],
    this.detectedLanguage = 'unknown',
    this.confidence = 0.0,
    this.model = 'whisper-1',
    this.audioDurationMs = 0,
    this.processingTimeMs = 0,
    this.status = TranscriptionStatus.completed,
    required this.createdAt,
    this.ttlMinutes = 60, // 1 hora por defecto
  });

  // ─── Computed Properties ───

  /// ¿La transcripción ha expirado?
  bool get isExpired {
    final expiry = createdAt.add(Duration(minutes: ttlMinutes));
    return DateTime.now().isAfter(expiry);
  }

  /// Tiempo restante antes de expirar
  Duration get timeUntilExpiry {
    final expiry = createdAt.add(Duration(minutes: ttlMinutes));
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Confianza como porcentaje formateado
  String get confidencePercent =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  /// ¿Es una transcripción de alta calidad?
  bool get isHighQuality => confidence >= 0.8;

  /// ¿Es una transcripción de calidad media?
  bool get isMediumQuality => confidence >= 0.5 && confidence < 0.8;

  /// ¿Es una transcripción de baja calidad?
  bool get isLowQuality => confidence < 0.5;

  /// Calificación de calidad como texto
  String get qualityLabel {
    if (isHighQuality) return 'Alta precisión';
    if (isMediumQuality) return 'Precisión media';
    return 'Baja precisión — revisar manualmente';
  }

  /// Número de palabras transcritas
  int get wordCount => fullText.split(RegExp(r'\s+')).length;

  /// Duración formateada del audio
  String get formattedAudioDuration {
    final minutes = audioDurationMs ~/ 60000;
    final seconds = (audioDurationMs % 60000) ~/ 1000;
    return '${minutes}m ${seconds}s';
  }

  /// Velocidad de procesamiento (x veces en tiempo real)
  String get processingSpeed {
    if (processingTimeMs == 0 || audioDurationMs == 0) return 'N/A';
    final speed = audioDurationMs / processingTimeMs;
    return '${speed.toStringAsFixed(1)}x';
  }

  // ─── CopyWith ───

  Transcription copyWith({
    String? id,
    String? songId,
    String? fullText,
    List<TranscriptionSegment>? segments,
    String? detectedLanguage,
    double? confidence,
    String? model,
    int? audioDurationMs,
    int? processingTimeMs,
    TranscriptionStatus? status,
    DateTime? createdAt,
    int? ttlMinutes,
  }) {
    return Transcription(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      fullText: fullText ?? this.fullText,
      segments: segments ?? this.segments,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      confidence: confidence ?? this.confidence,
      model: model ?? this.model,
      audioDurationMs: audioDurationMs ?? this.audioDurationMs,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      ttlMinutes: ttlMinutes ?? this.ttlMinutes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        songId,
        fullText,
        segments,
        detectedLanguage,
        confidence,
        model,
        audioDurationMs,
        processingTimeMs,
        status,
        createdAt,
        ttlMinutes,
      ];

  @override
  String toString() =>
      'Transcription(id: $id, lang: $detectedLanguage, confidence: $confidencePercent, status: $status)';
}

/// Segmento individual de una transcripción con timestamps
class TranscriptionSegment extends Equatable {
  /// Texto del segmento
  final String text;

  /// Timestamp de inicio en milisegundos
  final int startTimeMs;

  /// Timestamp de fin en milisegundos
  final int endTimeMs;

  /// Confianza de este segmento específico (0.0 - 1.0)
  final double confidence;

  /// Idioma detectado para este segmento (útil para canciones multilingües)
  final String? language;

  /// Indica si es posiblemente un artefacto/alucinación del modelo
  final bool isPossibleHallucination;

  const TranscriptionSegment({
    required this.text,
    required this.startTimeMs,
    required this.endTimeMs,
    this.confidence = 0.0,
    this.language,
    this.isPossibleHallucination = false,
  });

  /// Duración del segmento
  int get durationMs => endTimeMs - startTimeMs;

  /// Timestamp formateado
  String get formattedTime {
    final minutes = startTimeMs ~/ 60000;
    final seconds = (startTimeMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  TranscriptionSegment copyWith({
    String? text,
    int? startTimeMs,
    int? endTimeMs,
    double? confidence,
    String? language,
    bool? isPossibleHallucination,
  }) {
    return TranscriptionSegment(
      text: text ?? this.text,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      confidence: confidence ?? this.confidence,
      language: language ?? this.language,
      isPossibleHallucination:
          isPossibleHallucination ?? this.isPossibleHallucination,
    );
  }

  @override
  List<Object?> get props => [
        text,
        startTimeMs,
        endTimeMs,
        confidence,
        language,
        isPossibleHallucination,
      ];
}

/// Estados posibles de una transcripción
enum TranscriptionStatus {
  /// Esperando en cola
  pending,

  /// Procesando audio
  processing,

  /// Completada exitosamente
  completed,

  /// Error durante el procesamiento
  failed,

  /// Expirada (pasó el TTL)
  expired;

  bool get isTerminal =>
      this == completed || this == failed || this == expired;
}
