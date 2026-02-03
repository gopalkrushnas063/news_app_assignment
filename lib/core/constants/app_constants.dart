// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'News Reader';
  static const String apiKeyEnv = 'NEWS_API_KEY';
  static const String baseUrlEnv = 'NEWS_API_BASE_URL';
  static const int pageSize = 20;
  static const Duration cacheDuration = Duration(hours: 1);
  static const int maxRetryAttempts = 3;
}

