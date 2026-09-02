import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';
import 'package:fluttergetx/domain/repositories/diagnosis_repository.dart';

class FetchDiagnosisHistoryUseCase {
  final DiagnosisRepository repository;

  FetchDiagnosisHistoryUseCase(this.repository);

  Future<Either<Failure, List<DiagnosisResult>>> call() {
    return repository.fetchHistory();
  }
}