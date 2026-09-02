import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import '../entities/user_entity.dart';

/*
 * DI / Usage Notes - AuthRepository
 *
 * - Use a single, configured Dio instance across the app (BaseOptions.baseUrl set
 *   and TokenInterceptor attached). Do NOT instantiate Dio() inside repositories.
 * - Repositories must receive Dio via constructor injection:
 *     class AuthRepositoryImpl implements AuthRepository {
 *       final Dio _dio;
 *       AuthRepositoryImpl(this._dio);
 *     }
 * - Use relative endpoint paths (e.g. 'login', 'users/1', 'refresh-token')
 *   so Dio.options.baseUrl is applied consistently.
 * - TokenInterceptor handles silent refresh and retrying requests.
 * - Parse responses defensively: verify response.data is Map before mapping to models.
 */

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String username, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, String?>> getToken();
  Future<Either<Failure, void>> refreshAccessToken();
  Future<Either<Failure, UserEntity?>> getDetail();
  Future<Either<Failure, List<UserEntity>>> getAllUsers();
  Future<Either<Failure, void>> deleteUser(int id);
  Future<Either<Failure, UserEntity>> updateProfile({
    required int id,
    required String username,
    required String email,
    required String fullName,
    required String phone,
    required String birthDate,
    required String gender,
    required String address,
    String? password,
  });
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, bool>> register(Map<String, dynamic> data);
}
