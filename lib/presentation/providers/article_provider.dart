// lib/presentation/providers/article_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/article_local_data_source.dart';
import '../../data/datasources/article_remote_data_source.dart';
import '../../data/repositories/article_repository_impl.dart';
import '../../domain/repositories/article_repository.dart';
import '../features/articles/notifiers/article_notifier.dart';
import '../features/articles/states/article_state.dart'; // Add this import

// Providers for dependencies
final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final remoteDataSourceProvider = Provider<ArticleRemoteDataSource>((ref) {
  return ArticleRemoteDataSourceImpl(ref.read(dioClientProvider));
});

final localDataSourceProvider = Provider<ArticleLocalDataSource>((ref) {
  return ArticleLocalDataSourceImpl();
});

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  return ArticleRepositoryImpl(
    remoteDataSource: ref.read(remoteDataSourceProvider),
    localDataSource: ref.read(localDataSourceProvider),
  );
});

// Main state provider
final articlesProvider = StateNotifierProvider<ArticleNotifier, ArticleState>(
  (ref) {
    return ArticleNotifier(
      repository: ref.read(articleRepositoryProvider),
    )..loadInitialArticles();
  },
);