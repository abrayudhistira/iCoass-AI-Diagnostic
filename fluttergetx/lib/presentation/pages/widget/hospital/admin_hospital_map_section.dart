import 'dart:async';
import 'dart:core';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/presentation/controllers/hospital_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// [AdminHospitalMapSection] — Visualisasi peta Google Maps untuk mode admin.
/// Menampilkan marker transient (biru) saat form aktif, dan marker RSGM (custom) dari database.
/// UI/UX disamakan dengan PatientHospitalPage: custom markers, radius circles, consistent styling.
class AdminHospitalMapSection extends StatefulWidget {
  final HospitalController controller;
  final LatLng selectedLatLng;
  final bool isFormVisible;
  final HospitalEntity? selectedHospital;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<LatLng> onLongPress;
  final VoidCallback onTap;
  final ValueChanged<HospitalEntity> onHospitalTap;

  const AdminHospitalMapSection({
    super.key,
    required this.controller,
    required this.selectedLatLng,
    required this.isFormVisible,
    required this.selectedHospital,
    required this.onMapCreated,
    required this.onLongPress,
    required this.onTap,
    required this.onHospitalTap,
  });

  @override
  State<AdminHospitalMapSection> createState() => _AdminHospitalMapSectionState();
}

class _AdminHospitalMapSectionState extends State<AdminHospitalMapSection> with SingleTickerProviderStateMixin {
  BitmapDescriptor? _hospitalMarkerIcon;

  // Animasi untuk marker transient (pulse effect)
  late final AnimationController _pulseController;
  Timer? _animationTimer;

  static const int _totalFrames = 12;
  final List<BitmapDescriptor> _transientPulseFrames = [];
  int _currentFrameIndex = 0;

