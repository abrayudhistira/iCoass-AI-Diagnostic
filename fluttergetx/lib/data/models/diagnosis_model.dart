import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';


class DiagnosisResultModel extends DiagnosisResult {
  DiagnosisResultModel({
    required super.mainDiagnosis,
    required super.confidence,
    required super.details,
  });

  factory DiagnosisResultModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisResultModel(
      mainDiagnosis: json['main_diagnosis'] ?? 'N/A',
      confidence: json['confidence']?.toString() ?? '0%',
      details: (json['details'] as List? ?? [])
          .map((d) => DiagnosisDetailModel.fromJson(d))
          .toList(),
    );
  }
}

class DiagnosisDetailModel extends DiagnosisDetail {
  DiagnosisDetailModel({required super.diseaseName, required super.probability});

  factory DiagnosisDetailModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisDetailModel(
      diseaseName: json['penyakit'] ?? 'N/A',
      probability: json['probabilitas']?.toString() ?? '0',
    );
  }
}
