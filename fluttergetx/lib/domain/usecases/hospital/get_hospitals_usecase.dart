import 'dart:io';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/domain/repositories/hospital_repository.dart';

class GetHospitalsUseCase {
  final HospitalRepository repository;

  GetHospitalsUseCase(this.repository);

  Future<List<HospitalEntity>> call({
    required double lat,
    required double lng,
    required double radius,
  }) {
    return repository.getHospitals(lat: lat, lng: lng, radius: radius);
  }
}