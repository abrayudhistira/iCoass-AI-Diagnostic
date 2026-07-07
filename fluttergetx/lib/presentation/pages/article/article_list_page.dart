import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/presentation/controllers/article_controller.dart';
import 'package:fluttergetx/presentation/pages/article/admin_article_page.dart';
import 'package:fluttergetx/presentation/pages/widget/article/article_card.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/chat_skeleton_card.dart';
import 'package:get/get.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:lottie/lottie.dart';

class ArticleListPage extends GetView<ArticleController> {
  const ArticleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.articles.isEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 5,
                  itemBuilder: (_, __) =>
                      const ChatSkeletonCard(), // Gunakan skeleton chat untuk konsistensi
                );
              }

              if (controller.articles.isEmpty) {
                return _buildEmptyState();
              }

              return _buildArticleList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Artikel Edukasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Informasi kesehatan gigi & mulut',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  if (controller.isAdmin)
                    Material(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await Get.to(() => const AdminArticlePage());

                          controller.fetchAll();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleList() {
    return CustomRefreshIndicator(
      onRefresh: () => controller.fetchAll(),
      builder: (context, child, indicatorController) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            if (!indicatorController.isIdle)
              Positioned(
                top: 25.0 * indicatorController.value,
                child: SizedBox(
                  height: 60,
                  child: Lottie.asset('assets/lottie/loading_animation.json'),
                ),
              ),
            Transform.translate(
              offset: Offset(0, 80.0 * indicatorController.value),
              child: child,
            ),
          ],
        );
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: controller.articles.length,
        itemBuilder: (context, index) {
          final article = controller.articles[index];
          return ArticleCard(
            article: article,
            onTap: () {
              // Mengirimkan ID sebagai argumen String untuk mencegah error null-check di router
              // Jika rute di main.dart menggunakan Get.arguments.id, ganti baris ini
              // atau pastikan rute tersebut menangani null dengan aman.
              final String articleId = article.id.toString();
              Get.toNamed('/article-detail', arguments: articleId);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie/loading_animation.json', width: 150),
          const Text(
            'Belum ada artikel tersedia',
            style: TextStyle(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
