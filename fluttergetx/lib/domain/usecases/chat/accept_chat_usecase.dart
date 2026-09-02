import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';

class AcceptChatUseCase {
  final ChatRepository repository;

  AcceptChatUseCase(this.repository);

  Future<Either<Failure, void>> call(int roomId, int adminId) async {
    try {
      repository.acceptChat(roomId, adminId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}