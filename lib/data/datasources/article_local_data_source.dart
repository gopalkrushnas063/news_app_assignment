// lib/data/datasources/article_local_data_source.dart
import 'package:hive/hive.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../models/article_model.dart';

abstract class ArticleLocalDataSource {
  Future<void> cacheArticles(ArticlesResponseModel response);
  Future<ArticlesResponseModel?> getCachedArticles();
  Future<DateTime?> getLastCacheTime();
  Future<void> clearCache();
}

class ArticleLocalDataSourceImpl implements ArticleLocalDataSource {
  static const String _articlesBox = 'articles_box';
  Box? _box;

  Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_articlesBox);
    }
    return _box!;
  }

  @override
  Future<void> cacheArticles(ArticlesResponseModel response) async {
    try {
      final box = await _getBox();
      await box.put('cached_articles', response.toJson());
      await box.put('last_cache_time', DateTime.now().toIso8601String());
    } catch (e) {
      throw CacheException('Failed to cache articles: $e');
    }
  }

  @override
  Future<ArticlesResponseModel?> getCachedArticles() async {
    try {
      final box = await _getBox();
      final data = box.get('cached_articles');

      if (data != null) {
        return ArticlesResponseModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to retrieve cached articles: $e');
    }
  }

  @override
  Future<DateTime?> getLastCacheTime() async {
    try {
      final box = await _getBox();
      final timeString = box.get('last_cache_time');

      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to get cache time: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
}