import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';
import 'package:fluttergetx/domain/repositories/diagnosis_repository.dart';

class FetchDiagnosisUseCase {
  final DiagnosisRepository repository;

  FetchDiagnosisUseCase(this.repository);

  Future<Either<Failure, DiagnosisResult>> call(List<String> symptomCodes) {
    return repository.fetchDiagnosis(symptomCodes);
  }
}