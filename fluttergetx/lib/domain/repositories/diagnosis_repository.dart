import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import '../entities/diagnosis_entity.dart';

abstract class DiagnosisRepository {
  Future<Either<Failure, DiagnosisResult>> fetchDiagnosis(List<String> symptomCodes);
  Future<Either<Failure, List<DiagnosisResult>>> fetchHistory();
}
