import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(int senderId, int roomId, String message) async {
    try {
      repository.sendMessage(senderId, roomId, message);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}