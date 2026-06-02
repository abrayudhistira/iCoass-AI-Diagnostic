import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String username, String password);
  Future<void> logout();
  Future<String?> getToken();
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