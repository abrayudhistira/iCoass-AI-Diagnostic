import 'dart:async';
import 'dart:core';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/presentation/controllers/hospital_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'hospital_detail_sheet.dart';

/// [HospitalMapSection] mengonstruksi visualisasi peta berbasis Google Maps SDK
/// dengan memuat penanda kustom yang dikonversi dari representasi grafis Canvas.
class HospitalMapSection extends StatefulWidget {
  final HospitalController controller;
  final LatLng centerLocation;
  final ValueChanged<GoogleMapController> onMapCreated;

  const HospitalMapSection({
    super.key,
    required this.controller,
    required this.centerLocation,
    required this.onMapCreated,
  });

  @override
  State<HospitalMapSection> createState() => _HospitalMapSectionState();
}

class _HospitalMapSectionState extends State<HospitalMapSection> with SingleTickerProviderStateMixin {
  // BitmapDescriptor? _userMarkerIcon;
  BitmapDescriptor? _hospitalMarkerIcon;

  List<BitmapDescriptor> _userPulseFrames = [];
  int _currentFrameIndex = 0;

  BitmapDescriptor? get _userMarkerIcon {
  if (_userPulseFrames.isEmpty) return null;
  return _userPulseFrames[_currentFrameIndex];
}
  
  // Prasarana animasi untuk efek pulse lokasi pengguna
  late final AnimationController _pulseController;
  Timer? _animationTimer;

  static const int _totalFrames = 12;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Menginisialisasi konversi grafis widget ke format Bitmap internal Google Maps
    _initializeCustomMarkers();

