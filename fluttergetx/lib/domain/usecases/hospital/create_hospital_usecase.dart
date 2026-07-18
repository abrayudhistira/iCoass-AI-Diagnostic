import 'dart:io';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/domain/repositories/hospital_repository.dart';

class CreateHospitalUseCase {
  final HospitalRepository repository;

  CreateHospitalUseCase(this.repository);

  Future<bool> call(HospitalEntity hospital, {File? imageFile}) {
    return repository.createHospital(hospital, imageFile);
  }
}