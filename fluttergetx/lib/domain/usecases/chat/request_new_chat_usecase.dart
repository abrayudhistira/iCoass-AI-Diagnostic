import 'package:fluttergetx/domain/repositories/chat_repository.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:dartz/dartz.dart';

class RequestNewChatUseCase {
  final ChatRepository repository;

  RequestNewChatUseCase(this.repository);

  Future<Either<Failure, void>> call(int userId) async {
    try {
      // Assuming repository.requestChat now returns a Future<void> and handles its own errors
      // For now, we'll just wrap the existing call.
      // In a real scenario, the repository might return Either<Failure, void> directly.
      await repository.requestChat(userId);
      return const Right(null);
    } catch (e) {
      // A more robust error handling would involve mapping specific exceptions to Failure types
      return Left(ServerFailure(e.toString()));
    }
  }
}
