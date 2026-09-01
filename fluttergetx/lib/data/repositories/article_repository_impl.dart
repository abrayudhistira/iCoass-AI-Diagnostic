import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final Dio _dio;

  ArticleRepositoryImpl(this._dio);

  @override
  Future<List<ArticleEntity>> getAll({int page = 1, int limit = 10}) async {
    final response = await _dio.get(
      'articles',
      queryParameters: {'page': page, 'limit': limit},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = response.data as Map<String, dynamic>;
      final List<dynamic> list = body['data'] as List<dynamic>;
      return list.map((e) => ArticleEntity.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch articles: ${response.statusCode}');
  }

  @override
  Future<ArticleEntity> getDetail(String id) async {
    final response = await _dio.get('articles/$id');
    if (response.statusCode == 200) {
      return ArticleEntity.fromJson((response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch article detail: ${response.statusCode}');
  }

  @override
  Future<ArticleEntity> create(ArticleEntity article, {String? imagePath}) async {
    final formData = FormData.fromMap({
      'title': article.title,
      'content': article.content,
      if (imagePath != null && imagePath.isNotEmpty)
        'image': await MultipartFile.fromFile(imagePath, filename: imagePath.split(Platform.pathSeparator).last),
    });
    final response = await _dio.post('articles', data: formData);
    if (response.statusCode == 201) {
      return ArticleEntity.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create article: ${response.statusCode}');
  }

  @override
  Future<ArticleEntity> update(String id, ArticleEntity article, {String? imagePath}) async {
    final body = {
      'title': article.title,
      'content': article.content,
    };
    final response = await _dio.put('articles/$id', data: body);
    if (response.statusCode == 200) {
      return ArticleEntity.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to update article: ${response.statusCode}');
  }

  @override
  Future<void> delete(String id) async {
    final response = await _dio.delete('articles/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete article: ${response.statusCode}');
    }
  }
}
