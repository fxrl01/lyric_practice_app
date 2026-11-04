/// Excepciones personalizadas para la capa de datos
/// 
/// Las excepciones se lanzan en datasources/repositories
/// y se transforman a [AppFailure] en los use cases.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException($code: $message)';
}

class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    super.message = 'Server error',
    super.code = 'SERVER_ERROR',
    this.statusCode,
    super.originalError,
  });
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error',
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

class AudioException extends AppException {
  const AudioException({
    super.message = 'Audio error',
    super.code = 'AUDIO_ERROR',
    super.originalError,
  });
}

class RecognitionException extends AppException {
  const RecognitionException({
    super.message = 'Recognition failed',
    super.code = 'RECOGNITION_ERROR',
    super.originalError,
  });
}

class TranscriptionException extends AppException {
  const TranscriptionException({
    super.message = 'Transcription failed',
    super.code = 'TRANSCRIPTION_ERROR',
    super.originalError,
  });
}
