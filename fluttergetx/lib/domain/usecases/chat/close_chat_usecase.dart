import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class CloseChatUseCase {
  final ChatRepository repository;

  CloseChatUseCase(this.repository);

  Future<Either<Failure, void>> call(int roomId) {
    return repository.closeChat(roomId);
  }
}