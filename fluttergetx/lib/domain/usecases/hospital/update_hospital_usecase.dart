import 'dart:io';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/domain/repositories/hospital_repository.dart';

class UpdateHospitalUseCase {
  final HospitalRepository repository;

  UpdateHospitalUseCase(this.repository);

  Future<bool> call(int id, HospitalEntity hospital, {File? imageFile}) {
    return repository.updateHospital(id, hospital, imageFile);
  }
}