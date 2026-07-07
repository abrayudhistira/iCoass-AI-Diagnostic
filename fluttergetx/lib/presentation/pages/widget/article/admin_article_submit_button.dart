import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AdminArticleSubmitButton extends StatelessWidget {
  final bool isEditMode;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const AdminArticleSubmitButton({
    Key? key,
    required this.isEditMode,
    required this.isSubmitting,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isEditMode ? 'Perbarui Artikel' : 'Publish Artikel',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}