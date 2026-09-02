import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/chat_entity.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';
import 'package:fluttergetx/domain/usecases/chat/request_new_chat_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/get_chat_rooms_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/get_messages_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/get_queues_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/close_chat_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/accept_chat_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/send_message_usecase.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:fluttergetx/presentation/widgets/common_snackbar.dart';

class ChatController extends GetxController {
  final ChatRepository _repository;
  final RequestNewChatUseCase _requestNewChatUseCase;
  final GetChatRoomsUseCase _getChatRoomsUseCase;
  final GetMessagesUseCase _getMessagesUseCase;
  final GetQueuesUseCase _getQueuesUseCase;
  final CloseChatUseCase _closeChatUseCase;
  final AcceptChatUseCase _acceptChatUseCase;
  final SendMessageUseCase _sendMessageUseCase;

  ChatController({
    required ChatRepository repository,
    required RequestNewChatUseCase requestNewChatUseCase,
    required GetChatRoomsUseCase getChatRoomsUseCase,
    required GetMessagesUseCase getMessagesUseCase,
    required GetQueuesUseCase getQueuesUseCase,
    required CloseChatUseCase closeChatUseCase,
    required AcceptChatUseCase acceptChatUseCase,
    required SendMessageUseCase sendMessageUseCase,
  })  : _repository = repository,
        _requestNewChatUseCase = requestNewChatUseCase,
        _getChatRoomsUseCase = getChatRoomsUseCase,
        _getMessagesUseCase = getMessagesUseCase,
        _getQueuesUseCase = getQueuesUseCase,
        _closeChatUseCase = closeChatUseCase,
        _acceptChatUseCase = acceptChatUseCase,
        _sendMessageUseCase = sendMessageUseCase;

  /// Centralized failure handling with error code switching per backend spec
  String _handleFailure(Failure failure) {
    switch (failure.code) {
      case 'ERR_VALIDATION':
        if (failure is ValidationFailure && failure.field != null) {
          return '${failure.field}: ${failure.message}';
        }
        return failure.message;
      case 'ERR_UNAUTHORIZED':
        return 'Sesi kadaluwarsa, silakan login ulang';
      case 'ERR_FORBIDDEN':
        return 'Anda tidak memiliki akses untuk aksi ini';
      case 'ERR_NOT_FOUND':
        return failure.message;
      case 'ERR_CONFLICT':
        return failure.message;
      case 'ERR_INTERNAL':
        return 'Terjadi kesalahan server, coba lagi nanti';
      case 'CACHE_ERROR':
        return 'Gagal mengakses data lokal';
      case 'NETWORK_ERROR':
        return 'Tidak dapat terhubung ke server';
      case 'TIMEOUT_ERROR':
        return 'Koneksi timeout, coba lagi';
      default:
        return failure.message;
    }
  }

