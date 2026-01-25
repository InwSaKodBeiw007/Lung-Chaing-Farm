// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lung_chaing_farm/models/user.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/services/api_exception.dart'; // Import ApiException

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null) {
      final user = await ApiService.instance.loadUserFromToken(token);
      if (user != null) {
        _user = user;
        _token = user.token; // User object now contains the token
        ApiService.instance.setAuthToken(_token);
        notifyListeners();
      } else {
        // Token was invalid or expired, clear it from storage
        await prefs.remove('jwt_token');
      }
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', json.encode(user.toJson()));
  }

  Future<void> login(String email, String password) async {
    try {
      final user = await ApiService.instance.login(email, password);
      _user = user;
      _token = user.token;
      ApiService.instance.setAuthToken(_token);
      await _saveUserToStorage(_user!);
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
      await _saveUserToStorage(_user!);
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
    await prefs.remove('userData');
    notifyListeners();
  }
}
