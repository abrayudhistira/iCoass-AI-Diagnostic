import 'package:fluttergetx/domain/entities/chat_entity.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class GetChatRoomsUseCase {
  final ChatRepository repository;

  GetChatRoomsUseCase(this.repository);

  Future<List<ChatRoomEntity>> call() async {
    return await repository.getChatRooms();
  }
}