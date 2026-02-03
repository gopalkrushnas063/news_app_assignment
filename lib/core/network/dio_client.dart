// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../exceptions/app_exceptions.dart';
import '../constants/app_constants.dart';

class DioClient {
  final Dio _dio;

  DioClient() : _dio = Dio() {
    final baseUrl = dotenv.get(AppConstants.baseUrlEnv, fallback: 'https://newsapi.org/v2');
    
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add API key to all requests
          options.queryParameters['apiKey'] = dotenv.get(
            AppConstants.apiKeyEnv,
            fallback: 'b9348276b6b5446388a19259d18f1e11',
          );
          return handler.next(options);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException error) {
    if (error.response != null) {
      return ServerException(
        'Server error: ${error.response?.statusCode}',
        error.response?.statusCode ?? 500,
      );
    }
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');
      case DioExceptionType.badCertificate:
        return NetworkException('Invalid certificate');
      case DioExceptionType.badResponse:
        return ServerException(
          'Bad response from server',
          error.response?.statusCode ?? 500,
        );
      case DioExceptionType.cancel:
        return AppException('Request cancelled');
      default:
        return AppException('Network request failed');
    }
  }
}