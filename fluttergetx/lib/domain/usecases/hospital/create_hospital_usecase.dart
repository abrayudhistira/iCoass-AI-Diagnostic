import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'dart:io';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/domain/repositories/hospital_repository.dart';

class CreateHospitalUseCase {
  final HospitalRepository repository;

  CreateHospitalUseCase(this.repository);

  Future<Either<Failure, bool>> call(HospitalEntity hospital, {File? imageFile}) {
    return repository.createHospital(hospital, imageFile);
  }
}