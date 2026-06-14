import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _token;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isCompany => _currentUser?.isCompany ?? false;
  bool get isLoading => _isLoading;
  String? get token => _token;

  AuthProvider() {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserJson = prefs.getString('auth_user');
      
      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        ApiService.setToken(savedToken);
        _currentUser = User.fromJson(jsonDecode(savedUserJson));
      }
    } catch (e) {
      debugPrint('Error loading saved auth session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.post('/api/auth/login/', {
        'username': username,
        'password': password,
      });

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _token = body['token'];
        _currentUser = User.fromJson(body['user']);
        
        ApiService.setToken(_token);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));
      } else {
        throw body['error'] ?? 'Failed to log in.';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required bool isCompany,
    String? currentStatus,
    String? interestedField,
    String? hiringFocus,
    String? organization,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.post('/api/auth/register/', {
        'username': username,
        'email': email,
        'password': password,
        'is_company': isCompany,
        'current_status': currentStatus ?? '',
        'interested_field': interestedField ?? '',
        'hiring_focus': hiringFocus ?? '',
        'organization': organization ?? '',
      });

      final body = jsonDecode(response.body);
      if (response.statusCode != 201) {
        throw body['error'] ?? 'Failed to register.';
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    ApiService.setToken(null);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    
    notifyListeners();
  }
}
