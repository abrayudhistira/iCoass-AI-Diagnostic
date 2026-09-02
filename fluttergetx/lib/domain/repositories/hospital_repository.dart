import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'dart:io';
import '../entities/hospital_entity.dart';

abstract class HospitalRepository {
  Future<Either<Failure, List<HospitalEntity>>> getHospitals({
    required double lat,
    required double lng,
    double radius = 10,
    int page = 1,
    int limit = 10,
  });
  Future<Either<Failure, bool>> createHospital(HospitalEntity hospital, File? imageFile);
  Future<Either<Failure, bool>> updateHospital(int id, HospitalEntity hospital, File? imageFile);
  Future<Either<Failure, bool>> deleteHospital(int id);
}
