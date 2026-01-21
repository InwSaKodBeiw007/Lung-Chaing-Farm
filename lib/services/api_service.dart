// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Add this import
import 'package:lung_chaing_farm/services/api_exception.dart'; // Import ApiException

class ApiService {
  // --- Singleton Pattern ---
  static ApiService _instance =
      ApiService._internal(); // Make _instance public for testing

  // Internal HttpClient instance
  final http.Client _httpClient;
  String? _authToken; // Make _authToken an instance field

  factory ApiService() => _instance;

  // Private constructor with optional HttpClient for testing
  ApiService._internal({http.Client? httpClient, String? authToken})
    : _httpClient = httpClient ?? http.Client(),
      _authToken = authToken;

  // Getter for the instance (can be overridden in tests)
  static ApiService get instance => _instance;

  // Setter for testing purposes only
  @visibleForTesting
  static set instance(ApiService service) => _instance = service;

  @visibleForTesting
  static void resetForTesting({http.Client? httpClient}) {
    _instance = ApiService._internal(
      httpClient: httpClient,
      authToken: null,
    ); // Reset authToken as well
  }

  // --- Configuration ---
  // Use 'http://10.0.2.2:3000' for Android emulator
  // Use 'http://localhost:3000' for web
  static const String baseUrl =
      'http://localhost:3000'; // Corrected for web development

  // --- Header Management ---
  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _getHeaders({bool includeContentType = true}) {
    final headers = <String, String>{};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // --- Auth Methods ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to login',
      );
    }
  }

  Future<void> register({
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

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode != 201) {
      final errorBody = json.decode(response.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to register',
      );
    }
  }

  // --- Product Methods ---

  // Fetches low stock products for a villager
  Future<List<Map<String, dynamic>>> getLowStockProducts(String token) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/villager/low-stock-products'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['products']);
    } else {
      final errorBody = json.decode(response.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to load low stock products',
      );
    }
  }

  // Fetches all products
  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/products'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['products']);
    } else {
      final errorBody = json.decode(response.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to load products',
      );
    }
  }

  // Fetches a single product by ID
  Future<Map<String, dynamic>> getProductById(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['product']; // Assuming backend returns { "product": {...} }
    } else {
      final errorBody = json.decode(response.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to load product',
      );
    }
  }

  // Adds a new product
  Future<Map<String, dynamic>> addProduct(
    String name,
    double price,
    double stock, {
    String? category,
    double? lowStockThreshold,
    List<Uint8List>? imageBytes,
    List<String>? imageNames,
  }) async {
    final uri = Uri.parse('$baseUrl/products');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(
      _getHeaders(includeContentType: false),
    ); // Correctly apply to local 'request'

    request.fields['name'] = name;
    request.fields['price'] = price.toString();
    request.fields['stock'] = stock.toString();
    if (category != null) {
      request.fields['category'] = category;
    }
    if (lowStockThreshold != null) {
      request.fields['low_stock_threshold'] = lowStockThreshold.toString();
    }

    if (imageBytes != null && imageNames != null) {
      for (int i = 0; i < imageBytes.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images', // The backend expects an array of 'images'
            imageBytes[i],
            filename: imageNames[i],
          ),
        );
      }
    }

    final response = await _httpClient.send(request); // Use injected client
    final responseBody = await http.Response.fromStream(response);

    if (response.statusCode == 201) {
      return json.decode(responseBody.body);
    } else {
      final errorBody = json.decode(responseBody.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to add product',
      );
    }
  }

  // Purchases a product
  Future<Map<String, dynamic>> purchaseProduct(
    int productId,
    double quantity,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/products/$productId/purchase'),
      headers: _getHeaders(),
      body: json.encode({'quantity': quantity}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to purchase product',
      );
    }
  }

  // Updates a product's stock (e.g., when sold) - Simple stock update
  // This now needs to pass existing image URLs and category to the backend
  // to prevent accidental deletion of images.
  Future<Map<String, dynamic>> updateProductStock(
    int id,
    double newStock, {
    String? category,
    List<String>? existingImageUrls,
  }) async {
    final Map<String, dynamic> body = {'stock': newStock};
    if (category != null) {
      body['category'] = category;
    }
    if (existingImageUrls != null) {
      body['existing_image_urls'] = json.encode(
        existingImageUrls,
      ); // Backend expects JSON string
    }

    final response = await _httpClient.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getHeaders(),
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // Return the response body
    } else {
      final errorBody = json.decode(response.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to update product stock',
      );
    }
  }

  // Comprehensive update for an existing product
  Future<Map<String, dynamic>> updateProduct(
    int id,
    String name,
    double price,
    double stock,
    String? category,
    double? lowStockThreshold, {
    List<Uint8List>? newImageBytes,
    List<String>? newImageNames,
    List<String>? existingImageUrls, // List of image paths to keep
  }) async {
    final uri = Uri.parse('$baseUrl/products/$id');
    final request = http.MultipartRequest('PUT', uri); // Use PUT for updates

    request.headers.addAll(
      _getHeaders(includeContentType: false),
    ); // Correctly apply to local 'request'

    request.fields['name'] = name;
    request.fields['price'] = price.toString();
    request.fields['stock'] = stock.toString();
    if (category != null) {
      request.fields['category'] = category;
    }
    if (lowStockThreshold != null) {
      request.fields['low_stock_threshold'] = lowStockThreshold.toString();
    }
    // Send existing image URLs to the backend so it knows what to keep
    if (existingImageUrls != null && existingImageUrls.isNotEmpty) {
      // Need to stringify each URL in the list if sending as a single field
      request.fields['existing_image_urls'] = json.encode(existingImageUrls);
    }

    if (newImageBytes != null && newImageNames != null) {
      for (int i = 0; i < newImageBytes.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images', // The backend expects an array of 'images' for new uploads
            newImageBytes[i],
            filename: newImageNames[i],
          ),
        );
      }
    }

    final response = await _httpClient.send(request); // Use injected client
    final responseBody = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      return json.decode(responseBody.body); // Return the response body
    } else {
      final errorBody = json.decode(responseBody.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to update product',
      );
    }
  }

  // Fetches transaction history for a product
  Future<List<Map<String, dynamic>>> getProductTransactions(
    int productId, {
    int? days,
  }) async {
    Uri uri = Uri.parse('$baseUrl/products/$productId/transactions');
    if (days != null) {
      uri = uri.replace(queryParameters: {'days': days.toString()});
    }

    final response = await _httpClient.get(uri, headers: _getHeaders());
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['transactions']);
    } else {
      final errorBody = json.decode(response.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to load product transactions',
      );
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getHeaders(),
    );
    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw ApiException(
        response.statusCode,
        errorBody['error'] ?? 'Failed to delete product',
      );
    }
  }
}
