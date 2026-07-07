import 'package:flutter/material.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_content_field.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_header.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_image_picker.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_submit_button.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_title_field.dart';
import 'package:get/get.dart';
import 'package:fluttergetx/presentation/controllers/article_controller.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';


class AdminArticlePage extends StatefulWidget {
  final ArticleEntity? article;
  const AdminArticlePage({Key? key, this.article}) : super(key: key);

  @override
  State<AdminArticlePage> createState() => _AdminArticlePageState();
}

class _AdminArticlePageState extends State<AdminArticlePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _imagePath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      _titleController.text = widget.article!.title;
      _contentController.text = widget.article!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final controller = Get.find<ArticleController>();
      final article = ArticleEntity(
        id: widget.article?.id ?? 0,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.article == null) {
        await controller.createArticle(article, imagePath: _imagePath);
      } else {
        await controller.updateArticle(
          widget.article!.id.toString(),
          article,
          imagePath: _imagePath,
        );
      }

      await controller.fetchAll();

      Get.snackbar(
        'Sukses',
        widget.article == null
            ? 'Artikel berhasil dibuat'
            : 'Artikel berhasil diperbarui',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan artikel: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _updateImagePath(String? path) {
    setState(() => _imagePath = path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          AdminArticleHeader(
            isEditMode: widget.article != null,
            isSubmitting: _isSubmitting,
            onSubmit: _submit,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminArticleTitleField(controller: _titleController),
                      const SizedBox(height: 16),
                      AdminArticleContentField(controller: _contentController),
                      const SizedBox(height: 16),
                      AdminArticleImagePicker(
                        imagePath: _imagePath,
                        existingImageUrl: widget.article?.imageUrl,
                        onImageChanged: _updateImagePath,
                      ),
                      const SizedBox(height: 24),
                      AdminArticleSubmitButton(
                        isEditMode: widget.article != null,
                        isSubmitting: _isSubmitting,
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 100,)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}