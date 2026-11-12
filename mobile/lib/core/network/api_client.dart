import 'package:dio/dio.dart';

import '../constants/api_config.dart';

/// A failed call to the backend, with a message fit to show to the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin wrapper around Dio: every request to the backend goes through here.
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              headers: {'accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<dynamic> delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final response = error.response;
    if (response != null) {
      // FastAPI reports errors as {"detail": "..."}.
      final data = response.data;
      final detail = data is Map ? data['detail'] : null;
      return ApiException(
        detail is String
            ? detail
            : 'The server returned an error (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiException(
        'The server took too long to respond. Please try again.',
      ),
      _ => ApiException(
        'Could not reach the server at ${_dio.options.baseUrl}. '
        'Check that the backend is running and the device is on the same network.',
      ),
    };
  }
}
