class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
  });

  final int id;
  final String email;
  final String role;
  final String name;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      role: (json['role'] as String? ?? 'PATIENT').toUpperCase(),
      name: json['name'] as String? ?? 'Patient',
    );
  }
}
