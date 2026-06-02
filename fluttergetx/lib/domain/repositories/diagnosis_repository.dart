import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';

abstract class DiagnosisRepository {
  Future<DiagnosisResult> fetchDiagnosis(List<String> symptomCodes);
  Future<List<DiagnosisResult>> fetchHistory();
}