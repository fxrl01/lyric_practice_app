import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/lyrics.dart';

/// Contrato abstracto para el repositorio de letras
///
/// Define operaciones para obtener y gestionar letras de canciones.
/// Implementa el modelo pass-through: las letras se obtienen
/// de la API y se muestran al usuario SIN almacenamiento permanente.
///
/// ⚠️ LEGAL: Las letras son propiedad intelectual protegida.
/// Este repositorio NO debe cachear letras permanentemente.
abstract class ILyricsRepository {
  /// Obtener letras de una canción por su ID o metadata
  ///
  /// [songTitle] - Título de la canción
  /// [artist] - Nombre del artista
  /// [isrc] - ISRC code (opcional, más preciso)
  /// [duration] - Duración en ms (para validar match)
  ///
  /// Returns Either con Lyrics (pueden ser synced o no)
  Future<Either<AppFailure, Lyrics>> getLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
    int? duration,
  });

  /// Obtener letras sincronizadas (con timestamps)
  ///
  /// No todas las APIs soportan letras sincronizadas.
  /// Si no están disponibles, retorna letras normales.
  Future<Either<AppFailure, Lyrics>> getSyncedLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
  });

  /// Buscar letras por texto parcial
  ///
  /// [query] - Fragmento de letra para buscar
  Future<Either<AppFailure, List<Lyrics>>> searchByLyricText({
    required String query,
  });

  /// Obtener traducción de las letras
  ///
  /// [lyrics] - Letras originales
  /// [targetLanguage] - Idioma destino (ISO 639-1)
  Future<Either<AppFailure, Lyrics>> getTranslation({
    required Lyrics lyrics,
    required String targetLanguage,
  });

  /// Verificar si hay letras disponibles para una canción
  ///
  /// Más rápido que getLyrics, solo verifica existencia.
  Future<Either<AppFailure, bool>> hasLyrics({
    required String songTitle,
    required String artist,
  });
}
