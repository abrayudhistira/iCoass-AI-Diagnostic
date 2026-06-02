import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';
import 'package:fluttergetx/domain/repositories/diagnosis_repository.dart';

/// Implementasi repository untuk modul diagnosa menggunakan Dio.
/// Disinkronkan dengan DiagnosisEntity dan DiagnosisDetail sesuai struktur skripsi.
class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final Dio _dio;
  final _secureStorage = const FlutterSecureStorage();
  final String _baseUrl = dotenv.env['API_URL'] ?? '';

  DiagnosisRepositoryImpl(this._dio);

  Future<Options> _getOptions() async {
    String? token = await _secureStorage.read(key: 'access_token');
    return Options(headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
      "Content-Type": "application/json",
    });
  }

  @override
  Future<DiagnosisResult> fetchDiagnosis(List<String> symptomCodes) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/diagnosis',
        data: {"symptoms": symptomCodes},
        options: await _getOptions(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        return _mapToEntity(data);
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
        '$_baseUrl/diagnosis/history',
        options: await _getOptions(),
      );

      if (response.data != null && response.data['success'] == true) {
        final List rawList = response.data['data'] ?? [];
        return rawList.map((item) => _mapToEntity(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🚨 [REPOSITORY ERROR] $e');
      throw Exception('Gagal memuat riwayat: $e');
    }
  }

  /// Helper untuk memetakan JSON ke Entity.
  /// Memperbaiki error: named parameter 'penyakit', 'historyId', 'createdAt' tidak ditemukan.
  /// Memperbaiki error: argument type 'double' can't be assigned to 'String'.
  DiagnosisResult _mapToEntity(Map<String, dynamic> item) {
    
    // 1. Parsing Diagnosis Details (Stringified JSON handling)
    List<DiagnosisDetail> details = [];
    try {
      dynamic rawDetails = item['diagnosis_details'];
      List<dynamic> decodedDetails = [];
      
      if (rawDetails != null) {
        if (rawDetails is String) {
          decodedDetails = jsonDecode(rawDetails);
        } else {
          decodedDetails = rawDetails;
        }

        details = decodedDetails.map((d) {
          // Menyesuaikan dengan DiagnosisDetail Entity:
          // Parameter harus 'diseaseName' dan 'probability' (bukan penyakit/probabilitas)
          // Dan nilainya harus String (ditambah .toString())
          return DiagnosisDetail(
            diseaseName: d['penyakit']?.toString() ?? 'N/A',
            probability: d['probabilitas']?.toString() ?? d['confidence']?.toString() ?? '0',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [MAPPER WARNING] Gagal parsing details: $e');
    }

    // 2. Return DiagnosisResult Entity
    // Menyesuaikan parameter: mainDiagnosis, confidence, details.
    // Menghapus historyId dan createdAt karena tidak ada di Entity yang Anda berikan.
    return DiagnosisResult(
      mainDiagnosis: item['main_diagnosis']?.toString() ?? 'Tidak ada diagnosa',
      confidence: (item['confidence_score'] ?? item['confidence'] ?? '0').toString(),
      details: details,
    );
  }
}