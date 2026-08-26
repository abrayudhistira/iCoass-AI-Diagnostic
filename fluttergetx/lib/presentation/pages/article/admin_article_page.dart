import 'package:flutter/material.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_content_field.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_header.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_image_picker.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_submit_button.dart';
import 'package:fluttergetx/presentation/pages/widget/article/admin_article_title_field.dart';
import 'package:get/get.dart';
import 'package:fluttergetx/presentation/controllers/article_controller.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/presentation/widgets/common_snackbar.dart';


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
        await controller.editArticle(
          widget.article!.id.toString(),
          article,
          imagePath: _imagePath,
        );
      }

      await controller.fetchAll();

      AppSnackbar.success(
        widget.article == null
            ? 'Artikel berhasil dibuat'
            : 'Artikel berhasil diperbarui',
      );

      Get.back();
    } catch (e) {
      AppSnackbar.error('Gagal menyimpan artikel: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _updateImagePath(String? path) {
    setState(() => _imagePath = path);
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Artikel?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Artikel ini akan dihapus permanen dan tidak bisa dikembalikan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        final controller = Get.find<ArticleController>();
                        controller.deleteArticle(widget.article!.id.toString());
                        AppSnackbar.success('Artikel berhasil dihapus');
                        Get.back(); // Go back to article list
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
            onDelete: widget.article != null ? _showDeleteConfirmation : null,
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