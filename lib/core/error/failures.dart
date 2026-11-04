import 'package:equatable/equatable.dart';

/// Clase base para todos los errores de la aplicación
/// 
/// Cada feature puede extender esta clase para errores específicos.
/// Implementa Equatable para comparaciones en tests.
abstract class AppFailure extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppFailure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'AppFailure($code: $message)';
}

/// Error de red (sin conexión, timeout, etc.)
class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'Error de conexión. Verifica tu internet.',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

/// Error del servidor (500, 502, etc.)
class ServerFailure extends AppFailure {
  final int? statusCode;

  const ServerFailure({
    super.message = 'Error del servidor. Intenta más tarde.',
    super.code = 'SERVER_ERROR',
    this.statusCode,
    super.originalError,
  });

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Error de autenticación (401, 403)
class AuthFailure extends AppFailure {
  const AuthFailure({
    super.message = 'No tienes autorización para esta acción.',
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// Error de validación (datos incorrectos)
class ValidationFailure extends AppFailure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    super.message = 'Datos inválidos. Revisa los campos.',
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.originalError,
  });

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Error de API key no configurada
class ApiKeyMissingFailure extends AppFailure {
  const ApiKeyMissingFailure({
    super.message = 'API key no configurada. Revisa el archivo .env',
    super.code = 'API_KEY_MISSING',
    super.originalError,
  });
}

/// Error de reconocimiento de canción
class RecognitionFailure extends AppFailure {
  const RecognitionFailure({
    super.message = 'No se pudo reconocer la canción. Intenta de nuevo.',
    super.code = 'RECOGNITION_ERROR',
    super.originalError,
  });
}

/// Error de transcripción
class TranscriptionFailure extends AppFailure {
  const TranscriptionFailure({
    super.message = 'Error al transcribir el audio.',
    super.code = 'TRANSCRIPTION_ERROR',
    super.originalError,
  });
}

/// Error de grabación de audio
class AudioRecordingFailure extends AppFailure {
  const AudioRecordingFailure({
    super.message = 'Error al grabar audio. Verifica los permisos del micrófono.',
    super.code = 'AUDIO_RECORDING_ERROR',
    super.originalError,
  });
}

/// Error de permisos
class PermissionFailure extends AppFailure {
  const PermissionFailure({
    super.message = 'Permiso denegado. Habilítalo en configuración.',
    super.code = 'PERMISSION_ERROR',
    super.originalError,
  });
}

/// Error de caché / almacenamiento local
class CacheFailure extends AppFailure {
  const CacheFailure({
    super.message = 'Error de almacenamiento local.',
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// Error desconocido (catch-all)
class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'Error inesperado. Intenta de nuevo.',
    super.code = 'UNKNOWN_ERROR',
    super.originalError,
  });
}
