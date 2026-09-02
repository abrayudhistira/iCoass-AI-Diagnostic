import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/repositories/hospital_repository.dart';

class DeleteHospitalUseCase {
  final HospitalRepository repository;

  DeleteHospitalUseCase(this.repository);

  Future<Either<Failure, bool>> call(int id) {
    return repository.deleteHospital(id);
  }
}