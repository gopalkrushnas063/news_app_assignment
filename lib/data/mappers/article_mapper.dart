// lib/data/mappers/article_mapper.dart
import '../models/article_model.dart';
import '../../domain/entities/article.dart';

extension ArticleModelExtension on ArticleModel {
  Article toEntity() {
    return Article(
      source: Source(
        id: source.id,
        name: source.name,
      ),
      author: author,
      title: title,
      description: description,
      url: url,
      urlToImage: urlToImage,
      publishedAt: publishedAt,
      content: content,
    );
  }
}

extension ArticlesResponseModelExtension on ArticlesResponseModel {
  ArticlesResponse toEntity() {
    return ArticlesResponse(
      status: status,
      totalResults: totalResults,
      articles: articles.map((article) => article.toEntity()).toList(),
    );
  }
}

extension ArticleToModel on Article {
  ArticleModel toModel() {
    return ArticleModel(
      source: SourceModel(id: source.id, name: source.name),
      author: author,
      title: title,
      description: description,
      url: url,
      urlToImage: urlToImage,
      publishedAt: publishedAt,
      content: content,
    );
  }
}

extension ArticlesResponseToModel on ArticlesResponse {
  ArticlesResponseModel toModel() {
    return ArticlesResponseModel(
      status: status,
      totalResults: totalResults,
      articles: articles.map((article) => article.toModel()).toList(),
    );
  }
}