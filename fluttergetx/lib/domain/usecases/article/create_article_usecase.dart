import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';

class CreateArticleUseCase {
  final ArticleRepository repository;

  CreateArticleUseCase(this.repository);

  Future<Either<Failure, ArticleEntity>> call(ArticleEntity article, {String? imagePath}) {
    return repository.create(article, imagePath: imagePath);
  }
}