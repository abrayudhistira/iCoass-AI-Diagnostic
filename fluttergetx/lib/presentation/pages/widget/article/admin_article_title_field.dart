import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AdminArticleTitleField extends StatelessWidget {
  final TextEditingController controller;

  const AdminArticleTitleField({
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
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: "Judul Artikel",
          prefixIcon: Icon(Icons.title),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Judul artikel wajib diisi';
          }
          return null;
        },
      ),
    );
  }
}