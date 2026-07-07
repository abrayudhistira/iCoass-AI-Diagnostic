import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final _secureStorage = const FlutterSecureStorage();

  AuthRepositoryImpl(this._dio);

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
        await _secureStorage.write(
          key: 'access_token',
          value: data['accessToken'],
        );
        await _secureStorage.write(
          key: 'refresh_token',
          value: data['refreshToken'],
        );
        // String token = data['token'];
        //final user = UserModel.fromJson(Map<String, dynamic>.from(data));
        final user = UserModel.fromJson({'user': data['user']});
        await _secureStorage.write(key: 'id', value: user.id.toString());
        await _secureStorage.write(key: 'full_name', value: user.fullName);
        await _secureStorage.write(key: 'username', value: user.username);
        await _secureStorage.write(key: 'role', value: user.role);

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
  // @override
  // Future<UserEntity?> getDetail() async {
  //   try {
  //     // 1. Ambil token dari penyimpanan aman
  //     String? token = await getToken();
  //     if (token == null) throw "Sesi berakhir, silakan login kembali";

  //     // 2. Lakukan request GET ke endpoint profile/detail dengan Header Authorization
  //     final response = await _dio.get(
  //       '$_baseUrl/profile', // Sesuaikan dengan endpoint backend Anda (misal: /me atau /profile)
  //       options: Options(
  //         headers: {
  //           'Authorization': 'Bearer $token',
  //           'Accept': 'application/json',
  //         },
  //       ),
  //     );

  //     if (response.data['success']) {
  //       // Mengikuti struktur JSON yang Anda berikan: data -> user
  //       return UserModel.fromJson(response.data);
  //     }
  //   } on DioException catch (e) {
  //     if (e.response?.statusCode == 401) {
  //       await logout(); // Otomatis logout jika token tidak valid/expired
  //       throw "Sesi tidak valid";
  //     }
  //     String errorMessage = e.response?.data['message'] ?? "Gagal mengambil data detail pengguna";
  //     throw errorMessage;
  //   }
  //   return null;
  // }
  @override
  Future<UserEntity?> getDetail() async {
    try {
      String? userId = await _secureStorage.read(key: 'id');
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
        // Pastikan fungsi logout() tersedia di class ini
        // await logout();
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
  Future<bool> deleteUser(int id) async {
    try {
      final response = await _dio.delete('admin/users/$id');
      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw _handleDioError(e, "Gagal menghapus pengguna");
    }
  }

  // @override
  // Future<UserEntity?> updateProfile({
  //   required int id,
  //   required String username,
  //   required String email,
  //   required String fullName,
  //   required String phone,
  //   required String birthDate,
  //   required String gender,
  //   required String address,
  // }) async {
  //   try {
  //     String? token = await getToken();
  //     if (token == null) throw "Sesi berakhir";

  //     // Konstruksi payload data tanpa menyertakan 'role' untuk menjaga integritas data
  //     final Map<String, dynamic> updateData = {
  //       'username': username,
  //       'email': email,
  //       'full_name': fullName,
  //       'phone': phone,
  //       'birth_date': birthDate,
  //       'gender': gender,
  //       'address': address,
  //     };

  //     // Menggunakan method PUT atau POST sesuai dengan desain API Backend (umumnya PUT untuk update)
  //     final response = await _dio.put(
  //       '$_baseUrl/users/$id', // Endpoint update by ID
  //       data: updateData,
  //       options: Options(
  //         headers: {
  //           'Authorization': 'Bearer $token',
  //           'Accept': 'application/json',
  //         },
  //       ),
  //     );

  //     if (response.data['success']) {
  //       // Mengembalikan data user terbaru setelah pembaruan
  //       return UserModel.fromJson(response.data['data']['user']);
  //     }
  //   } on DioException catch (e) {
  //     String errorMessage = e.response?.data['message'] ?? "Gagal memperbarui profil";
  //     throw errorMessage;
  //   }
  //   return null;
  // }

  @override
  Future<UserEntity?> updateProfile({
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
    print("DEBUG: === Memulai Proses Update Profile ===");

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

      print("DEBUG: Response Body Raw: ${response.data}");

      // MODIFIKASI DISINI:
      // Jika backend hanya mengirim {success: true}, kita tidak bisa melakukan parsing ke UserModel.
      // Namun, kita harus mengembalikan "sesuatu" agar Controller tahu ini sukses.
      if (response.data != null && response.data['success'] == true) {
        print("DEBUG: Update Berhasil (Success: true)");

        // Skenario A: Backend mengirim data user terbaru
        if (response.data['data'] != null &&
            response.data['data']['user'] != null) {
          return UserModel.fromJson(response.data['data']['user']);
        }

        // Skenario B: Backend hanya mengirim pesan sukses (seperti log Anda)
        // Kita kembalikan objek UserModel dummy atau objek dengan ID saja
        // agar result di controller tidak NULL.
        print(
          "DEBUG: Backend tidak mengirim data user, mengembalikan objek minimal untuk memicu refresh.",
        );
        return UserEntity(
          id: id,
          username: username,
          email: email,
          fullName: fullName,
          role: '',
          phone: phone,
          address: address,
          gender: gender,
          birthDate: birthDate,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, "Gagal memperbarui profil");
    } catch (e) {
      rethrow;
    }

    return null;
  }

  //   @override
  // Future<UserEntity?> updateProfile({
  //   required int id,
  //   required String username,
  //   required String email,
  //   required String fullName,
  //   required String phone,
  //   required String birthDate,
  //   required String gender,
  //   required String address,
  // }) async {
  //   print("DEBUG: === Memulai Proses Update Profile ===");
  //   print("DEBUG: ID Target: $id");

  //   try {
  //     String? token = await getToken();
  //     print("DEBUG: Token Status: ${token != null ? 'Tersedia' : 'NULL'}");

  //     if (token == null) {
  //       print("DEBUG: ERROR - Token tidak ditemukan, melempar exception 'Sesi berakhir'");
  //       throw "Sesi berakhir";
  //     }

  //     // Konstruksi payload data
  //     final Map<String, dynamic> updateData = {
  //       'username': username,
  //       'email': email,
  //       'full_name': fullName,
  //       'phone': phone,
  //       'birth_date': birthDate,
  //       'gender': gender,
  //       'address': address,
  //     };

  //     final String fullUrl = '$_baseUrl/users/$id';
  //     print("DEBUG: Request URL: $fullUrl");
  //     print("DEBUG: Request Payload: $updateData");

  //     final response = await _dio.put(
  //       fullUrl,
  //       data: updateData,
  //       options: Options(
  //         headers: {
  //           'Authorization': 'Bearer $token',
  //           'Accept': 'application/json',
  //         },
  //       ),
  //     );

  //     print("DEBUG: Response Status Code: ${response.statusCode}");
  //     print("DEBUG: Response Body Raw: ${response.data}");

  //     // Validasi field 'success' pada body response
  //     if (response.data != null && response.data['success'] == true) {
  //       print("DEBUG: Update Berhasil (Success: true)");

  //       // Pastikan path data['user'] sesuai dengan struktur JSON dari backend
  //       if (response.data['data'] != null && response.data['data']['user'] != null) {
  //         final updatedUser = UserModel.fromJson(response.data['data']['user']);
  //         print("DEBUG: Parsing UserModel Berhasil: ${updatedUser.username}");
  //         return updatedUser;
  //       } else {
  //         print("DEBUG: ERROR - Struktur data['user'] tidak ditemukan di response");
  //       }
  //     } else {
  //       print("DEBUG: Update Gagal - API mengembalikan success: false");
  //     }
  //   } on DioException catch (e) {
  //     print("DEBUG: === DIO EXCEPTION DETECTED ===");
  //     print("DEBUG: Type: ${e.type}");
  //     print("DEBUG: Status Code: ${e.response?.statusCode}");
  //     print("DEBUG: Response Data: ${e.response?.data}");
  //     print("DEBUG: Message: ${e.message}");

  //     // Mengekstrak pesan error spesifik dari backend jika ada
  //     String errorMessage = "Gagal memperbarui profil";
  //     if (e.response?.data != null && e.response?.data['message'] != null) {
  //       errorMessage = e.response?.data['message'];
  //       print("DEBUG: Extracted Backend Error: $errorMessage");
  //     }
  //     throw errorMessage;
  //   } catch (e, stacktrace) {
  //     print("DEBUG: === UNKNOWN EXCEPTION ===");
  //     print("DEBUG: Error: $e");
  //     print("DEBUG: Stacktrace: $stacktrace");
  //     throw e.toString();
  //   }

  //   print("DEBUG: Update Profile berakhir dengan return NULL (tidak masuk ke blok success)");
  //   return null;
  // }

  @override
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  @override
  Future<void> refreshAccessToken() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    final response = await _dio.post(
      'refresh-token',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data;
    if (data['success'] == true) {
      await _secureStorage.write(
        key: 'access_token',
        value: data['accessToken'],
      );
    } else {
      throw data['message'] ?? "Refresh token gagal";
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    String? token = await getToken();
    return token != null;
  }

  @override
  Future<void> logout() async {
    // Defensive logout: attempt API call if tokens exist, ignore errors, and clear storage.
    final accessToken = await _secureStorage.read(key: 'access_token');
    final refreshToken = await _secureStorage.read(key: 'refresh_token');

    if (accessToken != null && refreshToken != null) {
      try {
        await _dio.post(
          'logout',
          data: {'refreshToken': refreshToken},
        );
      } catch (_) {
        // ignore errors during logout API call
      }
    }
    // Clear tokens locally regardless of API outcome
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
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
