import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/repositories/auth_repository.dart';

class DeleteUserUseCase {
  final AuthRepository repository;

  DeleteUserUseCase(this.repository);

  Future<Either<Failure, void>> call(int userId) async {
    return await repository.deleteUser(userId);
  }
}