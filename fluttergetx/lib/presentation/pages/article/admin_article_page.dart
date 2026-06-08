import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttergetx/presentation/controllers/article_controller.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminArticlePage extends StatefulWidget {
  final ArticleEntity? article; // null -> create, else edit
  const AdminArticlePage({Key? key, this.article}) : super(key: key);

  @override
  State<AdminArticlePage> createState() => _AdminArticlePageState();
}

class _AdminArticlePageState extends State<AdminArticlePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      _titleController.text = widget.article!.title;
      _contentController.text = widget.article!.content;
      // For editing we allow picking a new image; existing image can be shown via network if needed.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _imagePath = file.path;
      });
    }
  }

  Future<void> _submit() async {
    final controller = Get.find<ArticleController>();
    final article = ArticleEntity(
      id: widget.article?.id ?? 0,
      title: _titleController.text,
      content: _contentController.text,
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
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article == null ? 'Create Article' : 'Edit Article'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image'),
              ),
              const SizedBox(height: 8),
              // Show selected local image or existing remote image
              if (_imagePath != null)
                Image.file(File(_imagePath!), height: 150)
              else if (widget.article?.imageUrl != null)
                Image.network(
                  '${dotenv.env['API_URL']}${widget.article!.imageUrl!}',
                  height: 150,
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.article == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