  var chatRooms = <ChatRoomEntity>[].obs;
  var currentMessages = <MessageEntity>[].obs;
  var queues = <ChatRoomEntity>[].obs;
  var isLoading = false.obs;
  var activeRoomId = 0.obs;

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
      AppSnackbar.info("Konsultasi Anda telah diterima oleh Admin", title: "Chat Aktif");
      fetchMessages(data['roomId']);
    });

    _repository.onQueueUpdated().listen((updatedQueues) {
      queues.assignAll(updatedQueues);
      fetchChatRooms();
    });

    _repository.onChatClosed().listen((roomId) {
      debugPrint('🔒 [CONTROLLER] Chat $roomId ditutup dari server');

      final index = chatRooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        chatRooms[index] = chatRooms[index].copyWith(status: 'closed');
      }

      fetchChatRooms();

      if (activeRoomId.value == roomId) {
        AppSnackbar.info("Konsultasi telah diakhiri oleh admin", title: "Sesi Ditutup");
      }
    });
  }

  Future<void> fetchQueues() async {
    if (Get.find<AuthController>().currentUser.value?.role != 'admin') return;

    try {
      isLoading.value = true;
      final result = await _getQueuesUseCase();
      result.fold(
        (failure) {
          final msg = _handleFailure(failure);
          debugPrint('🚨 [FETCH QUEUES ERROR] $msg');
          AppSnackbar.error(msg, title: "Error");
        },
        (data) {
          queues.assignAll(data);
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchChatRooms() async {
    try {
      final result = await _getChatRoomsUseCase();
      result.fold(
        (failure) {
          final msg = _handleFailure(failure);
          debugPrint('❌ [FETCH ROOMS ERROR] $msg');
        },
        (rooms) {
          chatRooms.assignAll(rooms);
        },
      );
    } catch (e) {
      debugPrint('❌ [FETCH ROOMS ERROR] $e');
    }
  }

  Future<void> fetchMessages(int roomId) async {
    try {
      activeRoomId.value = roomId;
      isLoading.value = true;
      _repository.joinRoom(roomId);
      final result = await _getMessagesUseCase(roomId);
      result.fold(
        (failure) {
          final msg = _handleFailure(failure);
          debugPrint('❌ [FETCH MESSAGES ERROR] $msg');
        },
        (messages) {
          currentMessages.assignAll(messages);
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  void sendMessage(int senderId, String text) {
    if (text.trim().isEmpty) return;

    if (isRoomClosed) {
      AppSnackbar.warning("Tidak dapat mengirim pesan karena sesi telah diakhiri", title: "Sesi Ditutup");
      return;
    }

    _sendMessageUseCase(senderId, activeRoomId.value, text);
  }

  void requestNewConsultation(int userId) async {
    if (isLoading.value) {
      debugPrint('🔒 [LOCK] Request diblokir: sedang loading');
      return;
    }

    final now = DateTime.now();
    if (_lastRequestTime != null &&
        now.difference(_lastRequestTime!) < _debounceDuration) {
      debugPrint('🔒 [DEBOUNCE] Request diblokir: terlalu cepat');
      AppSnackbar.warning("Mohon tunggu sebelum mencoba lagi", title: "Tunggu Sebentar");
      return;
    }

    isLoading.value = true;
    _lastRequestTime = now;

    final result = await _requestNewChatUseCase(userId);
    result.fold(
      (failure) {
        String errorMessage = "Terjadi kesalahan";
        if (failure is ServerFailure) {
          errorMessage = failure.message;
        }
        AppSnackbar.error(errorMessage, title: "Gagal");
      },
      (_) {
        AppSnackbar.success("Permintaan konsultasi sedang dikirim", title: "Antrean");
        fetchChatRooms();
      },
    );
    isLoading.value = false;
  }

  Future<void> closeChatSession(int roomId) async {
    try {
      isLoading.value = true;
      final result = await _closeChatUseCase(roomId);
      result.fold(
        (failure) {
          final msg = _handleFailure(failure);
          AppSnackbar.error(msg, title: "Error");
        },
        (_) {
          final index = chatRooms.indexWhere((r) => r.id == roomId);
          if (index != -1) {
            chatRooms[index] = chatRooms[index].copyWith(status: 'closed');
          }
          AppSnackbar.success("Konsultasi telah diakhiri", title: "Sesi Ditutup");
          fetchChatRooms();
        },
      );
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

  Future<void> acceptChatQueue(int roomId, int adminId) async {
    try {
      queues.removeWhere((room) => room.id == roomId);

      final result = await _acceptChatUseCase(roomId, adminId);
      result.fold(
        (failure) {
          final msg = _handleFailure(failure);
          debugPrint('❌ [ACCEPT ERROR] $msg');
          AppSnackbar.error(msg, title: "Error");
          fetchQueues();
        },
        (_) {
          AppSnackbar.success("Anda telah mengambil antrean chat", title: "Sukses");
          fetchChatRooms();
          fetchQueues();
        },
      );
    } catch (e) {
      debugPrint('❌ [ACCEPT ERROR] $e');
      AppSnackbar.error("Gagal mengambil antrian: $e", title: "Error");
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