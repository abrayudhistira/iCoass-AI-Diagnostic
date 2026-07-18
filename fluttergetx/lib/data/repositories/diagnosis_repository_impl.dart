import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttergetx/data/models/diagnosis_model.dart'; // Import DiagnosisModel
import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';
import 'package:fluttergetx/domain/repositories/diagnosis_repository.dart';

/// Implementasi repository untuk modul diagnosa menggunakan Dio.
/// Disinkronkan dengan DiagnosisEntity dan DiagnosisDetail sesuai struktur skripsi.
class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final Dio _dio;

  DiagnosisRepositoryImpl(this._dio);

  @override
  Future<DiagnosisResult> fetchDiagnosis(List<String> symptomCodes) async {
    try {
      final response = await _dio.post(
        'diagnosis',
        data: {"symptoms": symptomCodes},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        return DiagnosisResultModel.fromJson(data).copyWith(symptomCodes: symptomCodes);
      } else {
        throw Exception('Gagal melakukan diagnosa');
      }
    } catch (e) {
      throw Exception('Kesalahan diagnosa: $e');
    }
  }

  @override
  Future<List<DiagnosisResult>> fetchHistory() async {
    try {
      debugPrint('📡 [DEBUG] Memanggil fetchHistory...');
      final response = await _dio.get(
        'diagnosis/history',
      );

      if (response.data != null && response.data['success'] == true) {
        final List rawList = response.data['data'] ?? [];
        return rawList.map((item) => DiagnosisResultModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🚨 [REPOSITORY ERROR] $e');
      throw Exception('Gagal memuat riwayat: $e');
    }
  }
}
