// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 'http://10.0.2.2:3000' for Android emulator to access host machine's localhost
  // Use 'http://localhost:3000' for web development
  // Replace with your machine's IP address (e.g., 'http://192.168.1.X:3000') for physical devices or other machines
  static const String baseUrl = 'http://10.0.2.2:3000'; // Change this based on your setup

  // Fetches all products from the backend
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['products']);
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Adds a new product to the backend
  static Future<Map<String, dynamic>> addProduct(String name, double price, double stock, {Uint8List? imageBytes, String? imageName}) async {
    final uri = Uri.parse('$baseUrl/products');
    final request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['price'] = price.toString();
    request.fields['stock'] = stock.toString();

    if (imageBytes != null && imageName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName,
      ));
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    if (response.statusCode == 201) {
      return json.decode(responseBody.body);
    } else {
      throw Exception('Failed to add product: ${responseBody.body}');
    }
  }

  // Updates a product's stock (e.g., when sold)
  static Future<void> updateProductStock(int id, double newStock) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'stock': newStock}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update product stock: ${response.body}');
    }
  }

  // Deletes a product
  static Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }
}
