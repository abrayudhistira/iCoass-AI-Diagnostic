import 'dart:io';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';

/// Repository implementation for Article feature, matching the clean‑architecture style used in the project (similar to DiagnosisRepositoryImpl).
class ArticleRepositoryImpl implements ArticleRepository {
  final Dio _dio;
  final String _baseUrl = dotenv.env['API_URL'] ?? '';

  ArticleRepositoryImpl(this._dio);

  @override
  Future<List<ArticleEntity>> getAll({int page = 1, int limit = 10}) async {
    final uri = '$_baseUrl/articles?page=$page&limit=$limit';
    final response = await _dio.get(uri);
    if (response.statusCode == 200) {
      // The API wraps the list inside a 'data' field.
      final Map<String, dynamic> body = response.data as Map<String, dynamic>;
      final List<dynamic> list = body['data'] as List<dynamic>;
      return list.map((e) => ArticleEntity.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch articles: ${response.statusCode}');
  }

  @override
  Future<ArticleEntity> getDetail(String id) async {
    final uri = '$_baseUrl/articles/$id';
    final response = await _dio.get(uri);
    if (response.statusCode == 200) {
      return ArticleEntity.fromJson((response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch article detail: ${response.statusCode}');
  }

  @override
  Future<ArticleEntity> create(ArticleEntity article, {String? imagePath}) async {
    final uri = '$_baseUrl/articles';
    final formData = FormData.fromMap({
      'title': article.title,
      'content': article.content,
      if (imagePath != null && imagePath.isNotEmpty) 'image': await MultipartFile.fromFile(imagePath, filename: imagePath.split(Platform.pathSeparator).last),
    });
    final response = await _dio.post(uri, data: formData);
    if (response.statusCode == 201) {
      return ArticleEntity.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create article: ${response.statusCode}');
  }

  @override
  Future<ArticleEntity> update(String id, ArticleEntity article, {String? imagePath}) async {
    final uri = '$_baseUrl/articles/$id';
    // API spec uses JSON for update; ignore imagePath for simplicity.
    final body = {
      'title': article.title,
      'content': article.content,
    };
    final response = await _dio.put(uri, data: body);
    if (response.statusCode == 200) {
      return ArticleEntity.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Failed to update article: ${response.statusCode}');
  }

  @override
  Future<void> delete(String id) async {
    final uri = '$_baseUrl/articles/$id';
    final response = await _dio.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete article: ${response.statusCode}');
    }
  }
}
