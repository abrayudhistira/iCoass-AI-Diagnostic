// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../domain/entities/hospital_entity.dart';
// import '../../data/repositories/hospital_repository_impl.dart';

// /// [HospitalController] mengelola logika bisnis untuk manajemen data rumah sakit.
// /// Dilengkapi dengan logging sistematis untuk keperluan debugging dan audit data.
// class HospitalController extends GetxController {
//   final HospitalRepositoryImpl repository;

//   HospitalController({required this.repository});

//   var hospitals = <HospitalEntity>[].obs;
//   var isLoading = false.obs;
//   var selectedImage = Rxn<File>();
  
//   // State untuk Filter Geospasial
//   // Radius dalam satuan KM sesuai dengan daftar pilihan yang diminta
//   var selectedRadius = 10.0.obs; 
//   final List<double> radiusOptions = [5, 10, 15, 20, 25, 30, 35, 40, 50, 55, 60];

//   // Koordinat acuan (Pusat Yogyakarta sebagai baseline penelitian)
//   // Di masa depan, ini bisa dinamis menggunakan library geolocator
//   final double defaultLat = -7.7956;
//   final double defaultLng = 110.3695;

//   final ImagePicker _picker = ImagePicker();

//   @override
//   void onInit() {
//     super.onInit();
//     fetchHospitals();
//   }

//   /// Mengambil data rumah sakit dari repositori dengan koordinat pusat Yogyakarta.
//   // Future<void> fetchHospitals() async {
//   //   try {
//   //     isLoading.value = true;
//   //     debugPrint('--- [FETCH] Memulai pengambilan data rumah sakit ---');
      
//   //     final result = await repository.getHospitals(
//   //       lat: -7.7956, 
//   //       lng: 110.3695,
//   //       radius: 10,
//   //     );
      
//   //     hospitals.assignAll(result);
//   //     debugPrint('--- [FETCH] Berhasil mengambil ${result.length} data ---');
//   //   } catch (e) {
//   //     debugPrint('--- [FETCH ERROR] Gagal mengambil data: $e ---');
//   //     Get.snackbar(
//   //       'Error',
//   //       'Gagal memuat data rumah sakit',
//   //       snackPosition: SnackPosition.BOTTOM,
//   //       backgroundColor: Colors.red.withOpacity(0.1),
//   //     );
//   //   } finally {
//   //     isLoading.value = false;
//   //   }
//   // }
//   Future<void> fetchHospitals() async {
//     try {
//       isLoading.value = true;
//       debugPrint('--- [FETCH GEOSPATIAL] Memulai pengambilan data RSGM ---');
//       debugPrint('Parameter: Lat=$defaultLat, Lng=$defaultLng, Radius=${selectedRadius.value}km');
      
//       final result = await repository.getHospitals(
//         lat: defaultLat, 
//         lng: defaultLng,
//         radius: selectedRadius.value,
//       );
      
//       hospitals.assignAll(result);
//       debugPrint('--- [FETCH SUCCESS] Terdeteksi ${result.length} RSGM dalam radius ---');
//     } catch (e) {
//       debugPrint('--- [FETCH ERROR] Kegagalan sistem pada fetchHospitals: $e ---');
//       _showErrorSnackbar('Gagal memuat data lokasi RSGM');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void updateRadius(double newRadius) {
//     if (selectedRadius.value != newRadius) {
//       selectedRadius.value = newRadius;
//       debugPrint('--- [FILTER CHANGE] Radius diperbarui menjadi: $newRadius KM ---');
//       fetchHospitals();
//     }
//   }

//   /// Menangani pemilihan gambar dengan optimasi kualitas untuk efisiensi bandwidth.
//   Future<void> pickImage() async {
//     try {
//       final XFile? pickedFile = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );
      
//       if (pickedFile != null) {
//         selectedImage.value = File(pickedFile.path);
//         debugPrint('--- [IMAGE] Gambar dipilih: ${pickedFile.path} ---');
//       }
//     } catch (e) {
//       debugPrint('--- [IMAGE ERROR] Gagal memilih gambar: $e ---');
//       _showErrorSnackbar('Gagal mengakses galeri');
//     }
//   }

