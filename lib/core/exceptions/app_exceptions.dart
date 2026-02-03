// lib/core/exceptions/app_exceptions.dart
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

class NetworkException extends AppException {
  NetworkException(String message, {String? code})
      : super(message, code: code);
}

class CacheException extends AppException {
  CacheException(String message, {String? code})
      : super(message, code: code);
}

class ServerException extends AppException {
  final int statusCode;

  ServerException(String message, this.statusCode, {String? code})
      : super(message, code: code);
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message);
}