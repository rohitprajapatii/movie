import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:stage_movie/core/config/app_constants.dart';

class NetworkService {
  final Dio _dio;
  final Logger _logger = Logger();

  NetworkService() : _dio = Dio() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Add interceptors for logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  // GET request
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      // Add API key to all requests
      final Map<String, dynamic> params = {'api_key': AppConstants.apiKey};

      if (queryParameters != null) {
        params.addAll(queryParameters);
      }

      final response = await _dio.get(endpoint, queryParameters: params);
      return response;
    } catch (e) {
      _logger.e('GET request failed: $e');
      rethrow;
    }
  }

  // POST request
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      // Add API key to all requests
      final Map<String, dynamic> params = {'api_key': AppConstants.apiKey};

      if (queryParameters != null) {
        params.addAll(queryParameters);
      }

      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: params,
      );
      return response;
    } catch (e) {
      _logger.e('POST request failed: $e');
      rethrow;
    }
  }
}
