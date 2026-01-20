// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package.shared_preferences/shared_preferences.dart';
import 'package:lung_chaing_farm/models/user.dart';
import 'package:lung_chaing_farm/services/api_service.dart';

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
    final userData = prefs.getString('userData');
    if (userData != null) {
      final decoded = json.decode(userData) as Map<String, dynamic>;
      _user = User.fromJson(decoded['user']);
      _token = decoded['token'];
      // Set the token in ApiService for subsequent requests
      ApiService.setAuthToken(_token);
      notifyListeners();
    }
  }

  Future<void> _saveUserToStorage(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode({
      'token': token,
      'user': {
        'id': user.id,
        'email': user.email,
        'role': user.role,
        'farm_name': user.farmName,
      }
    });
    await prefs.setString('userData', userData);
  }

  Future<void> login(String email, String password) async {
    final response = await ApiService.login(email, password);
    _user = User.fromJson(response['user']);
    _token = response['token'];
    ApiService.setAuthToken(_token); // Important
    await _saveUserToStorage(_user!, _token!);
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
    String? farmName,
    String? address,
    String? contactInfo,
  }) async {
    await ApiService.register(
      email: email,
      password: password,
      role: role,
      farmName: farmName,
      address: address,
      contactInfo: contactInfo,
    );
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    ApiService.setAuthToken(null); // Clear token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    notifyListeners();
  }
}
