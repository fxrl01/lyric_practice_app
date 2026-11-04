import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Cliente HTTP genérico para todas las llamadas a APIs
/// 
/// Abstrae Dio para facilitar testing y cambio de implementación.
/// Cada datasource usa este cliente en vez de Dio directamente.
class ApiClient {
  final Dio _dio;
  final Logger _logger;

  ApiClient({required Dio dio, required Logger logger})
      : _dio = dio,
        _logger = logger;

  /// GET request
  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    _logger.d('📡 GET: $url');
    return _dio.get<T>(
      url,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    _logger.d('📡 POST: $url');
    return _dio.post<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  /// POST con multipart (para enviar archivos de audio)
  Future<Response<T>> postMultipart<T>(
    String url, {
    required FormData formData,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    _logger.d('📡 POST (multipart): $url');
    return _dio.post<T>(
      url,
      data: formData,
      options: Options(
        headers: {
          ...?headers,
          'Content-Type': 'multipart/form-data',
        },
      ),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    _logger.d('📡 PUT: $url');
    return _dio.put<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    _logger.d('📡 DELETE: $url');
    return _dio.delete<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }
}
