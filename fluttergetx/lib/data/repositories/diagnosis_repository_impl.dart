import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/data/models/diagnosis_model.dart';
import 'package:fluttergetx/domain/entities/diagnosis_entity.dart';
import 'package:fluttergetx/domain/repositories/diagnosis_repository.dart';

/// Implementasi repository untuk modul diagnosa menggunakan Dio.
/// Disinkronkan dengan DiagnosisEntity dan DiagnosisDetail sesuai struktur skripsi.
class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final Dio _dio;

  DiagnosisRepositoryImpl(this._dio);

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

  @override
  Future<Either<Failure, DiagnosisResult>> fetchDiagnosis(List<String> symptomCodes) async {
    try {
      final response = await _dio.post(
        'diagnosis',
        data: {"symptoms": symptomCodes},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'];
          return Right(DiagnosisResultModel.fromJson(data).copyWith(symptomCodes: symptomCodes));
        }
        final code = body['code']?.toString();
        final message = body['message']?.toString() ?? 'Gagal melakukan diagnosa';
        final details = body['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Gagal melakukan diagnosa: ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      return Left(_mapError(e, 'Kesalahan diagnosa'));
    }
  }

  @override
  Future<Either<Failure, List<DiagnosisResult>>> fetchHistory() async {
    try {
      debugPrint('📡 [DEBUG] Memanggil fetchHistory...');
      final response = await _dio.get(
        'diagnosis/history',
      );

      if (response.data != null && response.data['success'] == true) {
        final List rawList = response.data['data'] ?? [];
        return Right(rawList.map((item) => DiagnosisResultModel.fromJson(item)).toList());
      }
      final code = response.data['code']?.toString();
      final message = response.data['message']?.toString() ?? 'Gagal memuat riwayat';
      final details = response.data['details'] as Map<String, dynamic>?;
      return Left(_createFailureFromResponse(code, message, details, response.statusCode));
    } on DioException catch (e) {
      debugPrint('🚨 [REPOSITORY ERROR] $e');
      return Left(_mapError(e, 'Gagal memuat riwayat'));
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
}