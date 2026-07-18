import 'package:fluttergetx/domain/repositories/hospital_repository.dart';

class DeleteHospitalUseCase {
  final HospitalRepository repository;

  DeleteHospitalUseCase(this.repository);

  Future<bool> call(int id) {
    return repository.deleteHospital(id);
  }
}