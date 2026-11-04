import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/song.dart';

/// Contrato abstracto para el repositorio de reconocimiento de canciones
///
/// Define las operaciones disponibles para identificar canciones.
/// La capa de datos implementa esta interfaz, cumpliendo
/// el Dependency Inversion Principle: el dominio NO depende de la data.
///
/// Usa [Either] de dartz para manejo funcional de errores:
/// - Left(Failure) → error tipado
/// - Right(Song) → resultado exitoso
abstract class ISongRecognitionRepository {
  /// Reconocer una canción a partir de audio grabado
  ///
  /// [audioBytes] - Audio en formato raw (WAV/WebM/MP3)
  /// [durationMs] - Duración de la grabación en milisegundos
  /// Returns Either<AppFailure, Song>
  Future<Either<AppFailure, Song>> recognizeSong({
    required List<int> audioBytes,
    required int durationMs,
  });

  /// Reconocer canción por tarareo/canturreo (si la API lo soporta)
  ///
  /// [audioBytes] - Audio del usuario tarareando
  Future<Either<AppFailure, Song>> recognizeByHumming({
    required List<int> audioBytes,
  });

  /// Buscar una canción por título y/o artista
  ///
  /// [query] - Texto de búsqueda (ej: "Bohemian Rhapsody Queen")
  Future<Either<AppFailure, List<Song>>> searchSong({
    required String query,
  });

  /// Obtener detalles completos de una canción por ID
  ///
  /// [songId] - Identificador único de la canción
  /// [source] - Fuente del ID (acrcloud, audd, etc.)
  Future<Either<AppFailure, Song>> getSongDetails({
    required String songId,
    required String source,
  });

  /// Obtener historial de canciones reconocidas (desde almacenamiento local)
  Future<Either<AppFailure, List<Song>>> getRecognitionHistory();

  /// Guardar una canción en el historial local
  Future<Either<AppFailure, void>> saveToHistory(Song song);

  /// Limpiar historial de reconocimiento
  Future<Either<AppFailure, void>> clearHistory();
}
