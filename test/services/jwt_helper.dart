import 'dart:convert';

// Generate a JWT with a specific payload for testing
String generateTestJwt(int id, String email, String role, String? farmName) {
  final Map<String, dynamic> payload = {
    'id': id,
    'email': email,
    'role': role,
    'farm_name': farmName,
    'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000, // Expires in 1 hour
  };
  // In a real scenario, this would be signed. For testing decoding, an unsigned token is sufficient.
  // This is a simplified representation. Actual JWTs have header, payload, and signature.
  final String header = base64Url.encode(utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})));
  final String payloadEncoded = base64Url.encode(utf8.encode(json.encode(payload)));
  return '$header.$payloadEncoded.'; // Trailing dot for unsigned part
}

// Generate an expired JWT
String generateExpiredTestJwt(int id, String email, String role, String? farmName) {
  final Map<String, dynamic> payload = {
    'id': id,
    'email': email,
    'role': role,
    'farm_name': farmName,
    'exp': DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000, // Expired 1 hour ago
  };
  final String header = base64Url.encode(utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})));
  final String payloadEncoded = base64Url.encode(utf8.encode(json.encode(payload)));
  return '$header.$payloadEncoded.';
}
