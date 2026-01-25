// lib/models/user.dart
class User {
  final int? id;
  final String? email;
  final String? role;
  final String? farmName;
  final String? token;

  User({this.id, this.email, this.role, this.farmName, this.token});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      farmName: json['farm_name'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'farm_name': farmName,
      'token': token,
    };
  }
}
