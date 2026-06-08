import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../../data/services/gemini_service.dart';
import '../../core/constants/symptoms.dart';

/// [DiagnosisController] mengelola state untuk daftar gejala, hasil diagnosa,
/// dan riwayat pemeriksaan menggunakan GetX.
/// Dilengkapi dengan logging verbose untuk kebutuhan evaluasi performa sistem.
class DiagnosisController extends GetxController {
  final DiagnosisRepository repository;
  DiagnosisController({required this.repository});

  var isLoading = false.obs;
  var historyList = <DiagnosisResult>[].obs;
  var selectedSymptoms = <String>[].obs;
  var currentResult = Rxn<DiagnosisResult>();
  final RxString searchQuery = ''.obs;

  final GeminiService _geminiService = GeminiService();
  final RxMap<String, String> explanations = <String, String>{}.obs;

  /// Mendapatkan penjelasan penyakit secara dinamis dari Gemini API (menggunakan cache jika sudah pernah diload)
  Future<String> getExplanation(DiagnosisResult result) async {
    final cacheKey = '${result.mainDiagnosis}_${result.symptomCodes.join(',')}';
    if (explanations.containsKey(cacheKey)) {
      return explanations[cacheKey]!;
    }

    try {
      final symptomNames = getSymptomNames(result.symptomCodes);
      final explanation = await _geminiService.fetchExplanation(
        diseaseName: result.mainDiagnosis,
        symptomNames: symptomNames,
      );
      explanations[cacheKey] = explanation;
      return explanation;
    } catch (e) {
      debugPrint('Error getExplanation: $e');
      return 'Gagal memuat penjelasan dari AI.';
    }
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('⚙️ [DEBUG: INIT] DiagnosisController diinisialisasi.');
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('🚀 [DEBUG: READY] Widget terpasang, memulai fetch history.');
    fetchHistory();
  }

  /// Mengambil riwayat diagnosa dari repository dengan logging transparan.
  Future<void> fetchHistory() async {
    try {
      isLoading.value = true;
      debugPrint('📡 [DEBUG: FETCH] Memanggil repository.fetchHistory()...');

      final results = await repository.fetchHistory();

      if (results != null) {
        debugPrint(
          '📊 [DEBUG: DATA] Berhasil memuat ${results.length} record riwayat.',
        );
        historyList.assignAll(results);

        if (results.isNotEmpty) {
          debugPrint(
            '🔍 [DEBUG: SAMPLE] Data terakhir: ${results.first.mainDiagnosis} (${results.first.confidence}%)',
          );
        }
      } else {
        debugPrint('⚠️ [DEBUG: DATA] Repository mengembalikan null.');
      }
    } catch (e) {
      debugPrint('❌ [DEBUG: ERROR] Gagal fetch history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengeksekusi proses diagnosa berdasarkan gejala yang dipilih.
  /// Sangat krusial untuk memantau performa algoritma Naive Bayes di sini.
  Future<void> performDiagnosis() async {
    if (selectedSymptoms.isEmpty) {
      debugPrint('⚠️ [DEBUG: VALIDASI] Gejala kosong, diagnosa dibatalkan.');
      Get.snackbar("Peringatan", "Pilih minimal satu gejala");
      return;
    }

    try {
      isLoading.value = true;
      debugPrint('🧬 [DEBUG: NAIVE BAYES] Memproses gejala: $selectedSymptoms');

      final result = await repository.fetchDiagnosis(selectedSymptoms);

      debugPrint(
        '🤖 [DEBUG: GEMINI] Mengambil penjelasan penyakit dari Gemini...',
      );
      final symptomNames = getSymptomNames(selectedSymptoms);
      final explanation = await _geminiService.fetchExplanation(
        diseaseName: result.mainDiagnosis,
        symptomNames: symptomNames,
      );

      final finalResult = result.copyWith(explanation: explanation);
      currentResult.value = finalResult;

      debugPrint('🎯 [DEBUG: HASIL] Diagnosa: ${finalResult.mainDiagnosis}');
      debugPrint('📈 [DEBUG: CONFIDENCE] Skor: ${finalResult.confidence}%');

      // Simpan penjelasan ke cache
      final cacheKey =
          '${finalResult.mainDiagnosis}_${finalResult.symptomCodes.join(',')}';
      explanations[cacheKey] = explanation;

      // Refresh riwayat setelah diagnosa baru berhasil disimpan
      debugPrint('🔄 [DEBUG: SYNC] Sinkronisasi ulang riwayat...');
      fetchHistory();

      _showResultDialog(finalResult);
    } catch (e) {
      debugPrint('❌ [DEBUG: ERROR DIAGNOSA] $e');
      Get.snackbar("Gagal Diagnosa", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Menambah atau menghapus gejala dari daftar pilihan.
  void toggleSymptom(String code) {
    if (selectedSymptoms.contains(code)) {
      selectedSymptoms.remove(code);
      debugPrint(
        '➖ [DEBUG: SYMPTOM] Menghapus: $code | Total: ${selectedSymptoms.length}',
      );
    } else {
      selectedSymptoms.add(code);
      debugPrint(
        '➕ [DEBUG: SYMPTOM] Menambahkan: $code | Total: ${selectedSymptoms.length}',
      );
    }
  }

  /// Menampilkan dialog hasil diagnosa kepada pengguna.
  void _showResultDialog(DiagnosisResult result) {
    Get.defaultDialog(
      title: "Hasil Diagnosa",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              result.mainDiagnosis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Tingkat Keyakinan: ${result.confidence}%",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (result.explanation != null &&
                result.explanation!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "Penjelasan Medis :",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.explanation!,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
      textConfirm: "OK",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blueGrey,
      onConfirm: () => Get.back(),
    );
  }

  void resetSymptoms() {
    selectedSymptoms.clear();
    searchQuery.value = '';
  }
}
