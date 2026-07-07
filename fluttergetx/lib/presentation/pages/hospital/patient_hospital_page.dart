import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/hospital_map_section.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/loading_overlay.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/map_action_buttons.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/radius_filter_overlay.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/hospital_controller.dart';

/// [PatientHospitalPage] — halaman utama visualisasi RSGM untuk pasien.
/// Terintegrasi penuh dengan Google Maps SDK.
class PatientHospitalPage extends StatefulWidget {
  const PatientHospitalPage({super.key});

  @override
  State<PatientHospitalPage> createState() => _PatientHospitalPageState();
}

class _PatientHospitalPageState extends State<PatientHospitalPage> {
  final HospitalController _controller = Get.find<HospitalController>();
  
  /// Menggunakan Completer untuk menampung referensi GoogleMapController secara asinkron
  final Completer<GoogleMapController> _mapControllerCompleter = Completer<GoogleMapController>();

  // Koordinat default: Pusat Yogyakarta sebagai baseline
  static const LatLng _defaultCenter = LatLng(-7.7956, 110.3695);

  LatLng _currentUserLocation = _defaultCenter;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchHospitals();
      
      // Sinkronisasi ulang kamera ketika struktur list data RSGM diperbarui
      ever(_controller.hospitals, (_) {
        _moveCameraToLocation(_currentUserLocation, _determineZoom());
      });
      
      // Penyesuaian viewport kamera ketika radius filter spasial digeser oleh pengguna
      ever(_controller.selectedRadius, (_) {
        _moveCameraToLocation(_currentUserLocation, _determineZoom());
      });
    });
  }

  /// Menghitung tingkat kedekatan (zoom level) kamera berdasarkan jangkauan radius (km)
  double _determineZoom() {
    final radius = _controller.selectedRadius.value;
    if (radius <= 5) return 13.5;
    if (radius <= 10) return 12.0;
    if (radius <= 20) return 10.5;
    if (radius <= 30) return 9.5;
    return 8.5;
  }

  /// Menjembatani pergerakan kamera Google Maps secara aman menggunakan interpolasi internal SDK
  Future<void> _moveCameraToLocation(LatLng target, double zoom) async {
    try {
      if (_mapControllerCompleter.isCompleted) {
        final GoogleMapController controller = await _mapControllerCompleter.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: zoom),
          ),
        );
      }
    } catch (e) {
      debugPrint('[MAP CAMERA ERROR] Gagal menggerakkan kamera: $e');
    }
  }

  /// Meminta akses hardware dan mengambil titik koordinat GPS aktual pengguna
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

      // Animasi perpindahan kamera ke posisi koordinat baru
      await _moveCameraToLocation(userLatLng, 14.0);

      // Sinkronisasi data koordinat ke state management internal untuk kalkulasi Naive Bayes / Geofencing
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

  @override
  Widget build(BuildContext context) {
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
            // Layer 1: Peta Utama Google Maps Section
            Obx(
              () => HospitalMapSection(
                key: ValueKey(_controller.selectedRadius.value),
                controller: _controller,
                centerLocation: _currentUserLocation,
                onMapCreated: (GoogleMapController controller) {
                  if (!_mapControllerCompleter.isCompleted) {
                    _mapControllerCompleter.complete(controller);
                  }
                },
              ),
            ),

            // Layer 2: Filter Radius Overlay (Top Floating Bar)
            RadiusFilterOverlay(controller: _controller),

            // Layer 3: Tombol Aksi Peta Terintegrasi Kamera Delegate
            MapActionButtons(
              onMoveCamera: _moveCameraToLocation,
              userLocation: _currentUserLocation,
              isLocating: _isLocating,
              onLocate: _goToMyLocation,
            ),

            // Layer 4: Loading Overlay (Full Screen Barrier)
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