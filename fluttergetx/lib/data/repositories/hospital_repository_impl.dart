import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttergetx/core/error/failures.dart';
import '../../domain/entities/hospital_entity.dart';
import '../../domain/repositories/hospital_repository.dart';
import '../models/hospital_model.dart';

/// [HospitalRepositoryImpl] mengelola aliran data antara aplikasi dan backend.
/// Dioptimalkan untuk menjaga integritas koordinat geospasial 8-digit desimal.
class HospitalRepositoryImpl implements HospitalRepository {
  final Dio _dio;

  HospitalRepositoryImpl(this._dio);

  Failure _mapError(DioException e, String defaultMessage) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final code = data['code']?.toString();
      final message = data['message']?.toString() ?? defaultMessage;
      final details = data['details'] as Map<String, dynamic>?;

      if (statusCode == 429) {
        final resetHeader = e.response?.headers.value('RateLimit-Reset');
        int? retryAfter;
        if (resetHeader != null) {
          final resetTime = int.tryParse(resetHeader);
          if (resetTime != null) {
            retryAfter = (resetTime - DateTime.now().millisecondsSinceEpoch / 1000).ceil();
            retryAfter = retryAfter! > 0 ? retryAfter : 1;
          }
        }
        return RateLimitFailure(
          message: message,
          retryAfterSeconds: retryAfter,
          details: details,
          statusCode: statusCode,
        );
      }

      switch (code) {
        case 'ERR_VALIDATION':
          return ValidationFailure(
            message: message,
            field: details?['field']?.toString(),
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_UNAUTHORIZED':
          return UnauthorizedFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_FORBIDDEN':
          return ForbiddenFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_NOT_FOUND':
          return NotFoundFailure(
            message: message,
            resource: details?['field']?.toString(),
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_CONFLICT':
          return ConflictFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_INTERNAL':
          return ServerFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        default:
          return ServerFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
      }
    } else if (data is String) {
      if (data.contains('<!DOCTYPE') || data.contains('<html')) {
        if (statusCode == 404) {
          return NotFoundFailure(message: 'Endpoint API tidak ditemukan (404)');
        }
        if (statusCode == 500) {
          return ServerFailure(message: 'Kesalahan internal server (500)');
        }
        return ServerFailure(message: 'Server mengembalikan respon tidak valid (HTML)', statusCode: statusCode);
      }
      return ServerFailure(message: data, statusCode: statusCode);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure();
      case DioExceptionType.connectionError:
        return NetworkFailure();
      case DioExceptionType.cancel:
        return UnknownFailure(message: 'Request dibatalkan');
      case DioExceptionType.badResponse:
        return ServerFailure(message: defaultMessage, statusCode: statusCode);
      case DioExceptionType.unknown:
      default:
        return UnknownFailure(message: '$defaultMessage (${e.type.name}): ${e.message}');
    }
  }

  void _logDioError(String context, DioException e) {
    debugPrint('--- [REPO ERROR: $context] ---');
    debugPrint('URL: ${e.requestOptions.uri}');
    debugPrint('Status Code: ${e.response?.statusCode}');
    if (e.response?.data is Map) {
      debugPrint('Message: ${e.response?.data['message']}');
      debugPrint('Code: ${e.response?.data['code']}');
    }
  }

  Failure _createFailureFromResponse(
    String? code,
    String message,
    Map<String, dynamic>? details,
    int? statusCode,
  ) {
    switch (code) {
      case 'ERR_VALIDATION':
        return ValidationFailure(
          message: message,
          field: details?['field']?.toString(),
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_UNAUTHORIZED':
        return UnauthorizedFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_FORBIDDEN':
        return ForbiddenFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_NOT_FOUND':
        return NotFoundFailure(
          message: message,
          resource: details?['field']?.toString(),
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_CONFLICT':
        return ConflictFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_INTERNAL':
        return ServerFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      default:
        return ServerFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
    }
  }

  @override
  Future<Either<Failure, bool>> createHospital(HospitalEntity hospital, File? imageFile) async {
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
            filename: imageFile.path.split(Platform.pathSeparator).last
          ),
        ));
      }

      final response = await _dio.post(
        'hospitals',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return const Right(true);
        }
        final code = body['code']?.toString();
        final message = body['message']?.toString() ?? 'Gagal membuat rumah sakit';
        final details = body['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Gagal membuat rumah sakit: ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      _logDioError('CREATE', e);
      return Left(_mapError(e, 'Gagal membuat rumah sakit'));
    }
  }

  @override
  Future<Either<Failure, List<HospitalEntity>>> getHospitals({
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
      );

      if (response.data != null && response.data['data'] != null) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          List rawList = body['data'];
          return Right(rawList.map((e) => HospitalModel.fromJson(e)).toList());
        }
        final code = body['code']?.toString();
        final message = body['message']?.toString() ?? 'Gagal mengambil rumah sakit';
        final details = body['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Gagal mengambil rumah sakit: Format respons tidak valid'));
    } on DioException catch (e) {
      _logDioError('GET_NEARBY', e);
      return Left(_mapError(e, 'Gagal mengambil rumah sakit'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteHospital(int id) async {
    try {
      final response = await _dio.delete(
        'hospitals/$id',
      );
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return const Right(true);
        }
        final code = body['code']?.toString();
        final message = body['message']?.toString() ?? 'Gagal menghapus rumah sakit';
        final details = body['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Gagal menghapus rumah sakit: ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      _logDioError('DELETE', e);
      return Left(_mapError(e, 'Gagal menghapus rumah sakit'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateHospital(int id, HospitalEntity hospital, File? imageFile) async {
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
            filename: imageFile.path.split(Platform.pathSeparator).last
          ),
        ));
      }

      // Melakukan request PUT ke endpoint /hospitals/:id
      final response = await _dio.put(
        'hospitals/$id',
        data: formData,
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return const Right(true);
        }
        final code = body['code']?.toString();
        final message = body['message']?.toString() ?? 'Gagal memperbarui rumah sakit';
        final details = body['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Gagal memperbarui rumah sakit: ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      _logDioError('UPDATE', e);
      return Left(_mapError(e, 'Gagal memperbarui rumah sakit'));
    }
  }
}