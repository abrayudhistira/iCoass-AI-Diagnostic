import 'package:fluttergetx/domain/entities/chat_entity.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class GetQueuesUseCase {
  final ChatRepository repository;

  GetQueuesUseCase(this.repository);

  Future<List<ChatRoomEntity>> call() async {
    return await repository.getQueues();
  }
}