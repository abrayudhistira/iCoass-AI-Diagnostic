import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:latlong2/latlong.dart';

/// [MapActionButtons] menyediakan tombol aksi peta yang mengambang.
/// Mencakup: kembali ke lokasi pengguna, zoom in, dan zoom out.
class MapActionButtons extends StatelessWidget {
  final MapController mapController;
  final LatLng userLocation;
  final bool isLocating;
  final VoidCallback onLocate;

  const MapActionButtons({
    super.key,
    required this.mapController,
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
          // Zoom In
          _MapActionButton(
            icon: Icons.add_rounded,
            tooltip: 'Zoom In',
            onTap: () {
              HapticFeedback.lightImpact();
              final currentZoom = mapController.camera.zoom;
              mapController.move(mapController.camera.center, currentZoom + 1);
            },
          ),
          const SizedBox(height: 8),
          // Zoom Out
          _MapActionButton(
            icon: Icons.remove_rounded,
            tooltip: 'Zoom Out',
            onTap: () {
              HapticFeedback.lightImpact();
              final currentZoom = mapController.camera.zoom;
              mapController.move(mapController.camera.center, currentZoom - 1);
            },
          ),
          const SizedBox(height: 16),
          // My Location Button
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

/// Tombol "My Location" dengan state loading dan animasi.
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
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      ),
                    )
                  : const Icon(
                      key: ValueKey('icon'),
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
