import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/colors.dart';
import '../../../controllers/hospital_controller.dart';

/// [HospitalMapPreview] — Komponen visual statis sebagai pratinjau spasial RSGM terpilih.
/// Menggunakan Google Maps SDK dengan batasan interaksi pengguna (Read-Only Preview).
class HospitalMapPreview extends StatelessWidget {
  const HospitalMapPreview({super.key});

  // Koordinat default: Pusat Yogyakarta sebagai baseline instansiasi kamera
  static const LatLng _defaultCenter = LatLng(-7.7956, 110.3695);

  /// Membangun koleksi marker Google Maps secara reaktif dibatasi maksimal 6 entitas rumah sakit teratas
  Set<Marker> _buildPreviewMarkers(List hospitals) {
    return hospitals.take(6).map((h) {
      return Marker(
        markerId: MarkerId('preview_id_${h.id}'),
        position: LatLng(h.latitude, h.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: h.name),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HospitalController>();

    // Memastikan persistensi data awal terpenuhi
    if (controller.hospitals.isEmpty) {
      controller.fetchHospitals();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Layer 1: Google Map Viewport Terisolasi (Static Mode)
          Obx(
            () => GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
                zoom: 12.5,
              ),
              markers: _buildPreviewMarkers(controller.hospitals),
              
              // Nonaktifkan seluruh kontrol & gestur interaksi untuk menjaga sifat read-only
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomGesturesEnabled: false,
            ),
          ),

          // Layer 2: Overlay Gradasi untuk Keterbacaan Teks & Aksesibilitas Tombol
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              alignment: Alignment.bottomRight,
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Get.toNamed('/patient-hospital'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Lihat Lokasi RSGM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}