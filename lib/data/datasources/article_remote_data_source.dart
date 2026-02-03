// lib/data/datasources/article_remote_data_source.dart
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../models/article_model.dart';

abstract class ArticleRemoteDataSource {
  Future<ArticlesResponseModel> getArticles({
    required String query,
    required int page,
    required int pageSize,
    DateTime? fromDate,
    String? sortBy,
  });
}

class ArticleRemoteDataSourceImpl implements ArticleRemoteDataSource {
  final DioClient _dioClient;

  ArticleRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ArticlesResponseModel> getArticles({
    required String query,
    required int page,
    required int pageSize,
    DateTime? fromDate,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'page': page,
        'pageSize': pageSize,
      };

      // Add optional parameters if provided
      if (fromDate != null) {
        queryParams['from'] = fromDate.toIso8601String().split('T').first;
      }
      if (sortBy != null) {
        queryParams['sortBy'] = sortBy;
      }

      final response = await _dioClient.get(
        '/everything',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return ArticlesResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Failed to load articles: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          'Server error: ${e.response?.statusCode}',
          e.response?.statusCode ?? 500,
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      } else {
        throw AppException('Network request failed: ${e.message}');
      }
    } catch (e) {
      throw AppException('Failed to fetch articles: $e');
    }
  }
}