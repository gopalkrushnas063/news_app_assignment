// lib/data/repositories/article_repository_impl.dart
import '../../domain/repositories/article_repository.dart';
import '../../domain/entities/article.dart';
import '../datasources/article_remote_data_source.dart';
import '../datasources/article_local_data_source.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../models/article_model.dart';
import '../mappers/article_mapper.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final ArticleRemoteDataSource _remoteDataSource;
  final ArticleLocalDataSource _localDataSource;

  ArticleRepositoryImpl({
    required ArticleRemoteDataSource remoteDataSource,
    required ArticleLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<ArticlesResponse> getArticles({
    required String query,
    required int page,
    required int pageSize,
    DateTime? fromDate,
    String? sortBy,
  }) async {
    try {
      // Get data from remote data source
      final response = await _remoteDataSource.getArticles(
        query: query,
        page: page,
        pageSize: pageSize,
        fromDate: fromDate,
        sortBy: sortBy,
      );

      // Cache successful response if it's the first page
      if (page == 1) {
        await cacheArticles(response.toEntity());
      }

      return response.toEntity();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Failed to fetch articles: $e');
    }
  }

  @override
  Future<void> cacheArticles(ArticlesResponse response) async {
    try {
      // Convert entity to model for caching
      final model = ArticlesResponseModel(
        status: response.status,
        totalResults: response.totalResults,
        articles: response.articles.map((article) {
          return ArticleModel(
            source: SourceModel(
              id: article.source.id,
              name: article.source.name,
            ),
            author: article.author,
            title: article.title,
            description: article.description,
            url: article.url,
            urlToImage: article.urlToImage,
            publishedAt: article.publishedAt,
            content: article.content,
          );
        }).toList(),
      );
      
      await _localDataSource.cacheArticles(model);
    } catch (e) {
      throw CacheException('Failed to cache articles: $e');
    }
  }

  @override
  Future<ArticlesResponse?> getCachedArticles() async {
    try {
      final cached = await _localDataSource.getCachedArticles();
      if (cached == null) return null;
      
      // Convert model to entity
      return ArticlesResponse(
        status: cached.status,
        totalResults: cached.totalResults,
        articles: cached.articles.map((articleModel) {
          return Article(
            source: Source(
              id: articleModel.source.id,
              name: articleModel.source.name,
            ),
            author: articleModel.author,
            title: articleModel.title,
            description: articleModel.description,
            url: articleModel.url,
            urlToImage: articleModel.urlToImage,
            publishedAt: articleModel.publishedAt,
            content: articleModel.content,
          );
        }).toList(),
      );
    } catch (e) {
      throw CacheException('Failed to get cached articles: $e');
    }
  }

  @override
  Future<DateTime?> getLastCacheTime() async {
    try {
      return await _localDataSource.getLastCacheTime();
    } catch (e) {
      throw CacheException('Failed to get cache time: $e');
    }
  }
}