import 'package:get/get.dart';
// Import Repository interface dan implementasinya
import 'package:fluttergetx/data/repositories/article_repository_impl.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';
// Pastikan path import ini sesuai dengan lokasi ArticleController Anda
import 'package:fluttergetx/presentation/controllers/article_controller.dart';

class ArticleBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Daftarkan Repository. Get.find() akan otomatis mengambil instance Dio yang ada di main.dart
    Get.lazyPut<ArticleRepository>(() => ArticleRepositoryImpl(Get.find()));

    // 2. Inisialisasi Controller dengan menyuntikkan repository yang sudah didaftarkan di atas
    Get.lazyPut<ArticleController>(
      () => ArticleController(repository: Get.find<ArticleRepository>()),
    );
  }
}