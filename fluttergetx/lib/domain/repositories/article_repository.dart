import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import '../entities/article_entity.dart';

abstract class ArticleRepository {
  Future<Either<Failure, List<ArticleEntity>>> getAll({int page, int limit});
  Future<Either<Failure, ArticleEntity>> getDetail(String id);
  Future<Either<Failure, ArticleEntity>> create(ArticleEntity article, {String? imagePath});
  Future<Either<Failure, ArticleEntity>> update(
    String id,
    ArticleEntity article, {
    String? imagePath,
  });
  Future<Either<Failure, void>> delete(String id);
}
