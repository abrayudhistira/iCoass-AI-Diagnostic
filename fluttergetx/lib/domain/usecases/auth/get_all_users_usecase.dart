import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/user_entity.dart';
import 'package:fluttergetx/domain/repositories/auth_repository.dart';

class GetAllUsersUseCase {
  final AuthRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<Either<Failure, List<UserEntity>>> call() {
    return repository.getAllUsers();
  }
}