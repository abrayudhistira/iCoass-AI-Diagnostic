import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/colors.dart';
import '../../../controllers/hospital_controller.dart';

class HospitalMapPreview extends StatelessWidget {
  const HospitalMapPreview({super.key});

  static const LatLng _defaultCenter = LatLng(-7.7956, 110.3695);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HospitalController>();

    // Pastikan data hospital sudah di-fetch (aman dipanggil berkali-kali
    // kalau controller kamu sudah handle debounce/loading guard)
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
          Obx(
            () => IgnorePointer(
              // Read-only: user tidak bisa geser/zoom di preview
              ignoring: true,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _defaultCenter,
                  initialZoom: 13.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.icoass.app',
                    errorTileCallback: (tile, error, stackTrace) {
                      debugPrint('[MAP PREVIEW] Tile gagal load: $error');
                    },
                  ),
                  MarkerLayer(
                    markers: controller.hospitals.take(6).map((h) {
                      return Marker(
                        point: LatLng(h.latitude, h.longitude),
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          // Overlay gradasi tipis biar tombol kebaca
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
                  colors: [Colors.black.withOpacity(0.35), Colors.transparent],
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
