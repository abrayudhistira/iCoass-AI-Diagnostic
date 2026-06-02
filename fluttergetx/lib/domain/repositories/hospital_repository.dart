import 'dart:io';
import '../entities/hospital_entity.dart';

abstract class HospitalRepository {
  Future<List<HospitalEntity>> getHospitals({
    required double lat,
    required double lng,
    double radius = 10,
  });
  Future<bool> createHospital(HospitalEntity hospital, File? imageFile);
  Future<bool> updateHospital(int id, HospitalEntity hospital, File? imageFile);
  Future<bool> deleteHospital(int id);
}