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
  Future<UserEntity?> login(String username, String password);
  Future<void> logout();
  Future<String?> getToken();
  Future<void> refreshAccessToken();
  Future<UserEntity?> getDetail();
  Future<List<UserEntity>> getAllUsers();
  Future<bool> deleteUser(int id);
  Future<UserEntity?> updateProfile({
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
  Future<bool> isLoggedIn();
  Future<bool> register(Map<String, dynamic> data);
}