//   void _showErrorSnackbar(String message) {
//     Get.snackbar(
//       'Error',
//       message,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red.withOpacity(0.1),
//       colorText: Colors.red[900],
//       margin: const EdgeInsets.all(10),
//       duration: const Duration(seconds: 3),
//     );
//   }

//   /// Eksekusi penyimpanan data rumah sakit baru ke server.
//   /// Menyertakan validasi parameter 'address' sesuai kontrak Entity.
//   Future<void> createHospital({
//     required String name,
//     required String address,
//     required String phone,
//     required String description,
//     required double lat,
//     required double lng,
//   }) async {
//     try {
//       isLoading.value = true;
//       debugPrint('--- [CREATE] Persiapan payload data rumah sakit ---');
//       debugPrint('Payload: Name=$name, Lat=$lat, Lng=$lng, Address=$address');

//       final hospital = HospitalEntity(
//         name: name,
//         address: address,
//         latitude: lat,
//         longitude: lng,
//         phone: phone,
//         description: description,
//       );

//       debugPrint('--- [CREATE] Mengirim data ke Repositori... ---');
//       final success = await repository.createHospital(hospital, selectedImage.value);

//       if (success) {
//         debugPrint('--- [CREATE SUCCESS] Data berhasil disimpan di server ---');
//         Get.back(); // Kembali ke halaman daftar
//         fetchHospitals(); // Refresh list
//         Get.snackbar(
//           'Sukses',
//           'Data rumah sakit berhasil disimpan',
//           backgroundColor: Colors.green.withOpacity(0.1),
//         );
//         selectedImage.value = null; 
//       }
//     } catch (e) {
//       debugPrint('--- [CREATE ERROR] Exception tertangkap: $e ---');
//       Get.snackbar(
//         'Gagal Menyimpan', 
//         e.toString().replaceAll('Exception: ', ''),
//         backgroundColor: Colors.red.withOpacity(0.1),
//         colorText: Colors.red[900],
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }
//   Future<bool> updateHospital({
//     required int id,
//     required String name,
//     required String address,
//     required String phone,
//     required String description,
//     required double lat,
//     required double lng,
//     File? imageFile,
//   }) async {
//     try {
//       isLoading.value = true;
//       debugPrint('--- [CONTROLLER UPDATE] Memproses Update ID: $id ---');

//       final hospital = HospitalEntity(
//         id: id,
//         name: name,
//         address: address,
//         latitude: lat,
//         longitude: lng,
//         phone: phone,
//         description: description,
//       );

//       final success = await repository.updateHospital(id, hospital, imageFile);

//       if (success) {
//         _onSuccess("Perubahan data berhasil disimpan");
//         return true;
//       } else {
//         Get.snackbar("Gagal", "Terjadi kesalahan saat memperbarui data");
//         return false;
//       }
//     } catch (e) {
//       debugPrint('--- [UPDATE ERROR] $e ---');
//       return false;
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Menghapus entitas rumah sakit berdasarkan ID.
//   Future<void> deleteHospital(int id) async {
//     try {
//       isLoading.value = true;
//       debugPrint('--- [DELETE] Menghapus RS dengan ID: $id ---');
      
//       final success = await repository.deleteHospital(id);
      
//       if (success) {
//         debugPrint('--- [DELETE SUCCESS] ID $id berhasil dihapus ---');
//         fetchHospitals();
//         Get.snackbar('Berhasil', 'Data telah dihapus');
//       }
//     } catch (e) {
//       debugPrint('--- [DELETE ERROR] Gagal menghapus ID $id: $e ---');
//       Get.snackbar('Error', 'Gagal menghapus data');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void _onSuccess(String message) {
//     Get.back();
//     fetchHospitals();
//     Get.snackbar('Sukses', message, backgroundColor: Colors.green.withOpacity(0.1));
//     selectedImage.value = null;
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/hospital_entity.dart';
import '../../data/repositories/hospital_repository_impl.dart';
 
