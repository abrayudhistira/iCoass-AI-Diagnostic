import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';

class DiagnosisBannerCard extends StatelessWidget {
  const DiagnosisBannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Kasih ruang ekstra di atas card supaya maskot yang "nempel" ke atas
      // tidak kepotong sama widget sebelumnya (header)
      padding: const EdgeInsets.only(top: 30),
      child: Stack(
        clipBehavior: Clip.none, // WAJIB: biar child boleh keluar dari batas Stack
        children: [
          // Card utama
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.toNamed('/diagnosis-history'),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  // Ruang kanan dikasih lebih besar biar teks tidak ketiban maskot
                  padding: const EdgeInsets.fromLTRB(20, 24, 130, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // <-- FIX overflow: tinggi ikut konten
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yakin Gigi dan\nMulut Anda Sehat?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Yuk diagnosis sementara dari\nkeluhan-keluhanmu!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        child: const Text(
                          'Diagnosa Sekarang!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Maskot dokter — nongol ke atas, menempel keluar dari card
          Positioned(
            top: -30, // nilai negatif = keluar dari batas atas card
            right: 4,
            child: Image.asset(
              'assets/images/maskot.png',
              height: 210,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}