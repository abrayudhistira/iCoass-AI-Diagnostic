class UserEntity {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? phone;
  final String? birthDate;
  final String? gender;
  final String? address;
  final String role;

  UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phone,
    this.birthDate,
    this.gender,
    this.address,
    required this.role,
  });
}
