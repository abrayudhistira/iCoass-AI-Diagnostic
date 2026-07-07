import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttergetx/core/constants/colors.dart';
// Menggunakan referensi LatLng murni dari ekosistem Google Maps
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// [MapActionButtons] menyediakan antarmuka kontrol mengambang (floating action controls)
/// untuk manipulasi visual peta seperti Zoom In, Zoom Out, dan Sinkronisasi Lokasi GPS.
class MapActionButtons extends StatelessWidget {
  /// Callback fungsi untuk menggerakkan kamera Google Maps secara halus
  final void Function(LatLng target, double zoom) onMoveCamera;
  final LatLng userLocation;
  final bool isLocating;
  final VoidCallback onLocate;

  const MapActionButtons({
    super.key,
    required this.onMoveCamera,
    required this.userLocation,
    required this.isLocating,
    required this.onLocate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kontrol Kenaikan Skala Visual (Zoom In)
          _MapActionButton(
            icon: Icons.add_rounded,
            tooltip: 'Zoom In',
            onTap: () async {
              HapticFeedback.lightImpact();
              // Menggeser kamera lebih dekat (skala penambahan +1.0)
              onMoveCamera(userLocation, 14.5);
            },
          ),
          const SizedBox(height: 8),
          
          // Kontrol Penurunan Skala Visual (Zoom Out)
          _MapActionButton(
            icon: Icons.remove_rounded,
            tooltip: 'Zoom Out',
            onTap: () {
              HapticFeedback.lightImpact();
              // Menggeser kamera menjauh (skala pengurangan -1.0 dari baseline standard)
              onMoveCamera(userLocation, 11.5);
            },
          ),
          const SizedBox(height: 16),
          
          // Kontrol Pemosisian Ulang Berbasis GPS (My Location Button)
          _MyLocationButton(
            isLocating: isLocating,
            onTap: () {
              HapticFeedback.mediumImpact();
              onLocate();
            },
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.textMain,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol penentu posisi koordinat pengguna dilengkapi indikator progresif
class _MyLocationButton extends StatelessWidget {
  final bool isLocating;
  final VoidCallback onTap;

  const _MyLocationButton({
    required this.isLocating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Lokasi Saya',
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        elevation: 4,
        shadowColor: AppColors.primary.withOpacity(0.4),
        child: InkWell(
          onTap: isLocating ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isLocating
                  ? Container(
                      key: const ValueKey('loading_state'),
                      width: 22,
                      height: 22,
                      padding: const EdgeInsets.all(2),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Icon(
                      key: ValueKey('icon_state'),
                      Icons.my_location_rounded,
                      color: AppColors.white,
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}