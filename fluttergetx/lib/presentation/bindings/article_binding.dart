import 'package:get/get.dart';
import 'package:fluttergetx/data/repositories/article_repository_impl.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';
import 'package:fluttergetx/domain/usecases/article/get_all_articles_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/get_article_detail_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/create_article_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/update_article_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/delete_article_usecase.dart';
import 'package:fluttergetx/presentation/controllers/article_controller.dart';

class ArticleBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Repository
    Get.lazyPut<ArticleRepository>(() => ArticleRepositoryImpl(Get.find()));

    // 2. UseCases
    Get.lazyPut(() => GetAllArticlesUseCase(Get.find<ArticleRepository>()));
    Get.lazyPut(() => GetArticleDetailUseCase(Get.find<ArticleRepository>()));
    Get.lazyPut(() => CreateArticleUseCase(Get.find<ArticleRepository>()));
    Get.lazyPut(() => UpdateArticleUseCase(Get.find<ArticleRepository>()));
    Get.lazyPut(() => DeleteArticleUseCase(Get.find<ArticleRepository>()));

    // 3. Controller with injected UseCases
    Get.lazyPut<ArticleController>(
      () => ArticleController(
        getAllArticles: Get.find<GetAllArticlesUseCase>(),
        getArticleDetail: Get.find<GetArticleDetailUseCase>(),
        createArticleUseCase: Get.find<CreateArticleUseCase>(),
        updateArticleUseCase: Get.find<UpdateArticleUseCase>(),
        deleteArticleUseCase: Get.find<DeleteArticleUseCase>(),
      ),
    );
  }
}