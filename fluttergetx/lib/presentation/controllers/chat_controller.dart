import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/domain/entities/chat_entity.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final ChatRepository _repository;

  ChatController(this._repository);

  var chatRooms = <ChatRoomEntity>[].obs;
  var currentMessages = <MessageEntity>[].obs;
  var queues = <ChatRoomEntity>[].obs;
  var isLoading = false.obs;
  var activeRoomId = 0.obs;

  // FIX: Tambahkan timestamp untuk debounce
  DateTime? _lastRequestTime;
  static const _debounceDuration = Duration(seconds: 3);

  @override
  void onInit() {
    super.onInit();
    _repository.connectSocket();
    _listenToEvents();

    final authController = Get.find<AuthController>();
    final role = authController.currentUser.value?.role;

    fetchChatRooms();

    if (role == 'admin') {
      fetchQueues();
    }
  }

  void _listenToEvents() {
    _repository.onMessageReceived().listen((message) {
      if (message.roomId == activeRoomId.value) {
        currentMessages.add(message);
      }
      _updateRoomLastMessage(message);
    });

    _repository.onChatActivated().listen((data) {
      activeRoomId.value = data['roomId'];
      Get.snackbar("Chat Aktif", "Konsultasi Anda telah diterima oleh Admin");
      fetchMessages(data['roomId']);
    });

    _repository.onQueueUpdated().listen((updatedQueues) {
      queues.assignAll(updatedQueues);
      // FIX: Refresh chatRooms ketika ada update queue
      fetchChatRooms();
    });

    _repository.onChatClosed().listen((roomId) {
      debugPrint('🔒 [CONTROLLER] Chat $roomId ditutup dari server');

      // FIX: Update status di chatRooms
      final index = chatRooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        chatRooms[index] = chatRooms[index].copyWith(status: 'closed');
      }

      // FIX: Refresh data untuk memastikan sinkron
      fetchChatRooms();

      if (activeRoomId.value == roomId) {
        Get.snackbar(
          "Sesi Ditutup",
          "Konsultasi telah diakhiri oleh admin",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }

  Future<void> fetchQueues() async {
    if (Get.find<AuthController>().currentUser.value?.role != 'admin') return;

    try {
      isLoading.value = true;
      var data = await _repository.getQueues();
      queues.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchChatRooms() async {
    try {
      var rooms = await _repository.getChatRooms();
      chatRooms.assignAll(rooms);
    } catch (e) {
      debugPrint('❌ [FETCH ROOMS ERROR] $e');
    }
  }

  Future<void> fetchMessages(int roomId) async {
    try {
      activeRoomId.value = roomId;
      isLoading.value = true;
      _repository.joinRoom(roomId);
      var messages = await _repository.getMessages(roomId);
      currentMessages.assignAll(messages);
    } finally {
      isLoading.value = false;
    }
  }

  void sendMessage(int senderId, String text) {
    if (text.trim().isEmpty) return;

    if (isRoomClosed) {
      Get.snackbar(
        "Sesi Ditutup",
        "Tidak dapat mengirim pesan karena sesi telah diakhiri",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _repository.sendMessage(senderId, activeRoomId.value, text);
  }

  // FIX: Enhanced requestNewConsultation dengan debounce & double-check
  // void requestNewConsultation(int userId) {
  //   // LOCK 1: Cek isLoading
  //   if (isLoading.value) {
  //     debugPrint('🔒 [LOCK] Request diblokir: sedang loading');
  //     return;
  //   }

  //   // LOCK 2: Debounce - cek apakah baru saja request dalam 3 detik terakhir
  //   final now = DateTime.now();
  //   if (_lastRequestTime != null &&
  //       now.difference(_lastRequestTime!) < _debounceDuration) {
  //     debugPrint('🔒 [DEBOUNCE] Request diblokir: terlalu cepat');
  //     Get.snackbar(
  //       "Tunggu Sebentar",
  //       "Mohon tunggu sebelum mencoba lagi",
  //       snackPosition: SnackPosition.BOTTOM,
  //       duration: const Duration(seconds: 2),
  //     );
  //     return;
  //   }

  //   // LOCK 3: Double-check dari data terbaru (fetch ulang)
  //   // Ini memastikan data tidak stale
  //   _checkAndRequest(userId);
  // }
  void requestNewConsultation(int userId) {
    if (isLoading.value) {
      debugPrint('🔒 [LOCK] Request diblokir: sedang loading');
      return;
    }

    final now = DateTime.now();
    if (_lastRequestTime != null &&
        now.difference(_lastRequestTime!) < _debounceDuration) {
      debugPrint('🔒 [DEBOUNCE] Request diblokir: terlalu cepat');
      Get.snackbar(
        "Tunggu Sebentar",
        "Mohon tunggu sebelum mencoba lagi",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    _lastRequestTime = now;

    // Request dengan callback
    _repository.requestChat(
      userId,
      onSuccess: () {
        Get.snackbar(
          "Antrean",
          "Permintaan konsultasi sedang dikirim",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.9),
          colorText: Colors.white,
        );

        // Refresh chat rooms
        fetchChatRooms();

        isLoading.value = false;
      },
      onError: (errorMessage) {
        Get.snackbar(
          "Gagal",
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.9),
          colorText: Colors.white,
        );

        // Refresh chat rooms untuk update state
        fetchChatRooms();

        isLoading.value = false;
      },
    );

    // Auto-reset loading setelah 5 detik (timeout)
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading.value) {
        isLoading.value = false;
      }
    });
  }

  Future<void> _checkAndRequest(int userId) async {
    try {
      isLoading.value = true;
      _lastRequestTime = DateTime.now();

      // Fetch data terbaru dari server
      await fetchChatRooms();

      // Cek apakah ada chat aktif (pending atau active)
      final activeChats = chatRooms
          .where((room) => room.status == 'pending' || room.status == 'active')
          .toList();

      if (activeChats.isNotEmpty) {
        final existingChat = activeChats.first;
        String title, message;

        if (existingChat.status == 'pending') {
          title = "Masih dalam Antrean";
          message =
              "Permintaan konsultasi Anda masih menunggu persetujuan admin.";
        } else {
          title = "Sedang Berlangsung";
          message = "Anda sudah memiliki sesi konsultasi yang sedang berjalan.";
        }

        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning.withOpacity(0.9),
          colorText: Colors.white,
        );

        isLoading.value = false;
        return;
      }

      // Jika tidak ada chat aktif, lanjutkan request
      _repository.requestChat(userId);
      Get.snackbar(
        "Antrean",
        "Permintaan konsultasi telah dikirim",
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh data setelah request
      Future.delayed(const Duration(seconds: 2), () {
        fetchChatRooms();
        isLoading.value = false;
      });
    } catch (e) {
      debugPrint('❌ [REQUEST ERROR] $e');
      isLoading.value = false;
    }
  }

  Future<void> closeChatSession(int roomId) async {
    try {
      isLoading.value = true;
      await _repository.closeChat(roomId);

      // Update status lokal
      final index = chatRooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        chatRooms[index] = chatRooms[index].copyWith(status: 'closed');
      }

      Get.snackbar(
        "Sesi Ditutup",
        "Konsultasi telah diakhiri",
        snackPosition: SnackPosition.BOTTOM,
      );

      // FIX: Refresh data setelah close
      await fetchChatRooms();
    } catch (e) {
      Get.snackbar("Error", "Gagal menutup sesi: $e");
    } finally {
      isLoading.value = false;
    }
  }

  bool get isRoomClosed {
    final room = currentRoom;
    return room?.status == 'closed' || room?.status == 'cancelled';
  }

  void _updateRoomLastMessage(MessageEntity message) {
    fetchChatRooms();
  }

  // void acceptChatQueue(int roomId, int adminId) {
  //   _repository.acceptChat(roomId, adminId);
  //   Get.snackbar("Sukses", "Anda telah mengambil antrean chat");
  //   fetchChatRooms();
  // }
  Future<void> acceptChatQueue(int roomId, int adminId) async {
  try {
    // Optimistic update: hapus dari list dulu
    queues.removeWhere((room) => room.id == roomId);
    
    _repository.acceptChat(roomId, adminId);
    
    Get.snackbar(
      "Sukses", 
      "Anda telah mengambil antrean chat",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success.withOpacity(0.1),
      colorText: AppColors.success,
    );
    
    // Refresh kedua list
    await Future.wait([
      fetchChatRooms(),
      fetchQueues(),
    ]);
  } catch (e) {
    debugPrint('❌ [ACCEPT ERROR] $e');
    Get.snackbar(
      "Error", 
      "Gagal mengambil antrian",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error.withOpacity(0.1),
      colorText: AppColors.error,
    );
    // Rollback: fetch ulang queues
    await fetchQueues();
  }
}

  ChatRoomEntity? get currentRoom {
    try {
      return chatRooms.firstWhere((room) => room.id == activeRoomId.value);
    } catch (_) {
      try {
        return queues.firstWhere((room) => room.id == activeRoomId.value);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  void onClose() {
    _repository.disconnectSocket();
    super.onClose();
  }
}
