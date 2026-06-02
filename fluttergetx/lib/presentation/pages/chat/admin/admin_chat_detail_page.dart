import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/chat_date_divider.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/message_bubble.dart';
import 'package:get/get.dart';
import '../../../controllers/chat_controller.dart';
import '../../../controllers/auth_controller.dart';

class AdminChatDetailPage extends StatefulWidget {
  const AdminChatDetailPage({super.key});

  @override
  State<AdminChatDetailPage> createState() => _AdminChatDetailPageState();
}

class _AdminChatDetailPageState extends State<AdminChatDetailPage> {
  final ChatController controller     = Get.find<ChatController>();
  final TextEditingController _msgCtrl  = TextEditingController();
  final ScrollController _scrollCtrl   = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final typing = _msgCtrl.text.isNotEmpty;
      if (typing != _isTyping) setState(() => _isTyping = typing);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(int myId) {
    final text = _msgCtrl.text.trim();
    if (text.isNotEmpty) {
      controller.sendMessage(myId, text);
      _msgCtrl.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final int myId =
        Get.find<AuthController>().currentUser.value?.id ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.currentMessages.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary));
              }

              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToBottom());

              if (controller.currentMessages.isEmpty) {
                return _buildEmptyChat();
              }

              return ListView.builder(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: controller.currentMessages.length,
                itemBuilder: (context, index) {
                  final msg = controller.currentMessages[index];
                  final bool isMe = msg.senderId == myId;
                  final showDate = index == 0 ||
                      !_isSameDay(
                        controller.currentMessages[index - 1].createdAt,
                        msg.createdAt,
                      );
                  return Column(
                    children: [
                      if (showDate)
                        ChatDateDivider(date: msg.createdAt), // ← shared
                      MessageBubble(msg: msg, isMe: isMe),   // ← shared
                    ],
                  );
                },
              );
            }),
          ),
          _buildInputBar(myId),
        ],
      ),
    );
  }

  // ── Header dengan info pasien + tombol diagnosa ─────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Row(
            children: [
              // Back
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar pasien
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              // Nama + label pasien
              Expanded(
                child: Obx(() {
                  final room = controller.currentRoom;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room?.patientName ?? 'Pasien',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Pasien',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              // Tombol lihat diagnosa pasien
              GestureDetector(
                onTap: () {
                  // Navigasi ke detail diagnosa pasien
                  // Get.toNamed('/admin-patient-diagnosis');
                  Get.snackbar(
                    'Info Diagnosa',
                    'Fitur lihat diagnosa pasien',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.primary.withOpacity(0.9),
                    colorText: Colors.white,
                    borderRadius: 14,
                    margin: const EdgeInsets.all(16),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medical_information_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty chat ───────────────────────────────────────────────────────────
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.waving_hand_rounded,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          const Text(
            'Mulai percakapan!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Balas pesan pasien untuk memulai.',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────────
  Widget _buildInputBar(int myId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isTyping
                        ? AppColors.primary.withOpacity(0.4)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textMain),
                  decoration: const InputDecoration(
                    hintText: 'Balas pesan pasien...',
                    hintStyle: TextStyle(
                        color: AppColors.textGrey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isTyping
                    ? AppColors.success     // ← admin pakai warna hijau
                    : AppColors.secondary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isTyping
                    ? [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: IconButton(
                onPressed:
                    _isTyping ? () => _sendMessage(myId) : null,
                icon: Icon(
                  Icons.send_rounded,
                  color: _isTyping
                      ? Colors.white
                      : AppColors.textGrey,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}