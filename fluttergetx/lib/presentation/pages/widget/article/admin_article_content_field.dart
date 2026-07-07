import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AdminArticleContentField extends StatelessWidget {
  final TextEditingController controller;

  const AdminArticleContentField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article, color: AppColors.textMain),
              const SizedBox(width: 8),
              const Text(
                'Isi Konten',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            maxLines: 12,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Tulis isi artikel di sini...',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Isi artikel wajib diisi';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}