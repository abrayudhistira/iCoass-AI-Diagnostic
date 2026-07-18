import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/user_entity.dart';
import 'package:fluttergetx/domain/usecases/auth/delete_user_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/get_all_users_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/get_user_detail_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/login_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/logout_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/register_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/update_profile_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/update_user_usecase.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

/*
 * AuthController - Clean Architecture with GetX
 *
 * - Use UseCases for all business logic
 * - Controller only handles UI state and navigation
 * - Use secure storage keys: 'role', 'access_token', 'refresh_token', 'id'
 */

class AuthController extends GetxController {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RegisterUseCase _registerUseCase;
  final GetUserDetailUseCase _getUserDetailUseCase;
  final GetAllUsersUseCase _getAllUsersUseCase;
  final DeleteUserUseCase _deleteUserUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UpdateUserUseCase _updateUserUseCase;
  final _storage = const FlutterSecureStorage();

  var isLoading = false.obs;
  var displayName = "Pengguna".obs;
  var isAuthenticated = false.obs;

  var usernameError = RxnString();
  var currentUser = Rxn<UserEntity>();
  var passwordError = RxnString();
  var users = <UserEntity>[].obs;

  String get userCity {
    final address = currentUser.value?.address;
    if (address == null || address.isEmpty) return 'Yogyakarta, Indonesia';
    return address;
  }

  // Token management methods for other controllers/services
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> refreshAccessToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;
    
