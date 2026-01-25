// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lung_chaing_farm/models/user.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/services/api_exception.dart'; // Import ApiException

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = true; // Added loading flag

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading; // Getter for loading flag

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token != null) {
        final user = await ApiService.instance.loadUserFromToken(token);
        if (user != null) {
          _user = user;
          _token = user.token;
          ApiService.instance.setAuthToken(_token);
          notifyListeners();
        } else {
          await prefs.remove('jwt_token');
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final user = await ApiService.instance.login(email, password);
      _user = user;
      _token = user.token;
      ApiService.instance.setAuthToken(_token);
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('jwt_token', _token!);
      }
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw Exception('Permission denied or invalid credentials.');
      }
      rethrow; // Re-throw other API exceptions
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String role,
    String? farmName,
    String? address,
    String? contactInfo,
  }) async {
    try {
      final user = await ApiService.instance.register(
        email: email,
        password: password,
        role: role,
        farmName: farmName,
        address: address,
        contactInfo: contactInfo,
      );
      _user = user;
      _token = user.token;
      ApiService.instance.setAuthToken(_token);
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('jwt_token', _token!);
      }
      notifyListeners();
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw Exception('Permission denied or invalid credentials.');
      }
      rethrow; // Re-throw other API exceptions
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    ApiService.instance.setAuthToken(null); // Clear token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token'); // Remove jwt_token
    notifyListeners();
  }
}