    // Loop interval untuk memperbarui marker lokasi dengan parameter pulse ter-animasi
    // _pulseController.repeat();
    // _animationTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
    //   if (mounted) {
    //     _updateUserPulseIcon();
    //   }
    // });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Membangun representasi biner untuk marker berdasarkan perhitungan matematis kurva animasi
  Future<void> _initializeCustomMarkers() async {
    _hospitalMarkerIcon = await _createHospitalMarkerBitmap();
    // _updateUserPulseIcon();
    // Generate SEMUA frame pulse SEKALI di awal (bukan berulang setiap tick)
    for (int i = 0; i < _totalFrames; i++) {
      final double t = i / _totalFrames;
      final double scale = ui.lerpDouble(1.0, 2.2, t)!;
      final double opacity = ui.lerpDouble(0.5, 0.0, t)!;
      final icon = await _createUserPulseBitmap(scale, opacity);
      _userPulseFrames.add(icon);
    }

    if (mounted) setState(() {});

    _pulseController.repeat();

    // Timer sekarang HANYA mengganti index frame (ringan), TIDAK generate ulang bitmap
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % _totalFrames;
        });
      }
    });
  }

  // Future<void> _updateUserPulseIcon() async {
  //   final double scale = ui.lerpDouble(1.0, 2.2, _pulseController.value)!;
  //   final double opacity = ui.lerpDouble(0.5, 0.0, _pulseController.value)!;
    
  //   final BitmapDescriptor userIcon = await _createUserPulseBitmap(scale, opacity);
  //   if (mounted) {
  //     setState(() {
  //       _userMarkerIcon = userIcon;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final double radiusInMeters = widget.controller.selectedRadius.value * 1000;

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: widget.centerLocation,
        zoom: _determineInitialZoom(widget.controller.selectedRadius.value),
      ),
      onMapCreated: widget.onMapCreated,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      onTap: (_) {
        if (Get.isBottomSheetOpen ?? false) Get.back();
      },
      circles: {
        // Outer Ring - Subtle Boundary
        Circle(
          circleId: const CircleId('geospatial_radius_outer'),
          center: widget.centerLocation,
          radius: radiusInMeters,
          strokeWidth: 2,
          strokeColor: AppColors.primary.withOpacity(0.4),
          fillColor: Colors.transparent,
        ),
        // Inner Fill - Translucent Geometric Overlay
        Circle(
          circleId: const CircleId('geospatial_radius_inner'),
          center: widget.centerLocation,
          radius: radiusInMeters,
          strokeWidth: 0,
          fillColor: AppColors.primary.withOpacity(0.08),
        ),
      },
      markers: _generateMarkerSet(),
    );
  }

  Set<Marker> _generateMarkerSet() {
    final Set<Marker> markers = {};

    // Penambahan Marker Lokasi Pengguna dengan Pulse Efek
    // if (_userMarkerIcon != null) {
    //   markers.add(
    //     Marker(
    //       markerId: const MarkerId('patient_user_coordinates'),
    //       position: widget.centerLocation,
    //       icon: _userMarkerIcon!,
    //       anchor: const Offset(0.5, 0.5), // Center alignment untuk pulse dot
    //       zIndex: 2.0,
    //     ),
    //   );
    // }

    if (_userMarkerIcon != null) {
  markers.add(
    Marker(
      markerId: const MarkerId('patient_user_coordinates'),
      position: widget.centerLocation,
      icon: _userMarkerIcon!,
      anchor: const Offset(0.5, 0.5),
      zIndex: 2,
    ),
  );
}

    // Penambahan Entitas Marker Rumah Sakit Gigi & Mulut (RSGM)
    for (final HospitalEntity hospital in widget.controller.hospitals) {
      markers.add(
        Marker(
          markerId: MarkerId('hospital_entity_${hospital.id}'),
          position: LatLng(hospital.latitude, hospital.longitude),
          icon: _hospitalMarkerIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 1.0), // Bottom center alignment untuk pin berekor
          zIndex: 1.0,
          onTap: () => HospitalDetailSheet.show(hospital),
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

  /// Konstruksi representasi grafis biner Penanda Lokasi Pengguna (Pulse Effect)
  Future<BitmapDescriptor> _createUserPulseBitmap(double scale, double opacity) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double size = 120.0; // Dimensi bidang gambar untuk menampung penskalaan
    const double center = size / 2;

    // 1. Menggambar Ring Enveloping Pulse
    final Paint pulsePaint = Paint()
      ..color = AppColors.primary.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(center, center), 14.0 * scale, pulsePaint);

    // 2. Menggambar Core Dot (Pusat Lokasi) - Menggunakan maskFilter untuk blur
    final Paint coreShadowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(const Offset(center, center), 10.0, coreShadowPaint);

    final Paint coreBorderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(center, center), 10.0, coreBorderPaint);

    final Paint coreCenterPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(center, center), 7.0, coreCenterPaint);

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Konstruksi representasi grafis biner Penanda RSGM (Custom Pin Tail)
  Future<BitmapDescriptor> _createHospitalMarkerBitmap() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    const double width = 90.0;
    const double height = 110.0;
    const double radius = 36.0; // Sesuai dengan spesifikasi ukuran kontainer lama

    // 1. Menggambar Shadow Objek Pin - Menggunakan maskFilter untuk blur
    final Paint shadowPaint = Paint()
      ..color = AppColors.error.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(const Offset(width / 2, radius + 6), radius, shadowPaint);

    // 2. Menggambar Struktur Lingkaran Atas Pin (Kontainer Ikon)
    final Paint pinBodyPaint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(width / 2, radius + 6), radius, pinBodyPaint);

    final Paint pinBorderPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0; // Mewakili border 2.5 berpasangan sisi
    canvas.drawCircle(const Offset(width / 2, radius + 6), radius, pinBorderPaint);

    // 3. Menggambar Ekor Pin Konstruktif (Tail Painter Replacement)
    final Paint tailPaint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.fill;
    final ui.Path path = ui.Path()
      ..moveTo(width / 2 - 12, radius * 2 - 2)
      ..lineTo(width / 2, height - 15)
      ..lineTo(width / 2 + 12, radius * 2 - 2)
      ..close();
    canvas.drawPath(path, tailPaint);

    // 4. Menggambar Simbologi Ikon Medis (Local Hospital Cross)
    const opacityIconColor = AppColors.white;
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.local_hospital_rounded.codePoint),
      style: const TextStyle(
        fontSize: 42.0, // Skala proporsional di dalam kanvas biner
        fontFamily: 'MaterialIcons',
        color: opacityIconColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset((width - textPainter.width) / 2, (radius * 2 + 12 - textPainter.height) / 2),
    );

    final ui.Image image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}