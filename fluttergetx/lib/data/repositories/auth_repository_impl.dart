import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  Future<UserEntity?> login(String username, String password) async {
    try {
      print("DEBUG: Akan melakukan request login...");
      final response = await _dio.post(
        'login',
        data: {'username': username, 'password': password},
      );
      print("DEBUG: Selesai request login");

      final data = response.data;

      if (data is! Map) {
        throw Exception("Response dari backend bukan Map: $data");
      }

      if (data['success'] == true) {
        await _authService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        final user = UserModel.fromJson({'user': data['user']});
        // Store user details in secure storage for quick access
        await _authService.saveUserDetails(user.id.toString(), user.fullName, user.username, user.role);

        return user;
      }
    } on DioException catch (e) {
      throw _handleDioError(e, "Terjadi kesalahan saat login");
    } catch (e) {
      throw e.toString();
    }
    return null;
  }

  @override
  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('register', data: data);
      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw _handleDioError(e, "Gagal mendaftar");
    }
  }

  @override
  Future<UserEntity?> getDetail() async {
    try {
      String? userId = await _authService.getUserId(); // Use AuthService
      if (userId == null) throw "Sesi tidak valid";

      final response = await _dio.get('users/$userId');

      final dynamic rawData = response.data;

      if (rawData is Map<String, dynamic>) {
        bool isSuccess =
            rawData['success'] == true || rawData['status'] == 'success';

        if (isSuccess) {
          final userData = rawData['data'] ?? rawData;
          return UserModel.fromJson(userData);
        } else {
          throw rawData['message'] ?? "Gagal mengambil data profil";
        }
      } else {
        throw "Format respon server tidak valid (Bukan JSON Object)";
      }
    } on DioException catch (e) {
      print("DEBUG: [getDetail] DioException: ${e.message}");
      if (e.response?.statusCode == 401) {
        // await _authService.clearTokens(); // Clear tokens on 401
        throw "Sesi tidak valid atau kadaluwarsa";
      }
      throw _handleDioError(e, "Gagal mengambil data detail pengguna");
    } catch (e, stack) {
      print("DEBUG: [getDetail] Exception Terdeteksi: $e");
      print("DEBUG: [getDetail] StackTrace: $stack");
      rethrow;
    }
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    try {
      final response = await _dio.get('users');

      if (response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e, "Gagal mengambil daftar pengguna");
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(int id) async {
    try {
      final response = await _dio.delete('admin/users/$id');
      if (response.data['success'] == true) {
        return const Right(null);
      }
      return Left(ServerFailure(response.data['message'] ?? "Gagal menghapus pengguna"));
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e, "Gagal menghapus pengguna")));
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
      return Left(ServerFailure(response.data['message'] ?? "Gagal memperbarui profil"));
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e, "Gagal memperbarui profil")));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<String?> getToken() async {
    return await _authService.getAccessToken(); // Use AuthService
  }

  @override
  Future<void> refreshAccessToken() async {
    final refreshToken = await _authService.getRefreshToken(); // Use AuthService
    if (refreshToken == null) throw "Refresh token tidak ditemukan";

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
    } else {
      throw data['message'] ?? "Refresh token gagal";
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn(); // Use AuthService
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _authService.getRefreshToken(); // Use AuthService

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
    await _authService.clearTokens(); // Use AuthService
  }

  /// Helper untuk menangani error dari Dio secara konsisten.
  /// Mencegah error 'type String is not a subtype of type int' saat server mengirim HTML.
  String _handleDioError(DioException e, String defaultMessage) {
    if (e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message']?.toString() ?? defaultMessage;
      } else if (data is String) {
        // Cek jika response berisi HTML (biasanya halaman error Apache/XAMPP)
        if (data.contains('<!DOCTYPE') || data.contains('<html')) {
          if (e.response?.statusCode == 404)
            return "Endpoint API tidak ditemukan (404). Periksa URL backend Anda.";
          if (e.response?.statusCode == 500)
            return "Kesalahan internal server (500).";
          return "Server mengembalikan respon tidak valid (HTML).";
        }
        return data;
      }
    }
    if (e.type == DioExceptionType.connectionTimeout)
      return "Koneksi ke server timeout.";
    if (e.type == DioExceptionType.connectionError)
      return "Tidak dapat terhubung ke server. Pastikan server aktif.";

    // Jika tetap gagal, kembalikan tipe error Dio agar mudah dilacak
    return "$defaultMessage (${e.type.name}): ${e.message}";
  }
}
