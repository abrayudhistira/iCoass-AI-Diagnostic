import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttergetx/presentation/controllers/article_controller.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';

class ArticleDetailPage extends StatefulWidget {
  final String articleId;
  const ArticleDetailPage({Key? key, required this.articleId}) : super(key: key);

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final ArticleController _controller = Get.find<ArticleController>();
  ArticleEntity? _article;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer data loading until after the first frame to avoid setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetail();
    });
  }

  Future<void> _loadDetail() async {
    try {
      await _controller.fetchDetail(widget.articleId);
      _article = _controller.selectedArticle.value;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Article Detail')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _article == null
                  ? const Center(child: Text('Article not found'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_article!.imageUrl != null)
                              Image.network(_article!.imageUrl != null && _article!.imageUrl!.startsWith('http') ? _article!.imageUrl! : '${dotenv.env['API_URL'] ?? ''}${_article!.imageUrl!}'),
                            const SizedBox(height: 12),
                            Text(
                              _article!.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _article!.createdAt.toLocal().toString(),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const Divider(height: 24),
                            Text(_article!.content),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
