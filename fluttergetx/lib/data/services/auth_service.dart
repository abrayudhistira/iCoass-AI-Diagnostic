import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage;

  AuthService(this._secureStorage);

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<bool> isLoggedIn() async {
    return await getAccessToken() != null;
  }

  Future<void> saveUserDetails(String id, String fullName, String username, String role) async {
    await _secureStorage.write(key: 'id', value: id);
    await _secureStorage.write(key: 'full_name', value: fullName);
    await _secureStorage.write(key: 'username', value: username);
    await _secureStorage.write(key: 'role', value: role);
  }

  Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'id');
  }
}