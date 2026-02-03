// lib/presentation/features/articles/screens/articles_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:news_app/core/constants/strings.dart';
import 'package:news_app/core/utils/date_formatter.dart';
import 'package:news_app/presentation/providers/article_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../domain/entities/article.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/error_widget.dart';
import '../states/article_state.dart';
import '../../article_detail/screens/article_detail_screen.dart';

class ArticlesScreen extends ConsumerStatefulWidget {
  const ArticlesScreen({super.key});

  @override
  ConsumerState<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends ConsumerState<ArticlesScreen> {
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      ref.read(articlesProvider.notifier).loadMoreArticles();
    }
  }

  void _onRefresh() async {
    await ref.read(articlesProvider.notifier).refreshArticles();
    _refreshController.refreshCompleted();
  }

  void _navigateToDetail(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articlesProvider);

    return Scaffold(backgroundColor: Colors.grey[50], body: _buildBody(state));
  }

  Widget _buildBody(ArticleState state) {
    if (state.isLoading && state.articles.isEmpty) {
      // Initial loading
      return const ArticleShimmer();
    } else if (state.hasError) {
      // Error state
      if (state.cachedArticles != null && state.cachedArticles!.isNotEmpty) {
        return _buildContentWithError(state);
      } else {
        return ErrorRetryWidget(
          message: state.errorMessage ?? 'An error occurred',
          isOffline: state.isOffline,
          onRetry: () =>
              ref.read(articlesProvider.notifier).loadInitialArticles(),
        );
      }
    } else if (state.articles.isEmpty && state.errorMessage != null) {
      // Empty state
      return _buildEmptyState(state.errorMessage!);
    } else {
      // Loaded state
      return _buildContent(state);
    }
  }

  Widget _buildContent(ArticleState state) {
    final carouselArticles = state.articles.take(10).toList();
    final listArticles = state.articles.skip(10).toList();

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      header: WaterDropHeader(
        waterDropColor: Theme.of(context).primaryColor,
        complete: Icon(
          Icons.check_circle,
          color: Theme.of(context).primaryColor,
        ),
      ),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            title: Text(
              AppStrings.appTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
            expandedHeight: 60,
            floating: true,
            pinned: true,
            elevation: 4,
            backgroundColor: Theme.of(context).primaryColor,
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.warning,
                    text:
                        'This feature is currently not available. It will be launched soon, and you’ll be able to use it shortly. Please stay tuned.',
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.warning,
                    text:
                        'This feature is currently not available. It will be launched soon, and you’ll be able to use it shortly. Please stay tuned.',
                  );
                },
              ),
            ],
          ),

          // Offline Banner
          if (state.isOffline)
            SliverToBoxAdapter(child: _buildOfflineBanner(state.lastCacheTime)),

          // Featured News Carousel
          if (carouselArticles.isNotEmpty)
            SliverToBoxAdapter(child: _buildCarouselSection(carouselArticles)),

          // Recent News Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent News',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${state.articles.length} articles',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),

          // News List
          if (listArticles.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < listArticles.length) {
                    return _buildNewsCard(listArticles[index]);
                  } else if (!state.hasReachedMax && state.isLoadingMore) {
                    return _buildLoadingMoreIndicator();
                  } else {
                    return _buildEndOfList();
                  }
                },
                childCount:
                    listArticles.length +
                    (!state.hasReachedMax && state.isLoadingMore ? 1 : 0) +
                    1,
              ),
            )
          else if (!state.hasReachedMax && state.isLoadingMore)
            SliverToBoxAdapter(child: _buildLoadingMoreIndicator()),
        ],
      ),
    );
  }

  Widget _buildCarouselSection(List<Article> articles) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        children: [
          // Carousel Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured News',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Theme.of(context).primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Top Stories',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Carousel
          CarouselSlider.builder(
            itemCount: articles.length,
            options: CarouselOptions(
              height: 220,
              autoPlay: true,
              enlargeCenterPage: true,
              enlargeFactor: 0.2,
              viewportFraction: 0.8,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              onPageChanged: (index, reason) {
                setState(() {
                  _carouselIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              return _buildCarouselItem(articles[index]);
            },
          ),
          const SizedBox(height: 16),

          // Carousel Indicator
          AnimatedSmoothIndicator(
            activeIndex: _carouselIndex,
            count: articles.length,
            effect: ExpandingDotsEffect(
              activeDotColor: Theme.of(context).primaryColor,
              dotColor: Colors.grey[300]!,
              dotHeight: 8,
              dotWidth: 8,
              spacing: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(Article article) {
    return GestureDetector(
      onTap: () => _navigateToDetail(article),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              CachedNetworkImage(
                imageUrl: article.urlToImage ?? '',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.article,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        article.source.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.grey[300],
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatPublishedAt(article.publishedAt),
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(Article article) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _navigateToDetail(article),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 140, // Fixed height to avoid unbounded constraints
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: article.urlToImage ?? '',
                    width: 120,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(width: 120, color: Colors.grey[200]),
                    errorWidget: (context, url, error) => Container(
                      width: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.article, color: Colors.grey),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Source
                        Text(
                          article.source.name.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Title
                        Flexible(
                          child: Text(
                            article.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        if (article.description != null)
                          Flexible(
                            child: Text(
                              article.description!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        const Spacer(),

                        // Footer
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey[500],
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatPublishedAt(
                                article.publishedAt,
                              ),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Read',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentWithError(ArticleState state) {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              AppStrings.appTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
            expandedHeight: 60,
            floating: true,
            pinned: true,
            elevation: 4,
            backgroundColor: Colors.orange,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildOfflineBanner(state.lastCacheTime),
                ErrorRetryWidget(
                  message: state.errorMessage ?? 'An error occurred',
                  isOffline: state.isOffline,
                  onRetry: () =>
                      ref.read(articlesProvider.notifier).loadInitialArticles(),
                ),
              ],
            ),
          ),
          if (state.cachedArticles != null && state.cachedArticles!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildNewsCard(state.cachedArticles![index]),
                childCount: state.cachedArticles!.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[100],
          ),
          child: Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.emptyTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () =>
              ref.read(articlesProvider.notifier).refreshArticles(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text(
            'Try Again',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner(DateTime? lastCacheTime) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[100]!, Colors.orange[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.wifi_off, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.offlineMessage,
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lastCacheTime != null)
                  Text(
                    '${AppStrings.lastUpdated}${DateFormatter.formatCacheTime(lastCacheTime)}',
                    style: TextStyle(color: Colors.orange[700], fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEndOfList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).primaryColor,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re all caught up!',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for more news',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
