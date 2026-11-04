import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa una canción reconocida
///
/// Inmutable y libre de dependencias de frameworks.
/// Contiene toda la metadata necesaria para identificar y
/// mostrar información sobre una canción.
///
/// Principio SRP: Solo modela los datos de una canción.
/// Principio OCP: Extensible via herencia sin modificar esta clase.
class Song extends Equatable {
  /// Identificador único (puede venir de ACRCloud, AudD, etc.)
  final String id;

  /// Título de la canción
  final String title;

  /// Nombre del artista principal
  final String artist;

  /// Nombre del álbum (opcional)
  final String? album;

  /// Duración en milisegundos
  final int? durationMs;

  /// Fecha de lanzamiento (ISO 8601)
  final DateTime? releaseDate;

  /// URL de la portada del álbum
  final String? coverUrl;

  /// Género musical
  final String? genre;

  /// ISRC (International Standard Recording Code)
  final String? isrc;

  /// URL de previsualización del audio (si disponible)
  final String? previewUrl;

  /// Fuente del reconocimiento (acrcloud, audd, demo)
  final String source;

  /// Indica si la canción tiene letras disponibles en APIs
  final bool hasLyrics;

  /// Confianza del reconocimiento (0.0 - 1.0)
  final double? confidence;

  /// Timestamp de cuando se reconoció
  final DateTime recognizedAt;

  /// Links externos (Spotify, Apple Music, YouTube, etc.)
  final Map<String, String> externalLinks;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.durationMs,
    this.releaseDate,
    this.coverUrl,
    this.genre,
    this.isrc,
    this.previewUrl,
    this.source = 'unknown',
    this.hasLyrics = false,
    this.confidence,
    DateTime? recognizedAt,
    this.externalLinks = const {},
  }) : recognizedAt = recognizedAt ?? DateTime.now();

  // ─── Factory Constructors ───

  /// Crear una canción de ejemplo (para modo demo)
  factory Song.demo({
    String? id,
    String title = 'Bohemian Rhapsody',
    String artist = 'Queen',
  }) {
    return Song(
      id: id ?? 'demo_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      artist: artist,
      album: 'A Night at the Opera',
      durationMs: 354000,
      releaseDate: DateTime(1975, 10, 31),
      genre: 'Rock',
      source: 'demo',
      hasLyrics: true,
      confidence: 0.95,
      externalLinks: const {
        'spotify': 'https://open.spotify.com/track/example',
        'youtube': 'https://youtube.com/watch?v=example',
      },
    );
  }

  /// Crear Song vacía (estado inicial)
  factory Song.empty() {
    return Song(
      id: '',
      title: '',
      artist: '',
      source: 'none',
    );
  }

  // ─── Computed Properties ───

  /// ¿Es una canción vacía/no inicializada?
  bool get isEmpty => id.isEmpty;

  /// ¿Tiene datos válidos?
  bool get isNotEmpty => id.isNotEmpty;

  /// Duración formateada como "m:ss"
  String get formattedDuration {
    if (durationMs == null) return '--:--';
    final minutes = (durationMs! ~/ 60000);
    final seconds = ((durationMs! % 60000) ~/ 1000);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Año de lanzamiento
  int? get releaseYear => releaseDate?.year;

  /// Porcentaje de confianza formateado
  String get confidencePercent {
    if (confidence == null) return 'N/A';
    return '${(confidence! * 100).toStringAsFixed(0)}%';
  }

  /// ¿Es una canción reconocida con alta confianza?
  bool get isHighConfidence => (confidence ?? 0) >= 0.7;

  /// Display name completo "Artist - Title"
  String get displayName => '$artist — $title';

  // ─── CopyWith ───

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    DateTime? releaseDate,
    String? coverUrl,
    String? genre,
    String? isrc,
    String? previewUrl,
    String? source,
    bool? hasLyrics,
    double? confidence,
    DateTime? recognizedAt,
    Map<String, String>? externalLinks,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      releaseDate: releaseDate ?? this.releaseDate,
      coverUrl: coverUrl ?? this.coverUrl,
      genre: genre ?? this.genre,
      isrc: isrc ?? this.isrc,
      previewUrl: previewUrl ?? this.previewUrl,
      source: source ?? this.source,
      hasLyrics: hasLyrics ?? this.hasLyrics,
      confidence: confidence ?? this.confidence,
      recognizedAt: recognizedAt ?? this.recognizedAt,
      externalLinks: externalLinks ?? this.externalLinks,
    );
  }

  // ─── Equatable ───

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        durationMs,
        releaseDate,
        coverUrl,
        genre,
        isrc,
        previewUrl,
        source,
        hasLyrics,
        confidence,
        externalLinks,
      ];

  @override
  String toString() =>
      'Song(id: $id, title: "$title", artist: "$artist", source: $source)';
}
