// lib/domain/entities/article.dart
class Article {
  final Source source;
  final String? author;
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final DateTime publishedAt;
  final String? content;

  Article({
    required this.source,
    required this.author,
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.content,
  });
}

class Source {
  final String? id;
  final String name;

  Source({required this.id, required this.name});
}

class ArticlesResponse {
  final String status;
  final int totalResults;
  final List<Article> articles;

  ArticlesResponse({
    required this.status,
    required this.totalResults,
    required this.articles,
  });
}