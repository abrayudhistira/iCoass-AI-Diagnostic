import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/domain/usecases/hospital/create_hospital_usecase.dart';
import 'package:fluttergetx/domain/usecases/hospital/get_hospitals_usecase.dart';
import 'package:fluttergetx/domain/usecases/hospital/delete_hospital_usecase.dart';
import 'package:fluttergetx/domain/usecases/hospital/update_hospital_usecase.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttergetx/presentation/widgets/common_snackbar.dart';

class HospitalController extends GetxController {
  final GetHospitalsUseCase getHospitals;
  final CreateHospitalUseCase createHospitalUseCase;
  final UpdateHospitalUseCase updateHospitalUseCase;
  final DeleteHospitalUseCase deleteHospitalUseCase;

  HospitalController({
    required this.getHospitals,
    required this.createHospitalUseCase,
    required this.updateHospitalUseCase,
    required this.deleteHospitalUseCase,
  });

  /// Centralized failure handling with error code switching per backend spec
  String _handleFailure(Failure failure) {
    switch (failure.code) {
      case 'ERR_VALIDATION':
        if (failure is ValidationFailure && failure.field != null) {
          return '${failure.field}: ${failure.message}';
        }
        return failure.message;
      case 'ERR_UNAUTHORIZED':
        return 'Sesi kadaluwarsa, silakan login ulang';
      case 'ERR_FORBIDDEN':
        return 'Anda tidak memiliki akses untuk aksi ini';
      case 'ERR_NOT_FOUND':
        return failure.message;
      case 'ERR_CONFLICT':
        return failure.message;
      case 'ERR_INTERNAL':
        return 'Terjadi kesalahan server, coba lagi nanti';
      case 'CACHE_ERROR':
        return 'Gagal mengakses data lokal';
      case 'NETWORK_ERROR':
        return 'Tidak dapat terhubung ke server';
      case 'TIMEOUT_ERROR':
        return 'Koneksi timeout, coba lagi';
      default:
        return failure.message;
    }
  }

  // ─── Observable State ─────────────────────────────
  final hospitals = <HospitalEntity>[].obs;
  final isLoading = false.obs;
  final selectedImage = Rxn<File>();

  // ─── Geospatial State ─────────────────────────────
  final selectedRadius = 10.0.obs;
  final List<double> radiusOptions = [5, 10, 15, 20, 25, 30, 35, 40, 50, 55, 60];

  final _activeLat = (-7.7956).obs;
  final _activeLng = (110.3695).obs;

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

  // ─── GEOSPATIAL ──────────────────────────────────

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

  void resetToDefaultCoordinates() {
    _activeLat.value = _defaultLat;
    _activeLng.value = _defaultLng;
    debugPrint('[LOCATION] Reset ke koordinat default Yogyakarta');
    fetchHospitals();
  }

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

  // ─── FETCH ───────────────────────────────────────

  Future<void> fetchHospitals() async {
    if (isLoading.value) {
      debugPrint('[FETCH] Request diabaikan: sedang loading');
      return;
    }

    try {
      isLoading.value = true;
      debugPrint('[FETCH] Memulai fetch RSGM...');

      final result = await getHospitals(
        lat: _activeLat.value,
        lng: _activeLng.value,
        radius: selectedRadius.value,
      );

      result.fold(
        (failure) {
          final msg = _handleFailure(failure);
          debugPrint('[FETCH ERROR] $msg');
          _showErrorSnackbar(msg);
        },
        (data) {
          hospitals.assignAll(data);
          debugPrint('[FETCH] Sukses: ${data.length} RSGM ditemukan');
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[FETCH ERROR] $e');
      debugPrint('[FETCH STACKTRACE] $stackTrace');
      _showErrorSnackbar('Gagal memuat data RSGM');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── CREATE ──────────────────────────────────────

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

      final result = await createHospitalUseCase(hospital, imageFile: selectedImage.value);

      result.fold(
        (failure) {
          final msg = _handleFailure(failure);
          debugPrint('[CREATE ERROR] $msg');
          _showErrorSnackbar(msg);
        },
        (success) {
          if (success) {
            debugPrint('[CREATE] Sukses: $name berhasil disimpan');
            _onSuccess('Data rumah sakit berhasil disimpan');
          } else {
            _showErrorSnackbar('Gagal menyimpan data rumah sakit');
          }
        },
      );
    } catch (e) {
      debugPrint('[CREATE ERROR] $e');
      _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  // ─── UPDATE ──────────────────────────────────────

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

      final result = await updateHospitalUseCase(id, hospital, imageFile: imageFile);

      bool success = false;
      result.fold(
        (failure) {
          final msg = _handleFailure(failure);
          debugPrint('[UPDATE ERROR] $msg');
          _showErrorSnackbar(msg);
        },
        (data) {
          success = data;
          if (data) {
            debugPrint('[UPDATE] Sukses: ID $id berhasil diperbarui');
            _onSuccess('Perubahan data berhasil disimpan');
          } else {
            _showErrorSnackbar('Gagal memperbarui data');
          }
        },
      );
      return success;
    } catch (e) {
      debugPrint('[UPDATE ERROR] $e');
      _showErrorSnackbar('Terjadi kesalahan saat memperbarui data');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── DELETE ──────────────────────────────────────

  Future<void> deleteHospital(int id) async {
    try {
      isLoading.value = true;
      debugPrint('[DELETE] Menghapus RSGM ID: $id');

      final result = await deleteHospitalUseCase(id);

      result.fold(
        (failure) {
          final msg = _handleFailure(failure);
          debugPrint('[DELETE ERROR] $msg');
          _showErrorSnackbar(msg);
        },
        (success) {
          if (success) {
            debugPrint('[DELETE] Sukses: ID $id dihapus');
            hospitals.removeWhere((h) => h.id == id);
            AppSnackbar.success('Data telah dihapus', title: 'Berhasil');
          } else {
            AppSnackbar.error('Gagal menghapus data');
          }
        },
      );
    } catch (e) {
      debugPrint('[DELETE ERROR] $e');
      _showErrorSnackbar('Gagal menghapus ID $id');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── IMAGE ───────────────────────────────────────

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

  // ─── HELPERS ─────────────────────────────────────

  void _onSuccess(String message) {
    Get.back();
    fetchHospitals();
    AppSnackbar.success(message, title: 'Sukses');
    selectedImage.value = null;
  }

  void _showErrorSnackbar(String message) {
    AppSnackbar.error(message, title: 'Error');
  }
}