// lib/models/user.dart
class User {
  final int id;
  final String email;
  final String role;
  final String? farmName;
  final String? token;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.farmName,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      farmName: json['farm_name'],
    );
  }
}