/// [HospitalController] mengelola logika bisnis untuk manajemen data rumah sakit.
///
/// Perbaikan v2:
/// - Radius options diperbaiki ke interval standar (5, 10, 15, 20... km)
/// - Dukungan koordinat dinamis dari GPS pengguna
/// - Logging sistematis dengan prefix yang konsisten
/// - Penanganan error yang lebih robust
class HospitalController extends GetxController {
  final HospitalRepositoryImpl repository;
 
  HospitalController({required this.repository});
 
  // ─── Observable State ─────────────────────────────
  final hospitals = <HospitalEntity>[].obs;
  final isLoading = false.obs;
  final selectedImage = Rxn<File>();
 
  // ─── Geospatial State ─────────────────────────────
  /// Radius default dalam KM
  final selectedRadius = 10.0.obs;
 
  /// Daftar opsi radius dalam KM — interval 5 km yang konsisten
  final List<double> radiusOptions = [5, 10, 15, 20, 25, 30, 35, 40, 50, 55, 60];
 
  /// Koordinat yang digunakan untuk fetch API.
  /// Dapat diperbarui dari GPS pengguna via [updateUserCoordinates].
  final _activeLat = (-7.7956).obs;
  final _activeLng = (110.3695).obs;
 
  // ─── Default Coordinate (Yogyakarta Center) ───────
  static const double _defaultLat = -7.7956;
  static const double _defaultLng = 110.3695;
 
  final ImagePicker _picker = ImagePicker();
 
  // ─── Getters ──────────────────────────────────────
  double get activeLat => _activeLat.value;
  double get activeLng => _activeLng.value;
 
