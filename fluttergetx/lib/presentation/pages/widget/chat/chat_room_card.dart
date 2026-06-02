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

  @override
  Widget build(BuildContext context) {
    final String title = isPending
        ? (showPatient ? (room.patientName ?? 'Pasien') : 'Menunggu Admin...')
        : (showPatient
            ? (room.patientName ?? 'Pasien')
            : (room.opponentName ?? 'Admin iCoass'));

    final String subtitle = isPending
        ? (showPatient
            ? 'Menunggu konfirmasi'
            : 'Permintaan Anda sedang dalam antrean')
        : (room.lastMessage ?? 'Klik untuk memulai chat');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPending
                ? AppColors.warning.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            Container(
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
            ),
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
                            fontWeight: isPending
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status badge
                      _StatusBadge(isPending: isPending),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
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
            isPending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.warning,
                    ),
                  )
                : Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary, size: 18),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isPending;
  const _StatusBadge({required this.isPending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPending
            ? AppColors.warning.withOpacity(0.12)
            : AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isPending ? 'Pending' : 'Aktif',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPending ? AppColors.warning : AppColors.success,
        ),
      ),
    );
  }
}