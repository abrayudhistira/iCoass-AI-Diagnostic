import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class RequestNewChatUseCase {
  final ChatRepository repository;

  RequestNewChatUseCase(this.repository);

  Future<Either<Failure, void>> call(int userId) {
    return repository.requestChat(userId);
  }
}