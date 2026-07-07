import 'package:equatable/equatable.dart';

class ChatRoomEntity extends Equatable {
  final int id;
  final int userId;
  final int? adminId;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final String? opponentName;
  final String status; // 'pending', 'active', 'closed'

  const ChatRoomEntity({
    required this.id,
    required this.userId,
    this.adminId,
    this.lastMessage,
    required this.lastMessageTime,
    this.opponentName,
    required this.status,
  });

  String get patientName => opponentName ?? 'Pasien';

  // ← TAMBAHAN: copyWith method
  ChatRoomEntity copyWith({
    int? id,
    int? userId,
    int? adminId,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? opponentName,
    String? status,
  }) {
    return ChatRoomEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      opponentName: opponentName ?? this.opponentName,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, userId, adminId, lastMessage, lastMessageTime, status];
}

class MessageEntity extends Equatable {
  final int id;
  final int roomId;
  final int senderId;
  final String messageText;
  final bool isRead;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.messageText,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, roomId, senderId, messageText, isRead, createdAt];
}