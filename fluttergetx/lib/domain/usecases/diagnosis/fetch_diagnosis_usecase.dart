import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';
import 'package:fluttergetx/domain/repositories/diagnosis_repository.dart';

class FetchDiagnosisUseCase {
  final DiagnosisRepository repository;

  FetchDiagnosisUseCase(this.repository);

  Future<Either<Failure, DiagnosisResult>> call(List<String> symptomCodes) async {
    try {
      final result = await repository.fetchDiagnosis(symptomCodes);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}