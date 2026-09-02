import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/chat_entity.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class GetChatRoomsUseCase {
  final ChatRepository repository;

  GetChatRoomsUseCase(this.repository);

  Future<Either<Failure, List<ChatRoomEntity>>> call() {
    return repository.getChatRooms();
  }
}