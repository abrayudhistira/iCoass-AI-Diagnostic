import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/hospital_entity.dart';
import '../../domain/repositories/hospital_repository.dart';
import '../models/hospital_model.dart';

/// [HospitalRepositoryImpl] mengelola aliran data antara aplikasi dan backend.
/// Dioptimalkan untuk menjaga integritas koordinat geospasial 8-digit desimal.
class HospitalRepositoryImpl implements HospitalRepository {
  final Dio _dio;
  final _secureStorage = const FlutterSecureStorage();

  HospitalRepositoryImpl(this._dio);

  Future<Options> _getOptions() async {
    return Options(headers: {
      "Accept": "application/json",
    });
  }

  @override
  Future<bool> createHospital(HospitalEntity hospital, File? imageFile) async {
    try {
      // KRUSIAL: Konversi latitude dan longitude ke String dengan presisi tetap (8 digit)
      // sebelum dimasukkan ke dalam FormData. Ini mencegah pembulatan oleh JSON serializer.
      final Map<String, dynamic> dataMap = {
        "name": hospital.name,
        "address": hospital.address,
        "latitude": hospital.latitude.toStringAsFixed(8), 
        "longitude": hospital.longitude.toStringAsFixed(8),
        "phone": hospital.phone ?? "",
        "description": hospital.description ?? "",
      };

      FormData formData = FormData.fromMap(dataMap);

      if (imageFile != null) {
        formData.files.add(MapEntry(
          "image",
          await MultipartFile.fromFile(
            imageFile.path, 
            filename: imageFile.path.split('').last
          ),
        ));
      }

      final response = await _dio.post(
        'hospitals',
        data: formData,
        options: await _getOptions(),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      _logDioError('CREATE', e);
      return false;
    }
  }

  @override
  Future<List<HospitalEntity>> getHospitals({
    required double lat,
    required double lng,
    double radius = 10,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // KRUSIAL: Mengirim koordinat via Query Params dengan presisi 8 digit
      final response = await _dio.get(
        'hospitals',
        queryParameters: {
          "latitude": lat.toStringAsFixed(8),
          "longitude": lng.toStringAsFixed(8),
          "radius": radius.toInt(),
          "page": page,
          "limit": limit
        },
        options: await _getOptions(),
      );

      if (response.data != null && response.data['data'] != null) {
        List rawList = response.data['data'];
        return rawList.map((e) => HospitalModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      _logDioError('GET_NEARBY', e);
      return [];
    }
  }

  @override
  Future<bool> deleteHospital(int id) async {
    try {
      final response = await _dio.delete(
        'hospitals/$id',
        options: await _getOptions(),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      _logDioError('DELETE', e);
      return false;
    }
  }

  void _logDioError(String context, DioException e) {
    debugPrint('--- [REPO ERROR: $context] ---');
    debugPrint('URL: ${e.requestOptions.uri}');
    debugPrint('Status Code: ${e.response?.statusCode}');
    if (e.response?.data is Map) {
      debugPrint('Message: ${e.response?.data['message']}');
    }
  }
  
  @override
  Future<bool> updateHospital(int id, HospitalEntity hospital, File? imageFile) async {
    try {
      // Pastikan presisi koordinat tetap terjaga untuk akurasi pemetaan
      final Map<String, dynamic> dataMap = {
        "name": hospital.name,
        "address": hospital.address,
        "latitude": hospital.latitude.toStringAsFixed(8),
        "longitude": hospital.longitude.toStringAsFixed(8),
        "phone": hospital.phone ?? "",
        "description": hospital.description ?? "",
      };

      FormData formData = FormData.fromMap(dataMap);

      if (imageFile != null) {
        formData.files.add(MapEntry(
          "image",
          await MultipartFile.fromFile(
            imageFile.path, 
            filename: imageFile.path.split('').last
          ),
        ));
      }

      // Melakukan request PUT ke endpoint /hospitals/:id
      final response = await _dio.put(
        'hospitals/$id',
        data: formData,
        options: await _getOptions(),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      _logDioError('UPDATE', e);
      return false;
    }
  }
}
