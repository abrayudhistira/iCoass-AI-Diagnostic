import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:fluttergetx/presentation/controllers/article_controller.dart';
import 'package:fluttergetx/presentation/pages/article/admin_article_page.dart';
import 'package:fluttergetx/presentation/pages/article/article_detail_page.dart';

class ArticleListPage extends StatelessWidget {
  const ArticleListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ArticleController controller = Get.find<ArticleController>();
    // Fetch articles when the page is first built
    controller.fetchAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
        actions: [
          if (controller.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Get.to(() => const AdminArticlePage()),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.articles.isEmpty) {
          return const Center(child: Text('No articles found.'));
        }
        return RefreshIndicator(
          onRefresh: controller.fetchAll,
          child: ListView.builder(
            itemCount: controller.articles.length,
            itemBuilder: (context, index) {
              final article = controller.articles[index];
              return ListTile(
                leading: article.imageUrl != null
                    ? Image.network(
                        '${dotenv.env['API_URL']}${article.imageUrl}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.article),
                title: Text(article.title),
                subtitle: Text(article.createdAt.toLocal().toString()),
                onTap: () => Get.to(
                  () => ArticleDetailPage(articleId: article.id.toString()),
                ),
                trailing: controller.isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => Get.to(() => AdminArticlePage(article: article)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await controller.deleteArticle(article.id.toString());
                            },
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
        );
      }),
    );
  }
}
