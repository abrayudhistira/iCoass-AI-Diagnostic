import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:get/get.dart';

/// Widget kartu room chat — dipakai di PatientChatListPage & AdminChatListPage.
///
/// [room]        — objek chat room (dynamic, sesuaikan dengan entity kamu)
/// [isPending]   — status pending/aktif
/// [onTap]       — aksi saat card di-tap
/// [showPatient] — jika true, tampilkan nama pasien (untuk tampilan admin)
class ChatRoomCard extends StatelessWidget {
  final dynamic room;
  final bool isPending;
  final VoidCallback onTap;
  final bool showPatient; // true = admin view, false = patient view

  const ChatRoomCard({
    super.key,
    required this.room,
    required this.isPending,
    required this.onTap,
    this.showPatient = false,
  });

  // Helper: cek apakah room sudah ditutup
  bool get _isClosed => room.status == 'closed';

  @override
  Widget build(BuildContext context) {
    final String title = _getTitle();
    final String subtitle = _getSubtitle();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Closed rooms lebih pudar
          color: _isClosed ? Colors.grey[100] : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _getBorderColor(),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              // Shadow lebih subtle untuk closed
              color: Colors.black.withOpacity(_isClosed ? 0.02 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            _buildAvatar(),
            const SizedBox(width: 14),

            // ── Info ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _isClosed
                                ? FontWeight.w500
                                : (isPending
                                    ? FontWeight.w500
                                    : FontWeight.w700),
                            // Closed text lebih pudar
                            color: _isClosed
                                ? Colors.grey[600]
                                : AppColors.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status badge
                      _StatusBadge(
                        isPending: isPending,
                        isClosed: _isClosed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      // Closed subtitle lebih pudar
                      color: _isClosed ? Colors.grey[500] : AppColors.textGrey,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Trailing ──────────────────────────────────────────────────
            _buildTrailing(),
          ],
        ),
      ),
    );
  }

  // ── Helper Methods ─────────────────────────────────────────────────────

  String _getTitle() {
    if (_isClosed) {
      return showPatient
          ? (room.patientName ?? 'Pasien')
          : (room.opponentName ?? 'Admin iCoass');
    }
    
    if (isPending) {
      return showPatient
          ? (room.patientName ?? 'Pasien')
          : 'Menunggu Admin...';
    }
    
    return showPatient
        ? (room.patientName ?? 'Pasien')
        : (room.opponentName ?? 'Admin iCoass');
  }

  String _getSubtitle() {
    if (_isClosed) {
      return 'Sesi konsultasi telah ditutup';
    }
    
    if (isPending) {
      return showPatient
          ? 'Menunggu konfirmasi'
          : 'Permintaan Anda sedang dalam antrean';
    }
    
    return room.lastMessage ?? 'Klik untuk memulai chat';
  }

  Color _getBorderColor() {
    if (_isClosed) {
      return Colors.grey.withOpacity(0.2);
    }
    return isPending
        ? AppColors.warning.withOpacity(0.2)
        : AppColors.primary.withOpacity(0.1);
  }

  Widget _buildAvatar() {
    if (_isClosed) {
      // Avatar untuk closed: abu-abu dengan icon lock
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.lock_outline_rounded,
          color: Colors.grey,
          size: 24,
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isPending
            ? AppColors.warning.withOpacity(0.12)
            : AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isPending
            ? Icons.timer_rounded
            : (showPatient
                ? Icons.person_rounded
                : Icons.local_hospital_rounded),
        color: isPending ? AppColors.warning : AppColors.success,
        size: 24,
      ),
    );
  }

  Widget _buildTrailing() {
    if (_isClosed) {
      // Trailing untuk closed: icon lock kecil
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.lock_outline_rounded,
          color: Colors.grey,
          size: 16,
        ),
      );
    }

    if (isPending) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.warning,
        ),
      );
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.primary,
        size: 18,
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isPending;
  final bool isClosed;

  const _StatusBadge({
    required this.isPending,
    this.isClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    // Tentukan warna & text berdasarkan status
    Color bgColor;
    Color textColor;
    String label;
    IconData? icon;

    if (isClosed) {
      bgColor = Colors.grey.withOpacity(0.15);
      textColor = Colors.grey[700]!;
      label = 'Ditutup';
      icon = Icons.lock_outline;
    } else if (isPending) {
      bgColor = AppColors.warning.withOpacity(0.12);
      textColor = AppColors.warning;
      label = 'Pending';
      icon = null;
    } else {
      bgColor = AppColors.success.withOpacity(0.12);
      textColor = AppColors.success;
      label = 'Aktif';
      icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}