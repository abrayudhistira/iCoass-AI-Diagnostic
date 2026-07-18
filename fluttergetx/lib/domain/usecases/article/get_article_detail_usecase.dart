import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';

class GetArticleDetailUseCase {
  final ArticleRepository repository;

  GetArticleDetailUseCase(this.repository);

  Future<ArticleEntity> call(String id) {
    return repository.getDetail(id);
  }
}