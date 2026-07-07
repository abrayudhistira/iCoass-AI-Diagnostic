import 'package:flutter/material.dart';
import 'package:fluttergetx/presentation/controllers/hospital_controller.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationController extends GetxController {
  var currentAddress = 'Mencari lokasi...'.obs;
  var isLocationLoading = false.obs;

  // Buat instance Geocoding sekali di level class
  final Geocoding _geocoding = Geocoding();

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      isLocationLoading.value = true;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        currentAddress.value = 'GPS tidak aktif';
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          currentAddress.value = 'Izin lokasi ditolak';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        currentAddress.value = 'Izin lokasi ditolak permanen';
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (Get.isRegistered<HospitalController>()) {
        Get.find<HospitalController>().updateUserCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      // FIX: panggil lewat instance _geocoding, bukan top-level function
      List<Placemark> placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String locality = place.locality ?? '';
        String subAdministrativeArea = place.subAdministrativeArea ?? '';

        currentAddress.value = locality.isNotEmpty
            ? locality
            : (subAdministrativeArea.isNotEmpty
                ? subAdministrativeArea
                : 'Yogyakarta, Indonesia');
      }
    } catch (e) {
      debugPrint('[LOCATION ERROR] Kegagalan reduksi koordinat GPS: $e');
      currentAddress.value = 'Gagal memuat lokasi';
    } finally {
      isLocationLoading.value = false;
    }
  }
}