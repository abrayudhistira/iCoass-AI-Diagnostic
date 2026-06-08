class Symptom {
  final String code;
  final String name;

  Symptom({required this.code, required this.name});
}

class DiagnosisResult {
  final String mainDiagnosis;
  final String confidence;
  final List<DiagnosisDetail> details;
  final List<String> symptomCodes;
  final String? explanation;

  DiagnosisResult({
    required this.mainDiagnosis,
    required this.confidence,
    required this.details,
    this.symptomCodes = const [],
    this.explanation,
  });

  /// CopyWith helper to easily update fields like explanation
  DiagnosisResult copyWith({
    String? mainDiagnosis,
    String? confidence,
    List<DiagnosisDetail>? details,
    List<String>? symptomCodes,
    String? explanation,
  }) {
    return DiagnosisResult(
      mainDiagnosis: mainDiagnosis ?? this.mainDiagnosis,
      confidence: confidence ?? this.confidence,
      details: details ?? this.details,
      symptomCodes: symptomCodes ?? this.symptomCodes,
      explanation: explanation ?? this.explanation,
    );
  }
}

class DiagnosisDetail {
  final String diseaseName;
  final String probability;

  DiagnosisDetail({required this.diseaseName, required this.probability});
}
