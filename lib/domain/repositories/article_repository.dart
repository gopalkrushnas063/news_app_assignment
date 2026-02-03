// lib/domain/repositories/article_repository.dart
import '../entities/article.dart';

abstract class ArticleRepository {
  Future<ArticlesResponse> getArticles({
    required String query,
    required int page,
    required int pageSize,
    DateTime? fromDate,
    String? sortBy,
  });

  Future<void> cacheArticles(ArticlesResponse response);
  Future<ArticlesResponse?> getCachedArticles();
  Future<DateTime?> getLastCacheTime();
}