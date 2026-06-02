import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/chat_room_card.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/chat_skeleton_card.dart';
import 'package:get/get.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:lottie/lottie.dart';
import '../../../controllers/chat_controller.dart';
import '../../../controllers/auth_controller.dart';

class PatientChatListPage extends GetView<ChatController> {
  const PatientChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final int userId =
        Get.find<AuthController>().currentUser.value?.id ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(userId),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.chatRooms.isEmpty) {
                return _buildLoadingState();
              }
              if (controller.chatRooms.isEmpty) {
                return _buildEmptyState(userId);
              }
              return _buildChatList(userId);
            }),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(int userId) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konsultasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Chat dengan dokter gigi kami',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        controller.requestNewConsultation(userId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(2, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() {
                final rooms = controller.chatRooms;
                final activeCount =
                    rooms.where((r) => r.status != 'pending').length;
                final pendingCount =
                    rooms.where((r) => r.status == 'pending').length;
                return Row(
                  children: [
                    _statChip('$activeCount', 'Aktif',
                        Icons.chat_rounded, Colors.white),
                    const SizedBox(width: 10),
                    _statChip('$pendingCount', 'Menunggu',
                        Icons.timer_rounded, Colors.white70),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(
      String count, String label, IconData icon, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── List + CustomRefreshIndicator ────────────────────────────────────────
  Widget _buildChatList(int userId) {
    return CustomRefreshIndicator(
      onRefresh: () => controller.fetchChatRooms(),
      builder: (context, child, indicatorController) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            if (!indicatorController.isIdle)
              Positioned(
                top: 25.0 * indicatorController.value,
                child: SizedBox(
                  height: 60,
                  child: Lottie.asset(
                    'assets/lottie/loading_animation.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(0, 80.0 * indicatorController.value),
              child: child,
            ),
          ],
        );
      },
      child: Obx(() => ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: controller.chatRooms.length,
            itemBuilder: (context, index) {
              final room = controller.chatRooms[index];
              final bool isPending = room.status == 'pending';
              return ChatRoomCard(          // ← shared widget
                room: room,
                isPending: isPending,
                showPatient: false,        // patient view
                onTap: isPending
                    ? () => Get.snackbar(
                          'Mohon Tunggu',
                          'Admin belum menerima permintaan Anda',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor:
                              AppColors.warning.withOpacity(0.9),
                          colorText: Colors.white,
                          borderRadius: 14,
                          margin: const EdgeInsets.all(16),
                          icon: const Icon(Icons.timer_rounded,
                              color: Colors.white),
                        )
                    : () {
                        controller.fetchMessages(room.id);
                        Get.toNamed('/chat-detail');
                      },
              );
            },
          )),
    );
  }

  // ── Loading skeleton ─────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: 4,
      itemBuilder: (_, __) => const ChatSkeletonCard(), // ← shared widget
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(int userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada konsultasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai konsultasi baru dengan\ndokter gigi kami sekarang.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.textGrey, height: 1.6),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => controller.requestNewConsultation(userId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mulai Konsultasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}