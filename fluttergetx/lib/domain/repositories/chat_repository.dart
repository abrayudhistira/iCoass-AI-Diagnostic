import '../entities/chat_entity.dart';

abstract class ChatRepository {
  // REST API
  Future<List<ChatRoomEntity>> getChatRooms();
  Future<List<MessageEntity>> getMessages(int roomId);
  Future<List<ChatRoomEntity>> getQueues(); // Spesifik untuk Admin
  Future<void> closeChat(int roomId); // ← TAMBAHAN: Close chat session

  // Socket Actions
  void connectSocket();
  void disconnectSocket();
  void joinRoom(int roomId);
  void sendMessage(int senderId, int roomId, String message);
  // void requestChat(int userId); // User memulai antrian
  void requestChat(int userId, {Function()? onSuccess, Function(String)? onError});
  void acceptChat(int roomId, int adminId); // Admin mengambil antrian

  // Streams
  Stream<MessageEntity> onMessageReceived();
  Stream<List<ChatRoomEntity>> onQueueUpdated(); // Stream daftar antrian terbaru
  Stream<Map<String, dynamic>> onChatActivated(); // Notifikasi saat chat aktif
  Stream<int> onChatClosed(); // ← TAMBAHAN: Stream saat chat ditutup (roomId)
}