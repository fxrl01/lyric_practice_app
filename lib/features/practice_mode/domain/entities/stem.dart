import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa un stem (pista separada)
///
/// Resultado de la separación de audio con Demucs.
/// Cada stem contiene una pista aislada: vocals, drums, bass, etc.
///
/// Principio SRP: Solo modela los datos de un stem de audio.
class Stem extends Equatable {
  /// ID único del stem
  final String id;

  /// ID de la canción original
  final String songId;

  /// Tipo de stem
  final StemType type;

  /// URL o path del archivo de audio del stem
  final String audioUrl;

  /// Duración en milisegundos
  final int durationMs;

  /// Tamaño del archivo en bytes
  final int? fileSizeBytes;

  /// Formato del audio (wav, mp3, flac)
  final String audioFormat;

  /// Sample rate en Hz
  final int sampleRate;

  /// ¿Está actualmente silenciado en el reproductor?
  final bool isMuted;

  /// Volumen actual (0.0 - 1.0)
  final double volume;

  /// Modelo utilizado para la separación (htdemucs, htdemucs_ft, etc.)
  final String model;

  const Stem({
    required this.id,
    required this.songId,
    required this.type,
    required this.audioUrl,
    required this.durationMs,
    this.fileSizeBytes,
    this.audioFormat = 'wav',
    this.sampleRate = 44100,
    this.isMuted = false,
    this.volume = 1.0,
    this.model = 'htdemucs',
  });

  // ─── Computed Properties ───

  /// Nombre legible del stem
  String get displayName => type.displayName;

  /// Icono sugerido para el stem
  String get iconName => type.iconName;

  /// Color sugerido para el stem
  int get colorValue => type.colorValue;

  /// Duración formateada
  String get formattedDuration {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Tamaño formateado
  String get formattedFileSize {
    if (fileSizeBytes == null) return 'N/A';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1048576) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes! / 1048576).toStringAsFixed(1)} MB';
  }

  // ─── CopyWith ───

  Stem copyWith({
    String? id,
    String? songId,
    StemType? type,
    String? audioUrl,
    int? durationMs,
    int? fileSizeBytes,
    String? audioFormat,
    int? sampleRate,
    bool? isMuted,
    double? volume,
    String? model,
  }) {
    return Stem(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      type: type ?? this.type,
      audioUrl: audioUrl ?? this.audioUrl,
      durationMs: durationMs ?? this.durationMs,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      audioFormat: audioFormat ?? this.audioFormat,
      sampleRate: sampleRate ?? this.sampleRate,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      model: model ?? this.model,
    );
  }

  @override
  List<Object?> get props => [
        id,
        songId,
        type,
        audioUrl,
        durationMs,
        fileSizeBytes,
        audioFormat,
        sampleRate,
        isMuted,
        volume,
        model,
      ];

  @override
  String toString() =>
      'Stem(id: $id, type: ${type.name}, muted: $isMuted, vol: $volume)';
}

/// Tipos de stems que Demucs puede separar
enum StemType {
  vocals,
  drums,
  bass,
  guitar,
  piano,
  other;

  /// Nombre para mostrar en UI
  String get displayName {
    switch (this) {
      case StemType.vocals:
        return 'Voz';
      case StemType.drums:
        return 'Batería';
      case StemType.bass:
        return 'Bajo';
      case StemType.guitar:
        return 'Guitarra';
      case StemType.piano:
        return 'Piano';
      case StemType.other:
        return 'Otros';
    }
  }

  /// Nombre del icono Material sugerido
  String get iconName {
    switch (this) {
      case StemType.vocals:
        return 'mic';
      case StemType.drums:
        return 'music_note'; // drum stick
      case StemType.bass:
        return 'equalizer';
      case StemType.guitar:
        return 'queue_music';
      case StemType.piano:
        return 'piano';
      case StemType.other:
        return 'tune';
    }
  }

  /// Color ARGB sugerido para visualización
  int get colorValue {
    switch (this) {
      case StemType.vocals:
        return 0xFFEC4899; // Pink
      case StemType.drums:
        return 0xFFF59E0B; // Amber
      case StemType.bass:
        return 0xFF8B5CF6; // Violet
      case StemType.guitar:
        return 0xFF22C55E; // Green
      case StemType.piano:
        return 0xFF3B82F6; // Blue
      case StemType.other:
        return 0xFF6B7280; // Gray
    }
  }
}

/// Resultado completo de separación de stems
/// 
/// Agrupa todos los stems de una canción procesada.
class StemSeparationResult extends Equatable {
  /// ID del job de procesamiento
  final String jobId;

  /// ID de la canción
  final String songId;

  /// Lista de stems separados
  final List<Stem> stems;

  /// Estado del procesamiento
  final StemProcessingStatus status;

  /// Progreso del procesamiento (0.0 - 1.0)
  final double progress;

  /// Modelo utilizado
  final String model;

  /// Tiempo de procesamiento en milisegundos
  final int? processingTimeMs;

  /// Mensaje de error (si falló)
  final String? errorMessage;

  /// Timestamp de creación
  final DateTime createdAt;

  const StemSeparationResult({
    required this.jobId,
    required this.songId,
    this.stems = const [],
    this.status = StemProcessingStatus.pending,
    this.progress = 0.0,
    this.model = 'htdemucs',
    this.processingTimeMs,
    this.errorMessage,
    required this.createdAt,
  });

  /// Obtener un stem por tipo
  Stem? getStem(StemType type) {
    try {
      return stems.firstWhere((s) => s.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Stem de voz (el más usado para letras)
  Stem? get vocalsStem => getStem(StemType.vocals);

  /// ¿Está completo el procesamiento?
  bool get isComplete => status == StemProcessingStatus.completed;

  StemSeparationResult copyWith({
    String? jobId,
    String? songId,
    List<Stem>? stems,
    StemProcessingStatus? status,
    double? progress,
    String? model,
    int? processingTimeMs,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return StemSeparationResult(
      jobId: jobId ?? this.jobId,
      songId: songId ?? this.songId,
      stems: stems ?? this.stems,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      model: model ?? this.model,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        jobId,
        songId,
        stems,
        status,
        progress,
        model,
        processingTimeMs,
        errorMessage,
        createdAt,
      ];
}

/// Estados de procesamiento de stems
enum StemProcessingStatus {
  pending,
  uploading,
  processing,
  completed,
  failed;
}
