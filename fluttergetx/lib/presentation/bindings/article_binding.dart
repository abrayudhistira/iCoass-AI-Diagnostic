import 'package:get/get.dart';
import 'package:fluttergetx/presentation/controllers/article_controller.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';
import 'package:dio/dio.dart';
import 'package:fluttergetx/data/repositories/article_repository_impl.dart';

class ArticleBinding extends Bindings {
  @override
  void dependencies() {
    // Register the repository implementation first
    Get.lazyPut<ArticleRepository>(() => ArticleRepositoryImpl(Get.find<Dio>()));
    // Then register the controller using the repository
    Get.lazyPut<ArticleController>(() => ArticleController(
      repository: Get.find<ArticleRepository>(),
    ));
  }
}