    // TODO: Call refresh token API
    // For now, return existing token
    return await _storage.read(key: 'access_token');
  }

  AuthController({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RegisterUseCase registerUseCase,
    required GetUserDetailUseCase getUserDetailUseCase,
    required GetAllUsersUseCase getAllUsersUseCase,
    required DeleteUserUseCase deleteUserUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UpdateUserUseCase updateUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _registerUseCase = registerUseCase,
        _getUserDetailUseCase = getUserDetailUseCase,
        _getAllUsersUseCase = getAllUsersUseCase,
        _deleteUserUseCase = deleteUserUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _updateUserUseCase = updateUserUseCase;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  void checkAuthStatus() async {
    String? role = await _storage.read(key: 'role');
    String? token = await _storage.read(key: 'access_token');
    bool loggedIn = token != null && token.isNotEmpty;

    isAuthenticated.value = loggedIn;

    if (loggedIn) {
      await fetchUserProfile();

      if (role == 'admin') {
        Get.offAllNamed('/admin-home');
      } else {
        Get.offAllNamed('/home');
      }
    } else {
      Get.offAllNamed('/login');
    }
  }

  Future<void> fetchUserProfile() async {
    debugPrint("DEBUG: [fetchUserProfile] Memulai fetch data detail user...");
    
    final result = await _getUserDetailUseCase();
    
    result.fold(
      (failure) {
        final msg = failure is ServerFailure ? failure.message : failure.toString();
        debugPrint("DEBUG: [fetchUserProfile] GAGAL: $msg");
      },
      (user) {
        debugPrint("DEBUG: [fetchUserProfile] Berhasil! User: ${user.username}, ID: ${user.id}");
        currentUser.value = user;
        displayName.value = user.fullName;
      },
    );
  }

  Future<void> fetchAllUsers() async {
    isLoading.value = true;
    
    final result = await _getAllUsersUseCase();
    
    result.fold(
      (failure) {
        final msg = failure is ServerFailure ? failure.message : failure.toString();
        debugPrint('🚨 [AUTH ERROR] Gagal fetch users: $msg');
        Get.snackbar("Error", msg, backgroundColor: AppColors.error, colorText: Colors.white);
      },
      (userList) {
        users.assignAll(userList);
        debugPrint('✅ [AUTH] Berhasil memuat ${userList.length} pengguna');
      },
    );
    
    isLoading.value = false;
  }

  Future<void> deleteUserAccount(int id) async {
    isLoading.value = true;
    try {
      final result = await _deleteUserUseCase(id);
      result.fold(
        (failure) {
          final msg = failure is ServerFailure ? failure.message : failure.toString();
          Get.snackbar("Error", msg, backgroundColor: AppColors.error, colorText: Colors.white);
        },
        (_) {
          users.removeWhere((u) => u.id == id);
          Get.snackbar("Sukses", "Akun berhasil dihapus", backgroundColor: Colors.green, colorText: Colors.white);
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserAccount({
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
    isLoading.value = true;
    try {
      final result = await _updateUserUseCase(
        id: id,
        username: username,
        email: email,
        fullName: fullName,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        address: address,
        password: password,
      );
      result.fold(
        (failure) {
          final msg = failure is ServerFailure ? failure.message : failure.toString();
          Get.snackbar("Gagal Update", msg, backgroundColor: AppColors.error, colorText: Colors.white);
        },
        (_) {
          fetchAllUsers();
          Get.back();
          Get.snackbar("Sukses", "Data pengguna diperbarui", backgroundColor: Colors.green, colorText: Colors.white);
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    required String username,
    required String email,
    required String fullName,
    required String phone,
    required String birthDate,
    required String gender,
    required String address,
    String? password,
  }) async {
    if (currentUser.value == null) return;

    isLoading.value = true;
    try {
      final result = await _updateProfileUseCase(
        id: currentUser.value!.id,
        username: username,
        email: email,
        fullName: fullName,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        address: address,
        password: password,
      );
      result.fold(
        (failure) {
          final msg = failure is ServerFailure ? failure.message : failure.toString();
          Get.snackbar("Gagal Update", msg, backgroundColor: AppColors.error, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        },
        (_) {
          fetchUserProfile();
          Get.back();
          Get.snackbar("Sukses", "Profil berhasil diperbarui", backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  void login(String username, String password) async {
    usernameError.value = null;
    passwordError.value = null;
    isLoading.value = true;

    debugPrint('🚀 [AUTH] Memulai proses login untuk username: $username');

    final result = await _loginUseCase(username, password);

    result.fold(
      (failure) {
        final msg = failure is ServerFailure ? failure.message : failure.toString();
        debugPrint('🚨 [AUTH ERROR] Login gagal: $msg');
        if (msg.contains("Akun tidak ditemukan")) {
          usernameError.value = msg;
        } else if (msg.contains("Password salah")) {
          passwordError.value = msg;
        } else {
          Get.snackbar("Login Gagal", msg, backgroundColor: AppColors.error, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        }
      },
      (user) async {
        debugPrint('✅ [AUTH] Login Berhasil. User ID: ${user.id}, Role: ${user.role}');
        await _storage.write(key: 'role', value: user.role);
        await fetchUserProfile();
        displayName.value = user.fullName;
        isAuthenticated.value = true;

        if (user.role == 'admin') {
          Get.offAllNamed('/admin-home');
          Future.microtask(() {
            if (Get.isRegistered<PersistentTabController>()) {
              Get.find<PersistentTabController>().index = 0;
            }
          });
        } else {
          Get.offAllNamed('/home');
          Future.microtask(() {
            if (Get.isRegistered<PersistentTabController>()) {
              Get.find<PersistentTabController>().index = 0;
            }
          });
        }
      },
    );

    isLoading.value = false;
    debugPrint('🏁 [AUTH] Proses login selesai (isLoading = false)');
  }

  Future<void> logout() async {
    isLoading.value = true;
    
    final result = await _logoutUseCase();
    
    result.fold(
      (failure) {
        final msg = failure is ServerFailure ? failure.message : failure.toString();
        debugPrint('🚨 [AUTH] Logout API gagal: $msg, tetap logout lokal');
      },
      (_) {
        debugPrint('✅ [AUTH] Logout berhasil');
      },
    );

    await _storage.delete(key: 'role');
    await _storage.deleteAll();
    displayName.value = "Pengguna";
    isAuthenticated.value = false;
    Get.offAllNamed('/login');
    isLoading.value = false;
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String birthDate,
    required String gender,
    required String address,
  }) async {
    isLoading.value = true;
    
    final data = {
      "username": username,
      "email": email,
      "password": password,
      "full_name": fullName,
      "phone": phone,
      "birth_date": birthDate,
      "gender": gender,
      "address": address,
    };

    final result = await _registerUseCase(data);

    result.fold(
      (failure) {
        final msg = failure is ServerFailure ? failure.message : failure.toString();
        Get.snackbar("Gagal", msg, backgroundColor: AppColors.error, colorText: Colors.white);
      },
      (success) {
        if (success) {
          Get.back();
          Get.snackbar("Sukses", "Akun berhasil dibuat, silakan login", backgroundColor: Colors.green, colorText: Colors.white);
        }
      },
    );

    isLoading.value = false;
  }
}