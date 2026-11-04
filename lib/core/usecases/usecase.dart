import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Clase base abstracta para todos los Use Cases
///
/// Implementa el patrón Command: cada use case es una clase
/// con un único método [call()] que ejecuta una operación.
///
/// Principio SRP: cada use case hace UNA sola cosa.
/// Principio DIP: recibe repositorios via constructor (inyección).
///
/// [Type] - Tipo de retorno exitoso
/// [Params] - Parámetros de entrada
///
/// Ejemplo:
/// ```dart
/// class GetLyrics extends UseCase<Lyrics, GetLyricsParams> {
///   @override
///   Future<Either<AppFailure, Lyrics>> call(GetLyricsParams params) async {
///     return repository.getLyrics(params.title, params.artist);
///   }
/// }
/// ```
abstract class UseCase<Type, Params> {
  Future<Either<AppFailure, Type>> call(Params params);
}

/// Parámetros vacíos para use cases que no requieren input
class NoParams {
  const NoParams();
}
