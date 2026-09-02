import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';

class DeleteArticleUseCase {
  final ArticleRepository repository;

  DeleteArticleUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.delete(id);
  }
}