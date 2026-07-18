import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  void call(int senderId, int roomId, String message) {
    repository.sendMessage(senderId, roomId, message);
  }
}