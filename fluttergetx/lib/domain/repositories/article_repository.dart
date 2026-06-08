import 'package:fluttergetx/domain/entities/article_entity.dart';

abstract class ArticleRepository {
  Future<List<ArticleEntity>> getAll({int page, int limit});
  Future<ArticleEntity> getDetail(String id);
  Future<ArticleEntity> create(ArticleEntity article, {String? imagePath});
  Future<ArticleEntity> update(
    String id,
    ArticleEntity article, {
    String? imagePath,
  });
  Future<void> delete(String id);
}
