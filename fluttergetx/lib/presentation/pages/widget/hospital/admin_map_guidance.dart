import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';

/// [AdminMapGuidance] — Circular info button with popup for admin map guidance.
/// Shows info icon (i) when form is hidden. On tap, shows centered popup with guide.
/// Hidden completely when form is visible.
class AdminMapGuidance extends StatefulWidget {
  final bool isFormVisible;

  const AdminMapGuidance({
    super.key,
    required this.isFormVisible,
  });

  @override
  State<AdminMapGuidance> createState() => _AdminMapGuidanceState();
}

class _AdminMapGuidanceState extends State<AdminMapGuidance> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showPopup() {
    if (_overlayEntry != null || widget.isFormVisible) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _GuidancePopup(
        onDismiss: _removeOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onButtonTap() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showPopup();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide completely when form is visible
    if (widget.isFormVisible) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onButtonTap,
        borderRadius: BorderRadius.circular(20),
        customBorder: const CircleBorder(),
        splashColor: AppColors.primary.withValues(alpha: 0.2),
        highlightColor: AppColors.primary.withValues(alpha: 0.1),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Small centered popup widget showing the guidance text
class _GuidancePopup extends StatelessWidget {
  final VoidCallback onDismiss;

  const _GuidancePopup({
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full screen backdrop - dismiss on tap
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
        // Centered popup card
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Title
                  const Text(
                    "Cara Mendaftarkan RSGM",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Description
                  const Text(
                    "Tekan lama pada peta di lokasi yang diinginkan untuk memulai pendaftaran RSGM baru.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: onDismiss,
                      child: const Text(
                        "MENGERTI",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}