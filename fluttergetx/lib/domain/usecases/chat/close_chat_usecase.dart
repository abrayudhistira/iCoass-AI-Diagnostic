import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class CloseChatUseCase {
  final ChatRepository repository;

  CloseChatUseCase(this.repository);

  Future<void> call(int roomId) async {
    await repository.closeChat(roomId);
  }
}