  BitmapDescriptor? get _transientMarkerIcon {
    if (_transientPulseFrames.isEmpty) return null;
    return _transientPulseFrames[_currentFrameIndex];
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _initializeCustomMarkers();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Membangun representasi biner untuk marker custom
  Future<void> _initializeCustomMarkers() async {
    _hospitalMarkerIcon = await _createHospitalMarkerBitmap();

    // Generate SEMUA frame pulse SEKALI di awal untuk marker transient
    for (int i = 0; i < _totalFrames; i++) {
      final double t = i / _totalFrames;
      final double scale = ui.lerpDouble(1.0, 2.0, t)!;
      final double opacity = ui.lerpDouble(0.6, 0.0, t)!;
      final icon = await _createTransientPulseBitmap(scale, opacity);
      _transientPulseFrames.add(icon);
    }

    if (mounted) setState(() {});

    _pulseController.repeat();

    // Timer HANYA mengganti index frame (ringan), TIDAK generate ulang bitmap
    _animationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % _totalFrames;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show radius circle based on controller's selected radius (matching patient page)
    final double radiusInMeters = widget.controller.selectedRadius.value * 1000;

    return Obx(
      () => GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: widget.selectedLatLng,
          zoom: _determineInitialZoom(widget.controller.selectedRadius.value),
        ),
        markers: _buildMapMarkers(),
        circles: _buildRadiusCircles(radiusInMeters),
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: true,
        onMapCreated: widget.onMapCreated,
        onLongPress: widget.onLongPress,
        onTap: (_) => widget.onTap(),
      ),
    );
  }

  Set<Circle> _buildRadiusCircles(double radiusInMeters) {
    return {
      // Outer Ring - Subtle Boundary
      Circle(
        circleId: const CircleId('admin_geospatial_radius_outer'),
        center: widget.selectedLatLng,
        radius: radiusInMeters,
        strokeWidth: 2,
        strokeColor: AppColors.primary.withValues(alpha: 0.4),
        fillColor: Colors.transparent,
      ),
      // Inner Fill - Translucent Geometric Overlay
      Circle(
        circleId: const CircleId('admin_geospatial_radius_inner'),
        center: widget.selectedLatLng,
        radius: radiusInMeters,
        strokeWidth: 0,
        fillColor: AppColors.primary.withValues(alpha: 0.08),
      ),
    };
  }

  Set<Marker> _buildMapMarkers() {
    final Set<Marker> markers = {};

    // 1. Marker Transien dengan Pulse Effect (saat form aktif)
    if (widget.isFormVisible && _transientMarkerIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('active_transient_marker'),
          position: widget.selectedLatLng,
          icon: _transientMarkerIcon!,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 2,
          infoWindow: const InfoWindow(title: 'Lokasi Terpilih'),
        ),
      );
    } else if (widget.isFormVisible) {
      // Fallback jika custom marker belum siap
      markers.add(
        Marker(
          markerId: const MarkerId('active_transient_marker_fallback'),
          position: widget.selectedLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Lokasi Terpilih'),
        ),
      );
    }

    // 2. Marker Persisten Rumah Sakit dari Database (Custom Pin)
    for (var hospital in widget.controller.hospitals) {
      markers.add(
        Marker(
          markerId: MarkerId('hospital_id_${hospital.id}'),
          position: LatLng(hospital.latitude, hospital.longitude),
          icon: _hospitalMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(0.5, 1.0), // Bottom center alignment untuk pin berekor
          zIndexInt: 1,
          infoWindow: InfoWindow(
            title: hospital.name,
            snippet: hospital.address,
          ),
          onTap: () => widget.onHospitalTap(hospital),
        ),
      );
    }

    return markers;
  }

  double _determineInitialZoom(double radius) {
    if (radius <= 5) return 13.0;
    if (radius <= 10) return 11.5;
    if (radius <= 20) return 10.0;
    if (radius <= 30) return 9.0;
    return 8.0;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LOW-LEVEL CANVAS BITMAP GENERATORS
  // ───────────────────────────────────────────────────────────────────────────

  /// Konstruksi representasi grafis biner Penanda Transien (Pulse Effect - Biru)
  /// Ukuran dikecilkan lagi: size 80 (was 100), core radius 6 (was 8), pulse radius 10 (was 12)
  Future<BitmapDescriptor> _createTransientPulseBitmap(double scale, double opacity) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double size = 80.0; // Dikecilkan dari 100
    const double center = size / 2;

    // 1. Menggambar Ring Enveloping Pulse (Biru)
    final Paint pulsePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(center, center), 10.0 * scale, pulsePaint); // 10 was 12

    // 2. Menggambar Core Dot (Pusat Lokasi)
    final Paint coreShadowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0); // 4 was 5
    canvas.drawCircle(const Offset(center, center), 6.0, coreShadowPaint); // 6 was 8

    final Paint coreBorderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(center, center), 6.0, coreBorderPaint);

    final Paint coreCenterPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(center, center), 4.0, coreCenterPaint); // 4 was 5

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Konstruksi representasi grafis biner Penanda RSGM (Custom Pin Tail - Merah/Error)
  /// Ukuran dikecilkan lagi: width 58 (was 70), height 70 (was 85), radius 22 (was 28), icon 26 (was 32)
  Future<BitmapDescriptor> _createHospitalMarkerBitmap() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    const double width = 58.0;   // Dikecilkan dari 70
    const double height = 70.0;  // Dikecilkan dari 85
    const double radius = 22.0;  // Dikecilkan dari 28

    // 1. Menggambar Shadow Objek Pin
    final Paint shadowPaint = Paint()
      ..color = AppColors.error.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0); // 4 was 5
    canvas.drawCircle(const Offset(width / 2, radius + 4), radius, shadowPaint); // +4 was +5

    // 2. Menggambar Struktur Lingkaran Atas Pin (Kontainer Ikon)
    final Paint pinBodyPaint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(width / 2, radius + 4), radius, pinBodyPaint);

    final Paint pinBorderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // 3 was 4
    canvas.drawCircle(const Offset(width / 2, radius + 4), radius, pinBorderPaint);

    // 3. Menggambar Ekor Pin Konstruktif (Tail) - disesuaikan dengan ukuran baru
    final Paint tailPaint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.fill;
    final ui.Path path = ui.Path()
      ..moveTo(width / 2 - 8, radius * 2 - 2)   // -8 was -10, -2 was -3
      ..lineTo(width / 2, height - 10)           // -10 was -12
      ..lineTo(width / 2 + 8, radius * 2 - 2)    // +8 was +10
      ..close();
    canvas.drawPath(path, tailPaint);

    // 4. Menggambar Simbologi Ikon Medis (Local Hospital Cross)
    const opacityIconColor = AppColors.white;
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.local_hospital_rounded.codePoint),
      style: const TextStyle(
        fontSize: 26.0,  // Dikecilkan dari 32
        fontFamily: 'MaterialIcons',
        color: opacityIconColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, (radius * 2 + 8 - textPainter.height) / 2), // +8 was +10
    );

    final ui.Image image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }
}