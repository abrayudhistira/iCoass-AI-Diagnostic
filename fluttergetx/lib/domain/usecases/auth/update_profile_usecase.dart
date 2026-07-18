import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/user_entity.dart';
import 'package:fluttergetx/domain/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required int id,
    required String username,
    required String email,
    required String fullName,
    required String phone,
    required String birthDate,
    required String gender,
    required String address,
    String? password,
  }) async {
    return await repository.updateProfile(
      id: id,
      username: username,
      email: email,
      fullName: fullName,
      phone: phone,
      birthDate: birthDate,
      gender: gender,
      address: address,
      password: password,
    );
  }
}