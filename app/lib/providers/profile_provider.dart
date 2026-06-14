import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  Profile? _userProfile;
  Profile? _viewingProfile;
  bool _isLoading = false;
  String? _error;

  Profile? get userProfile => _userProfile;
  Profile? get viewingProfile => _viewingProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.get('/api/profile/');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _userProfile = Profile.fromJson(body['profile']);
      } else {
        _error = 'Failed to load profile';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfileByUsername(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.get('/api/profile/$username/');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _viewingProfile = Profile.fromJson(body['profile']);
      } else {
        _error = 'Failed to load profile';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? avatar,
    String? bio,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.post('/api/profile/update/', {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (avatar != null) 'avatar': avatar,
        if (bio != null) 'bio': bio,
      });
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _userProfile = Profile.fromJson(body['profile']);
      } else {
        _error = 'Failed to update profile';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearViewingProfile() {
    _viewingProfile = null;
    notifyListeners();
  }
}
