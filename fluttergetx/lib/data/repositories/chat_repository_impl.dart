import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttergetx/data/services/auth_service.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio;
  late IO.Socket _socket;
  final AuthService _authService; // Inject AuthService
  final String _baseUrl = dotenv.env['API_URL'] ?? '';

  final _messageStreamController = StreamController<MessageEntity>.broadcast();
  final _queueStreamController =
      StreamController<List<ChatRoomEntity>>.broadcast();
  final _chatActivatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatClosedController = StreamController<int>.broadcast(); // ← TAMBAHAN

  ChatRepositoryImpl(this._dio, this._authService);

  Failure _mapError(DioException e, String defaultMessage) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final code = data['code']?.toString();
      final message = data['message']?.toString() ?? defaultMessage;
      final details = data['details'] as Map<String, dynamic>?;

      if (statusCode == 429) {
        final resetHeader = e.response?.headers.value('RateLimit-Reset');
        int? retryAfter;
        if (resetHeader != null) {
          final resetTime = int.tryParse(resetHeader);
          if (resetTime != null) {
            retryAfter = (resetTime - DateTime.now().millisecondsSinceEpoch / 1000).ceil();
            retryAfter = retryAfter! > 0 ? retryAfter : 1;
          }
        }
        return RateLimitFailure(
          message: message,
          retryAfterSeconds: retryAfter,
          details: details,
          statusCode: statusCode,
        );
      }

      switch (code) {
        case 'ERR_VALIDATION':
          return ValidationFailure(
            message: message,
            field: details?['field']?.toString(),
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_UNAUTHORIZED':
          return UnauthorizedFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_FORBIDDEN':
          return ForbiddenFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_NOT_FOUND':
          return NotFoundFailure(
            message: message,
            resource: details?['field']?.toString(),
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_CONFLICT':
          return ConflictFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_INTERNAL':
          return ServerFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        default:
          return ServerFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
      }
    } else if (data is String) {
      if (data.contains('<!DOCTYPE') || data.contains('<html')) {
        if (statusCode == 404) {
          return NotFoundFailure(message: 'Endpoint API tidak ditemukan (404)');
        }
        if (statusCode == 500) {
          return ServerFailure(message: 'Kesalahan internal server (500)');
        }
        return ServerFailure(message: 'Server mengembalikan respon tidak valid (HTML)', statusCode: statusCode);
      }
      return ServerFailure(message: data, statusCode: statusCode);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure();
      case DioExceptionType.connectionError:
        return NetworkFailure();
      case DioExceptionType.cancel:
        return UnknownFailure(message: 'Request dibatalkan');
      case DioExceptionType.badResponse:
        return ServerFailure(message: defaultMessage, statusCode: statusCode);
      case DioExceptionType.unknown:
      default:
        return UnknownFailure(message: '$defaultMessage (${e.type.name}): ${e.message}');
    }
  }

  Failure _createFailureFromResponse(
    String? code,
    String message,
    Map<String, dynamic>? details,
    int? statusCode,
  ) {
    switch (code) {
      case 'ERR_VALIDATION':
        return ValidationFailure(
          message: message,
          field: details?['field']?.toString(),
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_UNAUTHORIZED':
        return UnauthorizedFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_FORBIDDEN':
        return ForbiddenFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_NOT_FOUND':
        return NotFoundFailure(
          message: message,
          resource: details?['field']?.toString(),
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_CONFLICT':
        return ConflictFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_INTERNAL':
        return ServerFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      default:
        return ServerFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
    }
  }

  @override
  void connectSocket() async {
    try {
      String? token = await _authService.getAccessToken(); // Use AuthService
      debugPrint(
        '🔌 [SOCKET] Menghubungkan ke: ${_baseUrl.replaceAll('api', '')}',
      );

      _socket = IO.io(
        _baseUrl.replaceAll('api', ''),
        IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders({
          'Authorization': 'Bearer $token',
        }).build(),
      );

      _socket.onConnect((_) => debugPrint('✅ [SOCKET] Connected'));
      _socket.onConnectError(
        (data) => debugPrint('🚨 [SOCKET] Connect Error: $data'),
      );
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

      // ← TAMBAHAN: Listener untuk chat_closed
      _socket.on('chat_closed', (data) {
        debugPrint('🔒 [SOCKET] Chat ditutup: $data');
        if (data is Map && data['roomId'] != null) {
          _chatClosedController.add(data['roomId'] as int);
        } else if (data is int) {
          _chatClosedController.add(data);
        }
      });
    } catch (e) {
      debugPrint('🚨 [SOCKET EXCEPTION] $e');
    }
  }

  @override
  Future<Either<Failure, List<ChatRoomEntity>>> getChatRooms() async {
    try {
      debugPrint('📡 [API] Fetch Chat Rooms...');
      final response = await _dio.get('chat/rooms');
      debugPrint('✅ [API] Chat Rooms Success: ${response.statusCode}');
      if (response.data['success'] == true) {
        return Right((response.data['data'] as List)
            .map((e) => ChatRoomModel.fromJson(e))
            .toList());
      }
      final code = response.data['code']?.toString();
      final message = response.data['message']?.toString() ?? 'Gagal mengambil chat rooms';
      final details = response.data['details'] as Map<String, dynamic>?;
      return Left(_createFailureFromResponse(code, message, details, response.statusCode));
    } on DioException catch (e) {
      _logError('getChatRooms', e);
      return Left(_mapError(e, 'Gagal mengambil chat rooms'));
    } catch (e) {
      _logError('getChatRooms', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatRoomEntity>>> getQueues() async {
    try {
      debugPrint('📡 [API] Fetch Queues...');
      final response = await _dio.get('chat/queues');
      if (response.data['success'] == true) {
        return Right((response.data['data'] as List)
            .map((e) => ChatRoomModel.fromJson(e))
            .toList());
      }
      final code = response.data['code']?.toString();
      final message = response.data['message']?.toString() ?? 'Gagal mengambil antrean';
      final details = response.data['details'] as Map<String, dynamic>?;
      return Left(_createFailureFromResponse(code, message, details, response.statusCode));
    } on DioException catch (e) {
      _logError('getQueues', e);
      return Left(_mapError(e, 'Gagal mengambil antrean'));
    } catch (e) {
      _logError('getQueues', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages(int roomId) async {
    try {
      debugPrint('📡 [API] Fetch Messages for Room ID: $roomId');
      final response = await _dio.get('chat/messages/$roomId');

      debugPrint('✅ [API] Response Data: ${response.data}');

      if (response.data['data'] == null) {
        debugPrint('⚠️ [API] Warning: Data messages null');
        return Right([]);
      }

      if (response.data['success'] == true) {
        return Right((response.data['data'] as List)
            .map((e) => MessageModel.fromJson(e))
            .toList());
      }
      final code = response.data['code']?.toString();
      final message = response.data['message']?.toString() ?? 'Gagal mengambil pesan';
      final details = response.data['details'] as Map<String, dynamic>?;
      return Left(_createFailureFromResponse(code, message, details, response.statusCode));
    } on DioException catch (e) {
      _logError('getMessages', e);
      return Left(_mapError(e, 'Gagal mengambil pesan'));
    } catch (e) {
      _logError('getMessages', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ← TAMBAHAN: Close chat session
  @override
  Future<Either<Failure, void>> closeChat(int roomId) async {
    try {
      debugPrint('🔒 [API] Closing chat room: $roomId');
      final response = await _dio.post('chat/close/$roomId');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          debugPrint('✅ [API] Chat room $roomId berhasil ditutup');
          return const Right(null);
        }
        final code = response.data['code']?.toString();
        final message = response.data['message']?.toString() ?? 'Gagal menutup sesi';
        final details = response.data['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Gagal menutup sesi: Status ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      _logError('closeChat', e);
      return Left(_mapError(e, 'Gagal menutup sesi'));
    } catch (e) {
      _logError('closeChat', e);
      return Left(UnknownFailure(message: e.toString()));
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
  Future<Either<Failure, void>> requestChat(int userId) async {
    try {
      debugPrint('🎫 [SOCKET] Request Chat baru untuk User: $userId');
      final completer = Completer<Either<Failure, void>>();

      late void Function(dynamic) errorHandler;
      late void Function(dynamic) successHandler;

      successHandler = (dynamic data) {
        debugPrint('✅ [SOCKET] Queue created: $data');
        completer.complete(const Right(null));
        _socket.off('queue_created', successHandler);
        _socket.off('error_response', errorHandler);
      };

      errorHandler = (dynamic data) {
        debugPrint('🚨 [SOCKET ERROR] $data');
        String message = 'Terjadi kesalahan tidak diketahui';
        String? code;
        if (data is Map) {
          message = data['message'] ?? message;
          code = data['code']?.toString();
        }
        final details = data is Map ? data['details'] as Map<String, dynamic>? : null;
        completer.complete(Left(_createFailureFromResponse(code, message, details, null)));
        _socket.off('queue_created', successHandler);
        _socket.off('error_response', errorHandler);
      };

      _socket.once('queue_created', successHandler);
      _socket.once('error_response', errorHandler);

      _socket.emit('request_chat', {'userId': userId});

      return completer.future;
    } catch (e) {
      _logError('requestChat', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<MessageEntity> onMessageReceived() => _messageStreamController.stream;
  @override
  Stream<List<ChatRoomEntity>> onQueueUpdated() =>
      _queueStreamController.stream;
  @override
  Stream<Map<String, dynamic>> onChatActivated() =>
      _chatActivatedController.stream;
  @override
  Stream<int> onChatClosed() => _chatClosedController.stream; // ← TAMBAHAN

  @override
  void disconnectSocket() {
    _socket.disconnect();
    _messageStreamController.close();
    _queueStreamController.close();
    _chatActivatedController.close();
    _chatClosedController.close(); // ← TAMBAHAN
  }
}