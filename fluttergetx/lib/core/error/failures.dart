import 'package:equatable/equatable.dart';

/// Base failure class with error code matching backend specification
abstract class Failure extends Equatable {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  const Failure({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  @override
  List<Object?> get props => [code, message, details, statusCode];
}

/// Server-side errors (5xx, unexpected)
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    Map<String, dynamic>? details,
    int? statusCode,
  }) : super(
          code: 'ERR_INTERNAL',
          message: message,
          details: details,
          statusCode: statusCode ?? 500,
        );
}

/// Validation errors (400) - field-level
class ValidationFailure extends Failure {
  final String? field;

  const ValidationFailure({
    required String message,
    this.field,
    Map<String, dynamic>? details,
    int? statusCode,
  }) : super(
          code: 'ERR_VALIDATION',
          message: message,
          details: details,
          statusCode: statusCode ?? 400,
        );

  @override
  List<Object?> get props => [...super.props, field];
}

/// Unauthorized (401) - token invalid/expired
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    String message = 'Sesi tidak valid atau kadaluwarsa',
    Map<String, dynamic>? details,
    int? statusCode,
  }) : super(
          code: 'ERR_UNAUTHORIZED',
          message: message,
          details: details,
          statusCode: statusCode ?? 401,
        );
}

/// Forbidden (403) - access denied
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    String message = 'Anda tidak memiliki akses untuk aksi ini',
    Map<String, dynamic>? details,
    int? statusCode,
  }) : super(
          code: 'ERR_FORBIDDEN',
          message: message,
          details: details,
          statusCode: statusCode ?? 403,
        );
}

/// Not found (404)
class NotFoundFailure extends Failure {
  final String? resource;

  const NotFoundFailure({
    required String message,
    this.resource,
    Map<String, dynamic>? details,
    int? statusCode,
  }) : super(
          code: 'ERR_NOT_FOUND',
          message: message,
          details: details,
          statusCode: statusCode ?? 404,
        );

  @override
  List<Object?> get props => [...super.props, resource];
}

/// Conflict (409) - duplicate resource
class ConflictFailure extends Failure {
  const ConflictFailure({
    required String message,
    Map<String, dynamic>? details,
    int? statusCode,
  }) : super(
          code: 'ERR_CONFLICT',
          message: message,
          details: details,
          statusCode: statusCode ?? 409,
        );
}

/// Rate limited (429) - with retry info
class RateLimitFailure extends Failure {
  final int? retryAfterSeconds;

  const RateLimitFailure({
    required String message,
    this.retryAfterSeconds,
    Map<String, dynamic>? details,
    int? statusCode,
  }) : super(
          code: 'ERR_VALIDATION', // Backend uses ERR_VALIDATION for rate limit
          message: message,
          details: details,
          statusCode: statusCode ?? 429,
        );

  @override
  List<Object?> get props => [...super.props, retryAfterSeconds];
}

/// Cache/local storage errors
class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'Gagal mengakses penyimpanan lokal',
    Map<String, dynamic>? details,
  }) : super(
          code: 'CACHE_ERROR',
          message: message,
          details: details,
          statusCode: null,
        );
}

/// Network/connection errors
class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'Tidak dapat terhubung ke server',
    Map<String, dynamic>? details,
  }) : super(
          code: 'NETWORK_ERROR',
          message: message,
          details: details,
          statusCode: null,
        );
}

/// Timeout errors
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    String message = 'Koneksi ke server timeout',
    Map<String, dynamic>? details,
  }) : super(
          code: 'TIMEOUT_ERROR',
          message: message,
          details: details,
          statusCode: null,
        );
}

/// Unknown/unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    String message = 'Terjadi kesalahan yang tidak diketahui',
    Map<String, dynamic>? details,
  }) : super(
          code: 'UNKNOWN_ERROR',
          message: message,
          details: details,
          statusCode: null,
        );
}

/// Extension to easily create Failure from DioException
extension DioExceptionMapper on Exception {
  Failure toFailure() {
    if (this is Failure) return this as Failure;
    return UnknownFailure(message: toString());
  }
}