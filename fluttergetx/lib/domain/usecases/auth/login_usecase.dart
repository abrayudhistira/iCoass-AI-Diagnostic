import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/user_entity.dart';
import 'package:fluttergetx/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String username, String password) async {
    try {
      final user = await repository.login(username, password);
      if (user != null) {
        return Right(user);
      }
      return const Left(ServerFailure('Login failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}