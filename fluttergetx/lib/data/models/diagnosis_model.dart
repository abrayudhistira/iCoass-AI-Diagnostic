import 'dart:convert'; // Import for jsonDecode
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';


class DiagnosisResultModel extends DiagnosisResult {
  DiagnosisResultModel({
    required super.mainDiagnosis,
    required super.confidence,
    required super.details,
    super.symptomCodes = const [], // Add symptomCodes to constructor
  });

  factory DiagnosisResultModel.fromJson(Map<String, dynamic> json) {
    List<DiagnosisDetail> details = [];
    try {
      dynamic rawDetails = json['diagnosis_details'] ?? json['details'];
      List<dynamic> decodedDetails = [];

      if (rawDetails != null) {
        if (rawDetails is String) {
          decodedDetails = jsonDecode(rawDetails);
        } else {
          decodedDetails = rawDetails;
        }

        details = decodedDetails.map((d) => DiagnosisDetailModel.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [MODEL WARNING] Gagal parsing details: $e');
    }

    List<String> symptomCodes = [];
    try {
      final rawSymptomLog = json['symptom_log'];
      if (rawSymptomLog != null) {
        final rawSymptomList = rawSymptomLog['selected_symptoms'];
        if (rawSymptomList != null) {
          if (rawSymptomList is String) {
            final decoded = jsonDecode(rawSymptomList);
            if (decoded is List) {
              symptomCodes = decoded.map((e) => e.toString()).toList();
            }
          } else if (rawSymptomList is List) {
            symptomCodes = rawSymptomList.map((e) => e.toString()).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MODEL WARNING] Gagal parsing selected_symptoms: $e');
    }

    return DiagnosisResultModel(
      mainDiagnosis: json['main_diagnosis']?.toString() ?? 'Tidak ada diagnosa',
      confidence: (json['confidence_score'] ?? json['confidence'] ?? '0').toString(),
      details: details,
      symptomCodes: symptomCodes,
    );
  }
}

class DiagnosisDetailModel extends DiagnosisDetail {
  DiagnosisDetailModel({required super.diseaseName, required super.probability});

  factory DiagnosisDetailModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisDetailModel(
      diseaseName: json['penyakit']?.toString() ?? json['diseaseName']?.toString() ?? 'N/A',
      probability: json['probabilitas']?.toString() ?? json['confidence']?.toString() ?? json['probability']?.toString() ?? '0',
    );
  }
}
