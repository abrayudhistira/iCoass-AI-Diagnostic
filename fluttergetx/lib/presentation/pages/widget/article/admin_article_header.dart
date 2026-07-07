import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';

class AdminArticleHeader extends StatelessWidget {
  final bool isEditMode;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const AdminArticleHeader({
    Key? key,
    required this.isEditMode,
    required this.isSubmitting,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditMode ? 'Edit Artikel' : 'Tambah Artikel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isEditMode
                          ? 'Perbarui artikel edukasi'
                          : 'Buat artikel edukasi baru',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // FilledButton.icon(
              //   style: FilledButton.styleFrom(
              //     backgroundColor: Colors.white,
              //     foregroundColor: AppColors.primary,
              //   ),
              //   onPressed: isSubmitting ? null : onSubmit,
              //   icon: isSubmitting
              //       ? const SizedBox(
              //           width: 16,
              //           height: 16,
              //           child: CircularProgressIndicator(
              //             strokeWidth: 2,
              //             color: AppColors.primary,
              //           ),
              //         )
              //       : const Icon(Icons.save),
              //   label: Text(isSubmitting ? 'Menyimpan...' : 'Simpan'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}