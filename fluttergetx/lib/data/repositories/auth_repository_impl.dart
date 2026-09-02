import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/data/services/auth_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/*
 * AuthRepositoryImpl - DI & Usage
 *
 * - Receives Dio via constructor injection: AuthRepositoryImpl(this._dio)
 * - Use relative paths with _dio (e.g. _dio.post('login', ...)).
 * - Do not concat _baseUrl manually; rely on dio.options.baseUrl.
 * - Token management:
 *   - save access_token and refresh_token to FlutterSecureStorage (keys: 'access_token', 'refresh_token')
 *   - TokenInterceptor attached to Dio will perform refresh and retry.
 * - Defensive parsing: check response.data runtimeType before converting to models.
 */

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final AuthService _authService; // Inject AuthService

  AuthRepositoryImpl(this._dio, this._authService);

  @override
  Future<Either<Failure, UserEntity>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        'login',
        data: {'username': username, 'password': password},
      );

      final data = response.data;

      if (data is! Map) {
        return Left(ServerFailure(
          message: "Response dari backend bukan Map: $data",
        ));
      }

      if (data['success'] == true) {
        await _authService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        final user = UserModel.fromJson({'user': data['user']});
        // Store user details in secure storage for quick access
        await _authService.saveUserDetails(user.id.toString(), user.fullName, user.username, user.role);

        return Right(user);
      } else {
        // Handle structured error response when success is false
        final code = data['code']?.toString();
        final message = data['message']?.toString() ?? "Login gagal";
        final details = data['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
    } on DioException catch (e) {
      return Left(_mapDioError(e, "Terjadi kesalahan saat login"));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('register', data: data);

      if (response.data['success'] == true) {
        return const Right(true);
      } else {
        final code = response.data['code']?.toString();
        final message = response.data['message']?.toString() ?? "Gagal mendaftar";
        final details = response.data['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
    } on DioException catch (e) {
      return Left(_mapDioError(e, "Gagal mendaftar"));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getDetail() async {
    try {
      String? userId = await _authService.getUserId(); // Use AuthService
      if (userId == null) return Left(UnauthorizedFailure(message: "Sesi tidak valid"));

      final response = await _dio.get('users/$userId');

      final dynamic rawData = response.data;

      if (rawData is Map<String, dynamic>) {
        bool isSuccess =
            rawData['success'] == true || rawData['status'] == 'success';

        if (isSuccess) {
          final userData = rawData['data'] ?? rawData;
          return Right(UserModel.fromJson(userData));
        } else {
          final code = rawData['code']?.toString();
          final message = rawData['message']?.toString() ?? "Gagal mengambil data profil";
          final details = rawData['details'] as Map<String, dynamic>?;
          return Left(_createFailureFromResponse(code, message, details, response.statusCode));
        }
      } else {
        return Left(ServerFailure(message: "Format respon server tidak valid (Bukan JSON Object)"));
      }
    } on DioException catch (e) {
      print("DEBUG: [getDetail] DioException: ${e.message}");
      return Left(_mapDioError(e, "Gagal mengambil data detail pengguna"));
    } catch (e, stack) {
      print("DEBUG: [getDetail] Exception Terdeteksi: $e");
      print("DEBUG: [getDetail] StackTrace: $stack");
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async {
    try {
      final response = await _dio.get('users');

      if (response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return Right(list.map((json) => UserModel.fromJson(json)).toList());
      } else {
        final code = response.data['code']?.toString();
        final message = response.data['message']?.toString() ?? "Gagal mengambil daftar pengguna";
        final details = response.data['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
    } on DioException catch (e) {
      return Left(_mapDioError(e, "Gagal mengambil daftar pengguna"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(int id) async {
    try {
      final response = await _dio.delete('admin/users/$id');
      if (response.data['success'] == true) {
        return const Right(null);
      }
      final code = response.data['code']?.toString();
      final message = response.data['message']?.toString() ?? "Gagal menghapus pengguna";
      final details = response.data['details'] as Map<String, dynamic>?;
      return Left(_createFailureFromResponse(code, message, details, response.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioError(e, "Gagal menghapus pengguna"));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required int id,
    required String username,
    required String email,
    required String fullName,
    required String phone,
    required String birthDate,
    required String gender,
    required String address,
    String? password,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'username': username,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'birth_date': birthDate,
        'gender': gender,
        'address': address,
      };

      if (password != null && password.isNotEmpty) updateData['password'] = password;

      final response = await _dio.put('users/$id', data: updateData);

      if (response.data != null && response.data['success'] == true) {
        // Skenario A: Backend mengirim data user terbaru
        if (response.data['data'] != null && response.data['data']['user'] != null) {
          return Right(UserModel.fromJson(response.data['data']['user']));
        }

        // Skenario B: Kembalikan objek minimal
        return Right(UserEntity(
          id: id,
          username: username,
          email: email,
          fullName: fullName,
          role: '',
          phone: phone,
          address: address,
          gender: gender,
          birthDate: birthDate,
        ));
      }
      final code = response.data['code']?.toString();
      final message = response.data['message']?.toString() ?? "Gagal memperbarui profil";
      final details = response.data['details'] as Map<String, dynamic>?;
      return Left(_createFailureFromResponse(code, message, details, response.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioError(e, "Gagal memperbarui profil"));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getToken() async {
    try {
      final token = await _authService.getAccessToken();
      return Right(token);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> refreshAccessToken() async {
    try {
      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken == null) {
        return Left(UnauthorizedFailure(message: "Refresh token tidak ditemukan"));
      }

      final response = await _dio.post(
        'refresh-token',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      if (data['success'] == true) {
        await _authService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        return const Right(null);
      } else {
        final code = data['code']?.toString();
        final message = data['message']?.toString() ?? "Refresh token gagal";
        final details = data['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
    } on DioException catch (e) {
      return Left(_mapDioError(e, "Gagal me-refresh token"));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final result = await _authService.isLoggedIn();
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await _authService.getRefreshToken();

      if (refreshToken != null) {
        try {
          await _dio.post(
            'logout',
            data: {'refreshToken': refreshToken},
          );
        } catch (_) {
          // ignore errors during logout API call
        }
      }
      await _authService.clearTokens();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Helper to create appropriate Failure from a successful HTTP response with success=false
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

  /// Helper untuk menangani error dari Dio secara konsisten.
  /// Parse backend error codes (ERR_VALIDATION, ERR_UNAUTHORIZED, etc.) and throw typed failures.
  Failure _mapDioError(DioException e, String defaultMessage) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // Parse structured backend error response
    if (data is Map) {
      final code = data['code']?.toString();
      final message = data['message']?.toString() ?? defaultMessage;
      final details = data['details'] as Map<String, dynamic>?;

      // Rate limit (429) - check header for retry-after
      int? retryAfter;
      if (statusCode == 429) {
        final resetHeader = e.response?.headers.value('RateLimit-Reset');
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

      // Map error codes to typed failures
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
          // Unknown code but structured response
          return ServerFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
      }
    } else if (data is String) {
      // Handle HTML error pages (Apache/XAMPP default pages)
      if (data.contains('<!DOCTYPE') || data.contains('<html')) {
        if (statusCode == 404) {
          return NotFoundFailure(message: 'Endpoint API tidak ditemukan (404)');
        }
        if (statusCode == 500) {
          return ServerFailure(message: 'Kesalahan internal server (500)');
        }
        return ServerFailure(message: 'Server mengembalikan respon tidak valid (HTML)', statusCode: statusCode);
      }
      // Plain text error
      return ServerFailure(message: data, statusCode: statusCode);
    }

    // Network-level errors (no response)
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
        return ServerFailure(
          message: defaultMessage,
          statusCode: statusCode,
        );
      case DioExceptionType.unknown:
      default:
        return UnknownFailure(message: '$defaultMessage (${e.type.name}): ${e.message}');
    }
  }

  /// Legacy method kept for backward compatibility where string message is expected
  String _handleDioError(DioException e, String defaultMessage) {
    return _mapDioError(e, defaultMessage).message;
  }
}
