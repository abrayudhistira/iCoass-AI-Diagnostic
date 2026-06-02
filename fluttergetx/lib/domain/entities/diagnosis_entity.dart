class Symptom {
  final String code;
  final String name;

  Symptom({required this.code, required this.name});
}

class DiagnosisResult {
  final String mainDiagnosis;
  final String confidence;
  final List<DiagnosisDetail> details;

  DiagnosisResult({
    required this.mainDiagnosis,
    required this.confidence,
    required this.details,
  });
}

class DiagnosisDetail {
  final String diseaseName;
  final String probability;

  DiagnosisDetail({required this.diseaseName, required this.probability});
}