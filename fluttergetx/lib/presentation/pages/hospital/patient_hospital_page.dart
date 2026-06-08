import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/hospital_detail_sheet.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/hospital_map_section.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/loading_overlay.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/map_action_buttons.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/radius_filter_overlay.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../controllers/hospital_controller.dart';

/// [PatientHospitalPage] — halaman utama visualisasi RSGM untuk pasien.
///
/// Fitur:
/// - Peta interaktif dengan radius filter 5–60 km
/// - Tombol "Lokasi Saya" untuk mendapatkan posisi GPS pengguna
/// - Animasi marker dengan pulse effect
/// - Bottom sheet detail RSGM yang polished
/// - Loading overlay yang halus
class PatientHospitalPage extends StatefulWidget {
  const PatientHospitalPage({super.key});

  @override
  State<PatientHospitalPage> createState() => _PatientHospitalPageState();
}

class _PatientHospitalPageState extends State<PatientHospitalPage> {
  final HospitalController _controller = Get.find<HospitalController>();
  final MapController _mapController = MapController();

  // Koordinat default: Pusat Yogyakarta sebagai baseline
  static const LatLng _defaultCenter = LatLng(-7.7956, 110.3695);

  LatLng _currentUserLocation = _defaultCenter;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchHospitals();
      // Recenter map when hospital list updates
      ever(_controller.hospitals, (_) {
        _mapController.move(_currentUserLocation, _determineZoom());
      });
      // Adjust map when radius changes
      ever(_controller.selectedRadius, (_) {
        _mapController.move(_currentUserLocation, _determineZoom());
      });
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Helper to determine appropriate map zoom based on current radius
  double _determineZoom() {
    final radius = _controller.selectedRadius.value;
    if (radius <= 5) return 14.0;
    if (radius <= 10) return 12.0;
    if (radius <= 20) return 10.0;
    if (radius <= 30) return 9.0;
    return 8.0; // default for larger radii
  }
  // ─────────────────────────────────────────────

  /// Meminta izin dan mendapatkan posisi GPS pengguna.
  Future<void> _goToMyLocation() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);

    try {
      final permission = await _checkAndRequestPermission();
      if (!permission) {
        _showPermissionDeniedSnackbar();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() => _currentUserLocation = userLatLng);

      // Animasi peta ke lokasi pengguna
      _mapController.move(userLatLng, 14.0);

      // SINKRONISASI: Update koordinat di controller agar fetch API selanjutnya akurat
      // Ini akan memicu fetchHospitals otomatis di dalam controller.
      _controller.updateUserCoordinates(
        userLatLng.latitude,
        userLatLng.longitude,
      );

      debugPrint(
        '[LOCATION] Posisi pengguna disinkronkan: ${position.latitude}, ${position.longitude}',
      );
    } on LocationServiceDisabledException {
      _showLocationServiceDisabledSnackbar();
    } on TimeoutException {
      _showSnackbar('Timeout', 'Gagal mendapatkan lokasi. Coba lagi.');
    } catch (e) {
      debugPrint('[LOCATION ERROR] $e');
      _showSnackbar('Error', 'Gagal mendapatkan lokasi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw const LocationServiceDisabledException();

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void _showPermissionDeniedSnackbar() {
    _showSnackbar(
      'Izin Ditolak',
      'Aktifkan izin lokasi di pengaturan perangkat.',
      isError: true,
    );
  }

  void _showLocationServiceDisabledSnackbar() {
    _showSnackbar(
      'GPS Tidak Aktif',
      'Aktifkan layanan lokasi perangkat Anda.',
      isError: true,
    );
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? AppColors.error.withOpacity(0.1)
          : AppColors.success.withOpacity(0.1),
      colorText: isError ? AppColors.error : AppColors.success,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: Icon(
        isError
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Membuat status bar transparan agar peta terlihat full-screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top,
        ),
        child: Stack(
          children: [
            // Layer 1: Peta Utama
            Obx(
              () => HospitalMapSection(
                key: ValueKey(_controller.selectedRadius.value),
                controller: _controller,
                centerLocation: _currentUserLocation,
                mapController: _mapController,
              ),
            ),

            // Layer 2: Filter Radius Overlay (top)
            RadiusFilterOverlay(controller: _controller),

            // Layer 3: Tombol Aksi Peta (FAB kanan bawah)
            MapActionButtons(
              mapController: _mapController,
              userLocation: _currentUserLocation,
              isLocating: _isLocating,
              onLocate: _goToMyLocation,
            ),

            // Layer 4: Loading Overlay (full screen)
            Obx(() => LoadingOverlay(isVisible: _controller.isLoading.value)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.97),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
      ),
      title: const _AppBarTitle(),
      actions: [
        _RefreshButton(onRefresh: () => _controller.fetchHospitals()),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// APPBAR COMPONENTS
// ─────────────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: AppColors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RSGM Terdekat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Yogyakarta & sekitarnya',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;

  const _RefreshButton({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Refresh Data',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onRefresh();
          },
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
