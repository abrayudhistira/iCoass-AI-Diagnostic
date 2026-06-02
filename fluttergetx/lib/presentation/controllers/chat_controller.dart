import 'package:fluttergetx/domain/entities/chat_entity.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class ChatController extends GetxController {
  final ChatRepository _repository;

  ChatController(this._repository);

  // Observable states
  var chatRooms = <ChatRoomEntity>[].obs;
  var currentMessages = <MessageEntity>[].obs;
  var queues = <ChatRoomEntity>[].obs;
  var isLoading = false.obs;
  var activeRoomId = 0.obs;

  @override
  // void onInit() {
  //   super.onInit();
  //   _repository.connectSocket();
  //   _listenToEvents();
  //   fetchChatRooms();
  //   fetchQueues();
  // }

  void onInit() {
  super.onInit();
  _repository.connectSocket();
  _listenToEvents();

  // Ambil data user dari AuthController untuk cek role
  final authController = Get.find<AuthController>();
  final role = authController.currentUser.value?.role;

  // Pasien & Admin sama-sama butuh list chat room yang sudah aktif
  fetchChatRooms();

  // Hanya admin yang boleh fetch seluruh antrean (mencegah 403)
  if (role == 'admin') {
    fetchQueues();
  }
}

  void _listenToEvents() {
    // Mendengarkan pesan masuk secara real-time
    _repository.onMessageReceived().listen((message) {
      if (message.roomId == activeRoomId.value) {
        currentMessages.add(message);
      }
      // Update pesan terakhir di daftar room
      _updateRoomLastMessage(message);
    });

    // Mendengarkan aktivasi chat (untuk pasien)
    _repository.onChatActivated().listen((data) {
      activeRoomId.value = data['roomId'];
      Get.snackbar("Chat Aktif", "Konsultasi Anda telah diterima oleh Admin");
      fetchMessages(data['roomId']);
    });
    // Listener khusus untuk antrian
    _repository.onQueueUpdated().listen((updatedQueues) {
      queues.assignAll(updatedQueues);
    });
  }

  // Future<void> fetchQueues() async {
  //   try {
  //     isLoading.value = true;
  //     var data = await _repository.getQueues();
  //     queues.assignAll(data);
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

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
      isLoading.value = true;
      var rooms = await _repository.getChatRooms();
      chatRooms.assignAll(rooms);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMessages(int roomId) async {
    try {
      activeRoomId.value = roomId;
      isLoading.value = true;
      _repository.joinRoom(roomId); // Socket join room
      var messages = await _repository.getMessages(roomId);
      currentMessages.assignAll(messages);
    } finally {
      isLoading.value = false;
    }
  }

  void sendMessage(int senderId, String text) {
    if (text.trim().isEmpty) return;
    _repository.sendMessage(senderId, activeRoomId.value, text);
  }

  void requestNewConsultation(int userId) {
    // LOCK: Jika sedang loading/proses, abaikan klik selanjutnya
    if (isLoading.value) return;

    // BUG FIX: Cek apakah user sudah memiliki antrean pending agar tidak double request
    // Mencegah antrean membludak karena multiple attempts.
    final bool hasPendingChat = chatRooms.any((room) => room.status == 'pending');

    if (hasPendingChat) {
      Get.snackbar(
        "Info Antrean", 
        "Anda sudah berada dalam antrean konsultasi.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Set loading ke true segera setelah klik valid pertama diterima
    isLoading.value = true;
    
    _repository.requestChat(userId);
    Get.snackbar("Antrean", "Permintaan konsultasi telah dikirim");

    // Refresh data setelah jeda singkat untuk sinkronisasi status terbaru dari server
    Future.delayed(const Duration(seconds: 2), () => fetchChatRooms());
  }

  void _updateRoomLastMessage(MessageEntity message) {
    int index = chatRooms.indexWhere((r) => r.id == message.roomId);
    if (index != -1) {
      // Logic untuk memperbarui preview pesan terakhir di list
      fetchChatRooms();
    }
  }

  void acceptChatQueue(int roomId, int adminId) {
    _repository.acceptChat(roomId, adminId);
    // Opsional: Langsung pindah ke chat page setelah sukses atau tunggu event chat_activated
    Get.snackbar("Sukses", "Anda telah mengambil antrean chat");
    fetchChatRooms(); // Refresh list chat aktif admin
  }

  ChatRoomEntity? get currentRoom {
  // Mencari di chatRooms atau di queues (siapa tahu admin baru saja accept)
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
