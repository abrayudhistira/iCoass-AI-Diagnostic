import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ArticleCard extends StatelessWidget {
  final dynamic article;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Mengambil baseUrl dari .env dan memastikan tidak ada trailing slash untuk konsistensi
    final String rawBaseUrl = dotenv.env['API_URL'] ?? '';
    final String baseUrl = rawBaseUrl.endsWith('/') 
        ? rawBaseUrl.substring(0, rawBaseUrl.length - 1) 
        : rawBaseUrl;

    // Helper untuk mengambil data secara aman baik dari Model maupun Map
    String imagePath = '';
    String title = '';
    dynamic id;
    dynamic rawDate;

    try {
      imagePath = article.imageUrl ?? '';
      title = article.title ?? '';
      id = article.id;
      rawDate = article.createdAt;
    } catch (_) {
      try {
        imagePath = article['image_url'] ?? '';
        title = article['title'] ?? '';
        id = article['id'];
        rawDate = article['createdAt'];
      } catch (_) {
        imagePath = '';
        title = 'Tanpa Judul';
        id = DateTime.now().millisecondsSinceEpoch;
      }
    }

    // Memastikan imagePath tidak memiliki leading slash untuk menghindari double slash saat digabungkan
    imagePath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    final String finalImageUrl = imagePath.isNotEmpty
        ? "$baseUrl/$imagePath"
        : 'https://via.placeholder.com/150';
    
    // Format tanggal
    // Perbaikan: Cek tipe data createdAt. Jika sudah DateTime, langsung format. 
    final String date = rawDate != null 
        ? DateFormat('dd MMM yyyy', 'id_ID').format(
            rawDate is String ? DateTime.parse(rawDate) : rawDate
          )
        : '-';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Gambar Artikel (Analog dengan Avatar Chat) ──────────────────
            Hero(
              tag: 'art-$id',
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.background,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    finalImageUrl,
                    fit: BoxFit.cover,
                    // Menangani error 404 atau kesalahan jaringan lainnya
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: Colors.grey,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // ── Konten Teks ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Baca selengkapnya...",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}