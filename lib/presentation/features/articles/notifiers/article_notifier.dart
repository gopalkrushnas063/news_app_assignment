// lib/presentation/features/articles/notifiers/article_notifier.dart
import 'package:flutter_riverpod/legacy.dart';
import '../../../../domain/repositories/article_repository.dart';
import '../states/article_state.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/strings.dart';

class ArticleNotifier extends StateNotifier<ArticleState> {
  final ArticleRepository _repository;
  final String _query = 'tesla';
  int _currentPage = 1;

  ArticleNotifier({
    required ArticleRepository repository,
  })  : _repository = repository,
        super(ArticleState.initial());

  Future<void> loadInitialArticles() async {
    try {
      state = ArticleState.loading();

      // Try to load fresh data
      final response = await _repository.getArticles(
        query: _query,
        page: 1,
        pageSize: AppConstants.pageSize,
        fromDate: DateTime(2026, 1, 3),
        sortBy: 'publishedAt',
      );

      if (response.articles.isEmpty) {
        state = ArticleState.empty(
          message: AppStrings.emptyMessage,
          isOffline: false,
        );
      } else {
        _currentPage = 1;
        final hasReachedMax = response.articles.length < AppConstants.pageSize;

        state = ArticleState.loaded(
          articles: response.articles,
          hasReachedMax: hasReachedMax,
          isOffline: false,
          lastCacheTime: DateTime.now(),
        );
      }
    } on NetworkException {
      // Network error, try to load from cache
      await _loadFromCache();
    } on AppException catch (e) {
      // Other errors, try cache first
      await _loadFromCache(errorMessage: e.message);
    } catch (e) {
      // Unexpected error
      state = ArticleState.error(
        message: 'An unexpected error occurred',
        isOffline: false,
      );
    }
  }

  Future<void> _loadFromCache({String? errorMessage}) async {
    try {
      final cached = await _repository.getCachedArticles();
      final lastCacheTime = await _repository.getLastCacheTime();

      if (cached != null && cached.articles.isNotEmpty) {
        state = ArticleState.loaded(
          articles: cached.articles,
          hasReachedMax: true,
          isOffline: true,
          lastCacheTime: lastCacheTime,
        );
      } else {
        state = ArticleState.error(
          message: errorMessage ?? 'No internet connection and no cached data',
          isOffline: true,
          cachedArticles: null,
          lastCacheTime: lastCacheTime,
        );
      }
    } catch (e) {
      state = ArticleState.error(
        message: errorMessage ?? 'Failed to load cached data',
        isOffline: true,
        cachedArticles: null,
        lastCacheTime: null,
      );
    }
  }

  Future<void> loadMoreArticles() async {
    if (state.hasReachedMax || state.isLoadingMore) return;

    try {
      state = state.copyWith(isLoadingMore: true);

      final nextPage = _currentPage + 1;
      final response = await _repository.getArticles(
        query: _query,
        page: nextPage,
        pageSize: AppConstants.pageSize,
        fromDate: DateTime(2026, 1, 3),
        sortBy: 'publishedAt',
      );

      if (response.articles.isEmpty) {
        state = state.copyWith(
          hasReachedMax: true,
          isLoadingMore: false,
        );
      } else {
        final updatedArticles = [...state.articles, ...response.articles];
        final hasReachedMax = response.articles.length < AppConstants.pageSize;
        _currentPage = nextPage;

        state = ArticleState.loaded(
          articles: updatedArticles,
          hasReachedMax: hasReachedMax,
          isOffline: false,
          lastCacheTime: state.lastCacheTime,
        );
      }
    } on NetworkException {
      state = state.copyWith(
        hasReachedMax: true,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refreshArticles() async {
    _currentPage = 1;
    await loadInitialArticles();
  }

  void clearError() {
    if (state.hasError) {
      if (state.cachedArticles != null) {
        state = ArticleState.loaded(
          articles: state.cachedArticles!,
          hasReachedMax: true,
          isOffline: true,
          lastCacheTime: state.lastCacheTime,
        );
      } else {
        state = ArticleState.initial();
      }
    }
  }
}