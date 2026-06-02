import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/domain/entities/user_entity.dart';
import 'package:get/get.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;
  final _storage = const FlutterSecureStorage();

  var isLoading = false.obs;
  var displayName = "Pengguna".obs;
  var isAuthenticated = false.obs;

  var usernameError = RxnString();
  var currentUser = Rxn<UserEntity>();
  var passwordError = RxnString();
  var users = <UserEntity>[].obs;

  AuthController(this._repository);

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  // void checkAuthStatus() async {
  //   print("DEBUG: Memulai cek status autentikasi...");

  //   // Ambil role dari secure storage
  //   String? role = await _storage.read(key: 'role');
  //   bool loggedIn = await _repository.isLoggedIn();

  //   print("DEBUG: Status login: $loggedIn, Role: $role");

  //   isAuthenticated.value = loggedIn;

  //   if (loggedIn) {
  //     if (role == 'admin') {
  //       Get.offAllNamed('/admin-home');
  //     } else {
  //       Get.offAllNamed('/home');
  //     }
  //   } else {
  //     Get.offAllNamed('/login');
  //   }
  // }
  void checkAuthStatus() async {
    String? role = await _storage.read(key: 'role');
    bool loggedIn = await _repository.isLoggedIn();

    isAuthenticated.value = loggedIn;

    if (loggedIn) {
      // PENTING: Ambil data profil saat auto-login agar currentUser tidak null
      fetchUserProfile();

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
    print("DEBUG: [fetchUserProfile] Memulai fetch data detail user...");
    try {
      final user = await _repository.getDetail();

      if (user != null) {
        print(
          "DEBUG: [fetchUserProfile] Berhasil! User: ${user.username}, ID: ${user.id}",
        );
        currentUser.value = user;
        displayName.value = user.fullName;
      } else {
        print("DEBUG: [fetchUserProfile] GAGAL: Repository mengembalikan null");
      }
    } catch (e, stacktrace) {
      print("DEBUG: [fetchUserProfile] EXCEPTION: $e");
      print("DEBUG: [fetchUserProfile] STACKTRACE: $stacktrace");
    }
  }

  Future<void> fetchAllUsers() async {
    isLoading.value = true;
    try {
      final result = await _repository.getAllUsers();
      users.assignAll(result);
      debugPrint('✅ [AUTH] Berhasil memuat ${result.length} pengguna');
    } catch (e) {
      debugPrint('🚨 [AUTH ERROR] Gagal fetch users: $e');
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUserAccount(int id) async {
    isLoading.value = true;
    try {
      final success = await _repository.deleteUser(id);
      if (success) {
        users.removeWhere((u) => u.id == id);
        Get.snackbar("Sukses", "Akun berhasil dihapus",
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
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
      final result = await _repository.updateProfile(
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

      if (result != null) {
        await fetchAllUsers();
        Get.back();
        Get.snackbar("Sukses", "Data pengguna diperbarui",
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Gagal Update", e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
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
      // 1. Eksekusi request update ke repository
      final result = await _repository.updateProfile(
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

      // 2. Jika repository mengembalikan data (meskipun hanya flag sukses/objek parsial)
      // Kita panggil fetchUserProfile untuk sinkronisasi data terbaru
      if (result != null) {
        print(
          "DEBUG: Update API Berhasil, melakukan sinkronisasi data profil...",
        );

        // Panggil fungsi fetchUserProfile yang sudah ada untuk memperbarui currentUser.value
        await fetchUserProfile();

        Get.back(); // Kembali ke halaman sebelumnya
        Get.snackbar(
          "Sukses",
          "Profil berhasil diperbarui",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        print("DEBUG: Update gagal karena repository mengembalikan null");
      }
    } catch (e) {
      print("DEBUG: Error saat update profil: $e");
      Get.snackbar(
        "Gagal Update",
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // void login(String username, String password) async {
  //   // Reset error sebelum mulai login
  //   usernameError.value = null;
  //   passwordError.value = null;
  //   isLoading.value = true;

  //   try {
  //     final user = await _repository.login(username, password);
  //     if (user != null) {
  //       await _storage.write(key: 'role', value: user.role);
  //       await fetchUserProfile();
  //       displayName.value = user.fullName;
  //       isAuthenticated.value = true;
  //       if (user.role == 'admin') {
  //         Get.offAllNamed('/admin-home');
  //       } else {
  //         Get.offAllNamed('/home');
  //       }
  //     }
  //   } catch (e) {
  //     String msg = e.toString();

  //     // Logika mapping error ke field spesifik
  //     if (msg.contains("Akun tidak ditemukan")) {
  //       usernameError.value = msg;
  //     } else if (msg.contains("Password salah")) {
  //       passwordError.value = msg;
  //     } else {
  //       // Jika error umum (misal server mati)
  //       Get.snackbar(
  //         "Login Gagal",
  //         msg,
  //         backgroundColor: AppColors.error,
  //         colorText: AppColors.white,
  //       );
  //     }
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  void login(String username, String password) async {
    // Reset error sebelum mulai login
    usernameError.value = null;
    passwordError.value = null;
    isLoading.value = true;

    debugPrint('🚀 [AUTH] Memulai proses login untuk username: $username');

    try {
      final user = await _repository.login(username, password);
      
      if (user != null) {
        debugPrint('✅ [AUTH] Login Berhasil. User ID: ${user.id}, Role: ${user.role}');

        // Simpan role ke storage
        await _storage.write(key: 'role', value: user.role);
        debugPrint('💾 [AUTH] Role "${user.role}" berhasil disimpan ke Secure Storage');

        // Fetch detail profile
        debugPrint('🔄 [AUTH] Mengambil profil lengkap user...');
        await fetchUserProfile();
        
        displayName.value = user.fullName;
        isAuthenticated.value = true;

        // Logika pengalihan halaman berdasarkan role
        if (user.role == 'admin') {
          debugPrint('📂 [NAVIGATION] Mengarahkan ke Dashboard Admin...');
          Get.offAllNamed('/admin-home');
        } else {
          debugPrint('📂 [NAVIGATION] Mengarahkan ke Home Pasien...');
          Get.offAllNamed('/home');
        }
      } else {
        debugPrint('⚠️ [AUTH] Repository mengembalikan null user (Data tidak cocok)');
      }
    } catch (e) {
      debugPrint('🚨 [AUTH ERROR] Terjadi kesalahan saat login: $e');
      
      String msg = e.toString();

      // Logika mapping error ke field spesifik
      if (msg.contains("Akun tidak ditemukan")) {
        debugPrint('❌ [AUTH MAPPING] Error: Username tidak ditemukan');
        usernameError.value = msg;
      } else if (msg.contains("Password salah")) {
        debugPrint('❌ [AUTH MAPPING] Error: Password salah');
        passwordError.value = msg;
      } else {
        debugPrint('🚨 [AUTH GLOBAL ERROR] Pesan error tidak ter-mapping, menampilkan snackbar.');
        Get.snackbar(
          "Login Gagal",
          msg,
          backgroundColor: Colors.redAccent, // Sesuaikan dengan AppColors.error
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
      debugPrint('🏁 [AUTH] Proses login selesai (isLoading = false)');
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _repository.logout();
      await _storage.delete(key: 'role');
      await _storage.deleteAll();
      displayName.value = "Pengguna";
      isAuthenticated.value = false;
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar("Error", "Gagal Logout: $e");
    } finally {
      isLoading.value = false;
    }
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
    try {
      final success = await _repository.register({
        "username": username,
        "email": email,
        "password": password,
        "full_name": fullName,
        "phone": phone,
        "birth_date": birthDate,
        "gender": gender,
        "address": address,
      });

      if (success) {
        Get.back(); // Kembali ke halaman login
        Get.snackbar(
          "Sukses",
          "Akun berhasil dibuat, silakan login",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Gagal",
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
