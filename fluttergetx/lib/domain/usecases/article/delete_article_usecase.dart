import 'package:fluttergetx/domain/repositories/article_repository.dart';

class DeleteArticleUseCase {
  final ArticleRepository repository;

  DeleteArticleUseCase(this.repository);

  Future<void> call(String id) {
    return repository.delete(id);
  }
}