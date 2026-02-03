// lib/presentation/features/articles/states/article_state.dart
import 'package:flutter/foundation.dart';
import '../../../../domain/entities/article.dart';

@immutable
class ArticleState {
  final List<Article> articles;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasError;
  final bool hasReachedMax;
  final bool isOffline;
  final String? errorMessage;
  final DateTime? lastCacheTime;
  final List<Article>? cachedArticles;

  const ArticleState({
    this.articles = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasError = false,
    this.hasReachedMax = false,
    this.isOffline = false,
    this.errorMessage,
    this.lastCacheTime,
    this.cachedArticles,
  });

  ArticleState copyWith({
    List<Article>? articles,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasError,
    bool? hasReachedMax,
    bool? isOffline,
    String? errorMessage,
    DateTime? lastCacheTime,
    List<Article>? cachedArticles,
  }) {
    return ArticleState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage ?? this.errorMessage,
      lastCacheTime: lastCacheTime ?? this.lastCacheTime,
      cachedArticles: cachedArticles ?? this.cachedArticles,
    );
  }

  factory ArticleState.initial() => const ArticleState();
  
  factory ArticleState.loading() => const ArticleState(isLoading: true);
  
  factory ArticleState.loaded({
    required List<Article> articles,
    bool hasReachedMax = false,
    bool isOffline = false,
    DateTime? lastCacheTime,
  }) => ArticleState(
    articles: articles,
    hasReachedMax: hasReachedMax,
    isOffline: isOffline,
    lastCacheTime: lastCacheTime,
  );
  
  factory ArticleState.error({
    required String message,
    bool isOffline = false,
    List<Article>? cachedArticles,
    DateTime? lastCacheTime,
  }) => ArticleState(
    hasError: true,
    errorMessage: message,
    isOffline: isOffline,
    cachedArticles: cachedArticles,
    lastCacheTime: lastCacheTime,
  );
  
  factory ArticleState.empty({
    required String message,
    bool isOffline = false,
  }) => ArticleState(
    errorMessage: message,
    isOffline: isOffline,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ArticleState &&
        listEquals(other.articles, articles) &&
        other.isLoading == isLoading &&
        other.isLoadingMore == isLoadingMore &&
        other.hasError == hasError &&
        other.hasReachedMax == hasReachedMax &&
        other.isOffline == isOffline &&
        other.errorMessage == errorMessage &&
        other.lastCacheTime == lastCacheTime &&
        listEquals(other.cachedArticles, cachedArticles);
  }

  @override
  int get hashCode {
    return articles.hashCode ^
        isLoading.hashCode ^
        isLoadingMore.hashCode ^
        hasError.hashCode ^
        hasReachedMax.hashCode ^
        isOffline.hashCode ^
        errorMessage.hashCode ^
        lastCacheTime.hashCode ^
        cachedArticles.hashCode;
  }
}