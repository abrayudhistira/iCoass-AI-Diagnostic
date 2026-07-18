import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/user_entity.dart';
import 'package:fluttergetx/domain/repositories/auth_repository.dart';

class GetUserDetailUseCase {
  final AuthRepository repository;

  GetUserDetailUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() async {
    try {
      final user = await repository.getDetail();
      if (user != null) {
        return Right(user);
      }
      return const Left(ServerFailure('User not found'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}