import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';
import 'package:fluttergetx/domain/repositories/diagnosis_repository.dart';

class FetchDiagnosisHistoryUseCase {
  final DiagnosisRepository repository;

  FetchDiagnosisHistoryUseCase(this.repository);

  Future<Either<Failure, List<DiagnosisResult>>> call() async {
    try {
      final results = await repository.fetchHistory();
      return Right(results ?? []);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}