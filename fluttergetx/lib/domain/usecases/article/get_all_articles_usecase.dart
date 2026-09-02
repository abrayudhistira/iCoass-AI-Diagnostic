import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';

class GetAllArticlesUseCase {
  final ArticleRepository repository;

  GetAllArticlesUseCase(this.repository);

  Future<Either<Failure, List<ArticleEntity>>> call({int page = 1, int limit = 10}) {
    return repository.getAll(page: page, limit: limit);
  }
}