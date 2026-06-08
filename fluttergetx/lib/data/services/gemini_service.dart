import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service untuk berinteraksi dengan API Google Gemini untuk mendapatkan penjelasan penyakit.
class GeminiService {
  final Dio _dio = Dio();

  /// Mengambil penjelasan penyakit secara dinamis dari Gemini API berdasarkan nama penyakit dan gejalanya.
  Future<String> fetchExplanation({
    required String diseaseName,
    required List<String> symptomNames,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Kunci API Gemini tidak ditemukan. Harap tambahkan GEMINI_API_KEY ke file .env Anda.';
    }

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=$apiKey';

    String prompt;
    if (symptomNames.isNotEmpty) {
      prompt =
          'Berikan penjelasan medis singkat mengenai penyakit "$diseaseName" berdasarkan gejala-gejala berikut: ${symptomNames.join(', ')}. '
          'Ingat, berikan HANYA penjelasan medis tersebut secara ringkas (2-3 kalimat) yang mudah dipahami oleh pasien. '
          'JANGAN sertakan kalimat pembuka, penutup, salam, atau tanda format markdown tambahan. Jawab langsung pada inti penjelasannya.';
    } else {
      prompt =
          'Berikan penjelasan medis singkat mengenai penyakit "$diseaseName". '
          'Ingat, berikan HANYA penjelasan medis tersebut secara ringkas (2-3 kalimat) yang mudah dipahami oleh pasien. '
          'JANGAN sertakan kalimat pembuka, penutup, salam, atau tanda format markdown tambahan. Jawab langsung pada inti penjelasannya.';
    }

    try {
      final response = await _dio.post(
        url,
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        final text =
            response.data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String?;
        return text?.trim() ?? 'Gagal memuat penjelasan dari AI.';
      } else {
        return 'Gagal memuat penjelasan dari AI (Status: ${response.statusCode}).';
      }
    } catch (e) {
      debugPrint('🚨 [GEMINI SERVICE ERROR] $e');
      return 'Gagal menghubungkan ke AI Gemini untuk memuat penjelasan.';
    }
  }
}
