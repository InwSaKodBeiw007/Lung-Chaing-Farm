// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:lung_chaing_farm/services/api_exception.dart'; // Import ApiException

class ApiService {
  // --- Singleton Pattern ---
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // --- Configuration ---
  // Use 'http://10.0.2.2:3000' for Android emulator
  // Use 'http://localhost:3000' for web
  static const String baseUrl = 'http://10.24.14.163:3000'; 
  static String? _authToken;

  // --- Header Management ---
  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // --- Auth Methods ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw ApiException(response.statusCode, errorBody['error'] ?? 'Failed to login');
    }
  }

  static Future<void> register({
    required String email,
    required String password,
    required String role,
    String? farmName,
    String? address,
    String? contactInfo,
  }) async {
    final body = {
      'email': email,
      'password': password,
      'role': role,
      'farm_name': farmName,
      'address': address,
      'contact_info': contactInfo,
    };
    // Remove null values so the backend doesn't receive them
    body.removeWhere((key, value) => value == null);

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode != 201) {
      final errorBody = json.decode(response.body);
      throw ApiException(response.statusCode, errorBody['error'] ?? 'Failed to register');
    }
  }

  // --- Product Methods ---
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['products']);
    } else {
      final errorBody = json.decode(response.body);
      throw ApiException(response.statusCode, errorBody['error'] ?? 'Failed to load products');
    }
  }

  static Future<Map<String, dynamic>> addProduct(String name, double price, double stock, {List<Uint8List>? imageBytes, List<String>? imageNames}) async {
    final uri = Uri.parse('$baseUrl/products');
    final request = http.MultipartRequest('POST', uri);
    
    // Add auth token to multipart request header
    request.headers.addAll({'Authorization': 'Bearer $_authToken'});

    request.fields['name'] = name;
    request.fields['price'] = price.toString();
    request.fields['stock'] = stock.toString();

    if (imageBytes != null && imageNames != null) {
      for(int i = 0; i < imageBytes.length; i++) {
        request.files.add(http.MultipartFile.fromBytes(
          'images', // The backend expects an array of 'images'
          imageBytes[i],
          filename: imageNames[i],
        ));
      }
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    if (response.statusCode == 201) {
      return json.decode(responseBody.body);
    } else {
      final errorBody = json.decode(responseBody.body);
      throw ApiException(response.statusCode, errorBody['error'] ?? 'Failed to add product');
    }
  }
  
  static Future<void> updateProductStock(int id, double newStock) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getHeaders(),
      body: json.encode({'stock': newStock}),
    );
    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw ApiException(response.statusCode, errorBody['error'] ?? 'Failed to update product stock');
    }
  }

  static Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw ApiException(response.statusCode, errorBody['error'] ?? 'Failed to delete product');
    }
  }
}
