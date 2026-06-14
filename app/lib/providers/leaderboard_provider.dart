import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/leaderboard.dart';
import '../services/api_service.dart';

class LeaderboardProvider with ChangeNotifier {
  List<LeaderboardEntry> _leaderboard = [];
  UserStats? _userStats;
  bool _isLoading = false;
  String? _error;

  List<LeaderboardEntry> get leaderboard => _leaderboard;
  UserStats? get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.get('/api/tests/leaderboard/');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _leaderboard = (body['leaderboard'] as List)
            .asMap()
            .entries
            .map((entry) {
              final user = entry.value;
              user['rank'] = entry.key + 1;
              return LeaderboardEntry.fromJson(user);
            })
            .toList();
      } else {
        _error = 'Failed to load leaderboard';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.get('/api/tests/stats/');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _userStats = UserStats.fromJson(body['stats']);
      } else {
        _error = 'Failed to load user stats';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
