import 'package:get/get.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/domain/usecases/article/get_all_articles_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/get_article_detail_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/create_article_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/update_article_usecase.dart';
import 'package:fluttergetx/domain/usecases/article/delete_article_usecase.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';

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

  // ------------------- Fetch -------------------
  Future<void> fetchAll({int page = 1, int limit = 10}) async {
    _setLoading(true);
    try {
      final result = await getAllArticles(page: page, limit: limit);
      articles.assignAll(result);
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
      selectedArticle.value = result;
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
      var token = await authController.getToken();
      if (token == null) {
        try {
          await authController.refreshAccessToken();
        } catch (_) {}
      }
      final created = await createArticleUseCase(article, imagePath: imagePath);
      articles.add(created);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------- Update -------------------
  Future<void> editArticle(String id, ArticleEntity article, {String? imagePath}) async {
    if (!isAdmin) return;
    _setLoading(true);
    try {
      var token = await authController.getToken();
      if (token == null) {
        try {
          await authController.refreshAccessToken();
        } catch (_) {}
      }
      final updated = await updateArticleUseCase(id, article, imagePath: imagePath);
      // replace in list
      final index = articles.indexWhere((e) => e.id == updated.id);
      if (index != -1) articles[index] = updated;
      // also update selected if currently viewed
      if (selectedArticle.value?.id == updated.id) selectedArticle.value = updated;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------- Delete -------------------
  Future<void> deleteArticle(String id) async {
    if (!isAdmin) return;
    _setLoading(true);
    try {
      await deleteArticleUseCase(id);
      articles.removeWhere((e) => e.id == int.parse(id));
      if (selectedArticle.value?.id == int.parse(id)) selectedArticle.value = null;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) => isLoading.value = value;
}