  @override
  void onInit() {
    super.onInit();
    debugPrint('[CONTROLLER] HospitalController initialized');
    fetchHospitals();
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  // GEOSPATIAL
  // ─────────────────────────────────────────────────────────────────────────
 
  /// Memperbarui koordinat aktif dengan posisi GPS pengguna.
  /// Akan otomatis melakukan fetch ulang jika koordinat berubah signifikan.
  void updateUserCoordinates(double lat, double lng) {
    final hasChanged = (_activeLat.value - lat).abs() > 0.0001 ||
        (_activeLng.value - lng).abs() > 0.0001;
 
    if (hasChanged) {
      _activeLat.value = lat;
      _activeLng.value = lng;
      debugPrint('[LOCATION] Koordinat diperbarui: Lat=$lat, Lng=$lng');
      fetchHospitals();
    }
  }
 
  /// Mereset koordinat ke pusat Yogyakarta (default).
  void resetToDefaultCoordinates() {
    _activeLat.value = _defaultLat;
    _activeLng.value = _defaultLng;
    debugPrint('[LOCATION] Reset ke koordinat default Yogyakarta');
    fetchHospitals();
  }
 
  /// Memperbarui radius filter dan melakukan fetch ulang data.
  void updateRadius(double newRadius) {
    if (!radiusOptions.contains(newRadius)) {
      debugPrint('[FILTER WARNING] Radius $newRadius tidak valid, diabaikan');
      return;
    }
 
    if (selectedRadius.value == newRadius) return;
 
    selectedRadius.value = newRadius;
    debugPrint('[FILTER] Radius diperbarui: ${newRadius.toInt()} KM');
    fetchHospitals();
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  // FETCH
  // ─────────────────────────────────────────────────────────────────────────
 
  Future<void> fetchHospitals() async {
    if (isLoading.value) {
      debugPrint('[FETCH] Request diabaikan: sedang loading');
      return;
    }
 
    try {
      isLoading.value = true;
      debugPrint('[FETCH] Memulai fetch RSGM...');
      debugPrint(
          '[FETCH] Params: Lat=${_activeLat.value}, Lng=${_activeLng.value}, Radius=${selectedRadius.value}km');
 
      final result = await repository.getHospitals(
        lat: _activeLat.value,
        lng: _activeLng.value,
        radius: selectedRadius.value,
      );
 
      hospitals.assignAll(result);
      debugPrint('[FETCH] Sukses: ${result.length} RSGM ditemukan');
    } catch (e, stackTrace) {
      debugPrint('[FETCH ERROR] $e');
      debugPrint('[FETCH STACKTRACE] $stackTrace');
      _showErrorSnackbar('Gagal memuat data RSGM');
    } finally {
      isLoading.value = false;
    }
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────────────────
 
  Future<void> createHospital({
    required String name,
    required String address,
    required String phone,
    required String description,
    required double lat,
    required double lng,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('[CREATE] Membuat data RSGM baru: $name');
 
      final hospital = HospitalEntity(
        name: name,
        address: address,
        latitude: lat,
        longitude: lng,
        phone: phone,
        description: description,
      );
 
      final success = await repository.createHospital(hospital, selectedImage.value);
 
      if (success) {
        debugPrint('[CREATE] Sukses: $name berhasil disimpan');
        _onSuccess('Data rumah sakit berhasil disimpan');
      } else {
        _showErrorSnackbar('Gagal menyimpan data rumah sakit');
      }
    } catch (e) {
      debugPrint('[CREATE ERROR] $e');
      _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────────────────
 
  Future<bool> updateHospital({
    required int id,
    required String name,
    required String address,
    required String phone,
    required String description,
    required double lat,
    required double lng,
    File? imageFile,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('[UPDATE] Memperbarui RSGM ID: $id');
 
      final hospital = HospitalEntity(
        id: id,
        name: name,
        address: address,
        latitude: lat,
        longitude: lng,
        phone: phone,
        description: description,
      );
 
      final success = await repository.updateHospital(id, hospital, imageFile);
 
      if (success) {
        debugPrint('[UPDATE] Sukses: ID $id berhasil diperbarui');
        _onSuccess('Perubahan data berhasil disimpan');
        return true;
      }
 
      _showErrorSnackbar('Gagal memperbarui data');
      return false;
    } catch (e) {
      debugPrint('[UPDATE ERROR] $e');
      _showErrorSnackbar('Terjadi kesalahan saat memperbarui data');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────────────────
 
  Future<void> deleteHospital(int id) async {
    try {
      isLoading.value = true;
      debugPrint('[DELETE] Menghapus RSGM ID: $id');
 
      final success = await repository.deleteHospital(id);
 
      if (success) {
        debugPrint('[DELETE] Sukses: ID $id dihapus');
        hospitals.removeWhere((h) => h.id == id);
        Get.snackbar(
          'Berhasil',
          'Data telah dihapus',
          backgroundColor: AppColors.success.withOpacity(0.1),
          colorText: AppColors.success,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        _showErrorSnackbar('Gagal menghapus data');
      }
    } catch (e) {
      debugPrint('[DELETE ERROR] $e');
      _showErrorSnackbar('Gagal menghapus ID $id');
    } finally {
      isLoading.value = false;
    }
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE
  // ─────────────────────────────────────────────────────────────────────────
 
  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
 
      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
        debugPrint('[IMAGE] Gambar dipilih: ${pickedFile.path}');
      }
    } catch (e) {
      debugPrint('[IMAGE ERROR] $e');
      _showErrorSnackbar('Gagal mengakses galeri');
    }
  }
 
  void clearSelectedImage() {
    selectedImage.value = null;
    debugPrint('[IMAGE] Gambar direset');
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
 
  void _onSuccess(String message) {
    Get.back();
    fetchHospitals();
    Get.snackbar(
      'Sukses',
      message,
      backgroundColor: AppColors.success.withOpacity(0.1),
      colorText: AppColors.success,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
    );
    selectedImage.value = null;
  }
 
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error.withOpacity(0.1),
      colorText: AppColors.error,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error_outline_rounded, color: AppColors.error),
    );
  }
}