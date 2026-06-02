import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/presentation/controllers/hospital_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'hospital_detail_sheet.dart';

/// [HospitalMapSection] merender peta utama dengan marker RSGM dan visualisasi radius.
/// Setiap aspek visual dienkapsulasi untuk kemudahan pemeliharaan.
class HospitalMapSection extends StatelessWidget {
  final HospitalController controller;
  final LatLng centerLocation;
  final MapController mapController;

  const HospitalMapSection({
    super.key,
    required this.controller,
    required this.centerLocation,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: centerLocation,
            initialZoom: 12.0,
            minZoom: 8.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onTap: (_, __) {
              if (Get.isBottomSheetOpen ?? false) Get.back();
            },
          ),
          children: [
            _TileLayer(),
            _RadiusCircleLayer(
              center: centerLocation,
              radiusKm: controller.selectedRadius.value,
            ),
            _MarkerLayer(
              controller: controller,
              centerLocation: centerLocation,
            ),
          ],
        ));
  }
}

/// Layer tile OpenStreetMap dengan atribusi yang sesuai.
class _TileLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.icoass.app',
      maxZoom: 19,
      // Tile fallback untuk kondisi offline
      errorTileCallback: (tile, error, stackTrace) {
        debugPrint('[MAP] Tile error: $error');
      },
    );
  }
}

/// Visualisasi lingkaran radius geospasial dengan styling yang halus.
class _RadiusCircleLayer extends StatelessWidget {
  final LatLng center;
  final double radiusKm;

  const _RadiusCircleLayer({
    required this.center,
    required this.radiusKm,
  });

  @override
  Widget build(BuildContext context) {
    return CircleLayer(
      circles: [
        // Outer ring - subtle border
        CircleMarker(
          point: center,
          color: Colors.transparent,
          borderStrokeWidth: 1.5,
          borderColor: AppColors.primary.withOpacity(0.4),
          useRadiusInMeter: true,
          radius: radiusKm * 1000,
        ),
        // Inner fill - transparent blue tint
        CircleMarker(
          point: center,
          color: AppColors.primary.withOpacity(0.08),
          borderStrokeWidth: 0,
          borderColor: Colors.transparent,
          useRadiusInMeter: true,
          radius: radiusKm * 1000,
        ),
      ],
    );
  }
}

/// Layer marker untuk lokasi pengguna dan semua RSGM hasil filter.
class _MarkerLayer extends StatelessWidget {
  final HospitalController controller;
  final LatLng centerLocation;

  const _MarkerLayer({
    required this.controller,
    required this.centerLocation,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        _buildUserMarker(centerLocation),
        ...controller.hospitals.map(_buildHospitalMarker),
      ],
    );
  }

  Marker _buildUserMarker(LatLng point) {
    return Marker(
      point: point,
      width: 56,
      height: 56,
      child: const _UserLocationMarker(),
    );
  }

  Marker _buildHospitalMarker(HospitalEntity hospital) {
    return Marker(
      point: LatLng(hospital.latitude, hospital.longitude),
      width: 44,
      height: 52,
      child: _HospitalMarker(
        onTap: () => HospitalDetailSheet.show(hospital),
      ),
    );
  }
}

/// Marker lokasi pengguna dengan efek pulse animasi.
class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _scaleAnim = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _opacityAnim = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        AnimatedBuilder(
          animation: _animController,
          builder: (_, __) => Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _opacityAnim.value,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ),
        // Core dot
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Marker pin rumah sakit dengan tampilan modern.
class _HospitalMarker extends StatelessWidget {
  final VoidCallback onTap;

  const _HospitalMarker({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: AppColors.white,
              size: 18,
            ),
          ),
          // Pin tail
          CustomPaint(
            size: const Size(10, 6),
            painter: _PinTailPainter(color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter untuk ekor pin marker.
/// Menggunakan `ui.Path` eksplisit untuk menghindari konflik dengan
/// `flutter_map`'s `Path<LatLng>` yang ter-import di file yang sama.
class _PinTailPainter extends CustomPainter {
  final Color color;

  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) =>
      oldDelegate.color != color;
}