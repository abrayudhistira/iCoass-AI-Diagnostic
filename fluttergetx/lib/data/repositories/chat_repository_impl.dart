import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Untuk debugPrint
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio;
  late IO.Socket _socket;
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = dotenv.env['API_URL'] ?? '';

  final _messageStreamController = StreamController<MessageEntity>.broadcast();
  final _queueStreamController = StreamController<List<ChatRoomEntity>>.broadcast();
  final _chatActivatedController = StreamController<Map<String, dynamic>>.broadcast();

  ChatRepositoryImpl(this._dio);

  @override
  void connectSocket() async {
    try {
      String? token = await _storage.read(key: 'access_token');
      debugPrint('🔌 [SOCKET] Menghubungkan ke: ${_baseUrl.replaceAll('api', '')}');
      
      _socket = IO.io(_baseUrl.replaceAll('api', ''), 
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build());

      _socket.onConnect((_) => debugPrint('✅ [SOCKET] Connected'));
      _socket.onConnectError((data) => debugPrint('🚨 [SOCKET] Connect Error: $data'));
      _socket.onError((data) => debugPrint('🚨 [SOCKET] Error: $data'));

      _socket.on('receive_message', (data) {
        debugPrint('📩 [SOCKET] Pesan baru diterima: $data');
        _messageStreamController.add(MessageModel.fromJson(data));
      });

      _socket.on('queue_updated', (data) {
        debugPrint('📊 [SOCKET] Antrean diupdate: $data');
        if (data is List) {
          final rooms = data.map((e) => ChatRoomModel.fromJson(e)).toList();
          _queueStreamController.add(rooms);
        }
      });

      _socket.on('chat_activated', (data) {
        debugPrint('🚀 [SOCKET] Chat Aktif: $data');
        _chatActivatedController.add(Map<String, dynamic>.from(data));
      });
    } catch (e) {
      debugPrint('🚨 [SOCKET EXCEPTION] $e');
    }
  }

  @override
  Future<List<ChatRoomEntity>> getChatRooms() async {
    try {
      debugPrint('📡 [API] Fetch Chat Rooms...');
      final response = await _dio.get('chat/rooms');
      debugPrint('✅ [API] Chat Rooms Success: ${response.statusCode}');
      return (response.data['data'] as List).map((e) => ChatRoomModel.fromJson(e)).toList();
    } catch (e) {
      _logError('getChatRooms', e);
      rethrow;
    }
  }

  @override
  Future<List<ChatRoomEntity>> getQueues() async {
    try {
      debugPrint('📡 [API] Fetch Queues...');
      final response = await _dio.get('chat/queues');
      return (response.data['data'] as List).map((e) => ChatRoomModel.fromJson(e)).toList();
    } catch (e) {
      _logError('getQueues', e);
      rethrow;
    }
  }

  @override
  Future<List<MessageEntity>> getMessages(int roomId) async {
    try {
      debugPrint('📡 [API] Fetch Messages for Room ID: $roomId');
      final response = await _dio.get('chat/messages/$roomId');
      
      debugPrint('✅ [API] Response Data: ${response.data}');

      if (response.data['data'] == null) {
        debugPrint('⚠️ [API] Warning: Data messages null');
        return [];
      }

      return (response.data['data'] as List)
          .map((e) => MessageModel.fromJson(e))
          .toList();
    } catch (e) {
      _logError('getMessages', e);
      rethrow;
    }
  }

  // Helper function untuk logging error Dio secara mendetail
  void _logError(String methodName, dynamic e) {
    if (e is DioException) {
      debugPrint('🚨 [API ERROR] Method: $methodName');
      debugPrint('🚨 [STATUS CODE] : ${e.response?.statusCode}');
      debugPrint('🚨 [ERROR DATA]  : ${e.response?.data}');
      debugPrint('🚨 [REQ PATH]    : ${e.requestOptions.path}');
    } else {
      debugPrint('🚨 [UNKNOWN ERROR] $methodName: $e');
    }
  }

  @override
  void sendMessage(int senderId, int roomId, String message) {
    debugPrint('📤 [SOCKET] Mengirim pesan ke Room $roomId');
    _socket.emit('send_message', {
      'sender_id': senderId,
      'room_id': roomId,
      'message_text': message,
    });
  }

  @override
  void acceptChat(int roomId, int adminId) {
    debugPrint('📥 [SOCKET] Admin $adminId mengambil Chat $roomId');
    _socket.emit('accept_chat', {'roomId': roomId, 'adminId': adminId});
  }

  @override
  void joinRoom(int roomId) {
    debugPrint('🔑 [SOCKET] Joining Room: $roomId');
    _socket.emit('join_existing_room', roomId);
  }

  @override
  void requestChat(int userId) {
    debugPrint('🎫 [SOCKET] Request Chat baru untuk User: $userId');
    _socket.emit('request_chat', {'userId': userId});
  }

  @override
  Stream<MessageEntity> onMessageReceived() => _messageStreamController.stream;
  @override
  Stream<List<ChatRoomEntity>> onQueueUpdated() => _queueStreamController.stream;
  @override
  Stream<Map<String, dynamic>> onChatActivated() => _chatActivatedController.stream;
  @override
  void disconnectSocket() => _socket.disconnect();
}
