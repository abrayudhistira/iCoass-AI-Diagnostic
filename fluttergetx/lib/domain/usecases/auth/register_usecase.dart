import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, bool>> call(Map<String, dynamic> data) {
    return repository.register(data);
  }
}