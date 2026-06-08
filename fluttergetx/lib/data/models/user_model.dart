import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.fullName,
    required super.phone,
    required super.birthDate,
    required super.gender,
    required super.address,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Deteksi apakah data dibungkus dalam key 'user' (seperti saat login)
    // atau merupakan data user langsung (seperti di dalam list dari getAllUsers)
    final Map<String, dynamic> userMap = (json['user'] is Map<String, dynamic>) 
        ? json['user'] 
        : json;

    return UserModel(
      id: _parseId(userMap['id']),
      username: userMap['username']?.toString() ?? '',
      email: userMap['email']?.toString() ?? '',
      fullName: userMap['full_name']?.toString() ?? '',
      role: userMap['role']?.toString() ?? '',
      phone: userMap['phone']?.toString(),
      birthDate: userMap['birth_date']?.toString(),
      gender: userMap['gender']?.toString(),
      address: userMap['address']?.toString(),
    );
  }

  static int _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }
}
