import '../../domain/entities/chat_entity.dart';

class ChatRoomModel extends ChatRoomEntity {
  const ChatRoomModel({
    required super.id,
    required super.userId,
    super.adminId,
    super.lastMessage,
    required super.lastMessageTime,
    super.opponentName,
    required super.status,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    String? name;
    if (json['user'] != null) {
      name = json['user']['username'];
    } else if (json['admin'] != null) {
      name = json['admin']['username'];
    } else {
      name = json['opponent_name'];
    }

    return ChatRoomModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      adminId: json['admin_id'], // Bisa null dari DB
      lastMessage: json['last_message'],
      lastMessageTime: DateTime.parse(
        json['last_message_time'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      opponentName: name,
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'admin_id': adminId,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'opponent_name': opponentName,
      'status': status,
    };
  }
}

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.messageText,
    required super.isRead,
    required super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      messageText: json['message_text'] ?? "",
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      // createdAt: DateTime.parse(
      //   json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      // ),
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
    );
  }
}