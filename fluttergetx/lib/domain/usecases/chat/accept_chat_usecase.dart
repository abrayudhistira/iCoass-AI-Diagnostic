import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class AcceptChatUseCase {
  final ChatRepository repository;

  AcceptChatUseCase(this.repository);

  void call(int roomId, int adminId) {
    repository.acceptChat(roomId, adminId);
  }
}