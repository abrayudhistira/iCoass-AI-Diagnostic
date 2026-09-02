import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';

class UpdateArticleUseCase {
  final ArticleRepository repository;

  UpdateArticleUseCase(this.repository);

  Future<Either<Failure, ArticleEntity>> call(String id, ArticleEntity article, {String? imagePath}) {
    return repository.update(id, article, imagePath: imagePath);
  }
}