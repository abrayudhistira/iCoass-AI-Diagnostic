import 'package:get/get.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/domain/usecases/article/get_all_articles_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/get_article_detail_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/create_article_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/update_article_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/delete_article_usecase.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';

import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/presentation/widgets/common_snackbar.dart';

class ArticleController extends GetxController {
  final GetAllArticlesUseCase getAllArticles;
  final GetArticleDetailUseCase getArticleDetail;
  final CreateArticleUseCase createArticleUseCase;
  final UpdateArticleUseCase updateArticleUseCase;
  final DeleteArticleUseCase deleteArticleUseCase;

  ArticleController({
    required this.getAllArticles,
    required this.getArticleDetail,
    required this.createArticleUseCase,
    required this.updateArticleUseCase,
    required this.deleteArticleUseCase,
  });

  final AuthController authController = Get.find<AuthController>();

  // Observable state
  var articles = <ArticleEntity>[].obs;
  var selectedArticle = Rxn<ArticleEntity>();
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  bool get isAdmin => authController.currentUser.value?.role == 'admin';

  /// Centralized failure handling with error code switching per backend spec
  String _handleFailure(Failure failure) {
    switch (failure.code) {
      case 'ERR_VALIDATION':
        if (failure is ValidationFailure && failure.field != null) {
          return '${failure.field}: ${failure.message}';
        }
        return failure.message;
      case 'ERR_UNAUTHORIZED':
        return 'Sesi kadaluwarsa, silakan login ulang';
      case 'ERR_FORBIDDEN':
        return 'Anda tidak memiliki akses untuk aksi ini';
      case 'ERR_NOT_FOUND':
        return failure.message;
      case 'ERR_CONFLICT':
        return failure.message;
      case 'ERR_INTERNAL':
        return 'Terjadi kesalahan server, coba lagi nanti';
      case 'CACHE_ERROR':
        return 'Gagal mengakses data lokal';
      case 'NETWORK_ERROR':
        return 'Tidak dapat terhubung ke server';
      case 'TIMEOUT_ERROR':
        return 'Koneksi timeout, coba lagi';
      default:
        return failure.message;
    }
  }

  // ------------------- Fetch -------------------
  Future<void> fetchAll({int page = 1, int limit = 10}) async {
    _setLoading(true);
    try {
      final result = await getAllArticles(page: page, limit: limit);
      result.fold(
        (failure) {
          errorMessage.value = _handleFailure(failure);
        },
        (data) {
          articles.assignAll(data);
        },
      );
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchDetail(String id) async {
    _setLoading(true);
    try {
      final result = await getArticleDetail(id);
      result.fold(
        (failure) {
          errorMessage.value = _handleFailure(failure);
        },
        (data) {
          selectedArticle.value = data;
        },
      );
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------- Create -------------------
  Future<void> createArticle(ArticleEntity article, {String? imagePath}) async {
    if (!isAdmin) return;
    _setLoading(true);
    try {
      // TokenInterceptor handles auth automatically
      final result = await createArticleUseCase(article, imagePath: imagePath);
      result.fold(
        (failure) {
          errorMessage.value = _handleFailure(failure);
          AppSnackbar.error(errorMessage.value, title: "Gagal Membuat Artikel");
        },
        (created) {
          articles.add(created);
          AppSnackbar.success('Artikel berhasil dibuat', title: "Sukses");
        },
      );
    } catch (e) {
      errorMessage.value = e.toString();
      AppSnackbar.error(errorMessage.value, title: "Gagal Membuat Artikel");
    } finally {
      _setLoading(false);
    }
  }

  // ------------------- Update -------------------
  Future<void> editArticle(String id, ArticleEntity article, {String? imagePath}) async {
    if (!isAdmin) return;
    _setLoading(true);
    try {
      // TokenInterceptor handles auth automatically
      final result = await updateArticleUseCase(id, article, imagePath: imagePath);
      result.fold(
        (failure) {
          errorMessage.value = _handleFailure(failure);
          AppSnackbar.error(errorMessage.value, title: "Gagal Memperbarui Artikel");
        },
        (updated) {
          // replace in list
          final index = articles.indexWhere((e) => e.id == updated.id);
          if (index != -1) articles[index] = updated;
          // also update selected if currently viewed
          if (selectedArticle.value?.id == updated.id) selectedArticle.value = updated;
          AppSnackbar.success('Artikel berhasil diperbarui', title: "Sukses");
        },
      );
    } catch (e) {
      errorMessage.value = e.toString();
      AppSnackbar.error(errorMessage.value, title: "Gagal Memperbarui Artikel");
    } finally {
      _setLoading(false);
    }
  }

  // ------------------- Delete -------------------
  Future<void> deleteArticle(String id) async {
    if (!isAdmin) return;
    _setLoading(true);
    try {
      // TokenInterceptor handles auth automatically
      final result = await deleteArticleUseCase(id);
      result.fold(
        (failure) {
          errorMessage.value = _handleFailure(failure);
          AppSnackbar.error(errorMessage.value, title: "Gagal Menghapus Artikel");
        },
        (_) {
          articles.removeWhere((e) => e.id == int.parse(id));
          if (selectedArticle.value?.id == int.parse(id)) selectedArticle.value = null;
          AppSnackbar.success('Artikel berhasil dihapus', title: "Sukses");
        },
      );
    } catch (e) {
      errorMessage.value = e.toString();
      AppSnackbar.error(errorMessage.value, title: "Gagal Menghapus Artikel");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) => isLoading.value = value;
}