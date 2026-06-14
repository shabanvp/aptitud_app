import 'package:flutter/material.dart';
import '../services/question_service.dart';
import '../models/question.dart';

class GameStateProvider with ChangeNotifier {
  int _coins;
  int _lives;
  int _level;
  int _exp;
  UserStats? _stats;

  GameStateProvider({int coins = 0, int lives = 5, int level = 1, int exp = 0})
      : _coins = coins,
        _lives = lives,
        _level = level,
        _exp = exp;

  int get coins => _coins;
  int get lives => _lives;
  int get level => _level;
  int get exp => _exp;
  UserStats? get stats => _stats;

  /// Called after login to seed values from the real user object.
  void syncFromUser({required int coins, required int lives, required int level, required int exp}) {
    _coins = coins;
    _lives = lives;
    _level = level;
    _exp = exp;
    notifyListeners();
    _loadStats();
  }

  Future<void> _loadStats() async {
    _stats = await QuestionService.fetchUserStats();
    notifyListeners();
  }

  Future<void> refreshStats() async {
    _stats = await QuestionService.fetchUserStats();
    notifyListeners();
  }

  void syncFromServer(Map<String, dynamic> userData) {
    _coins = userData['coins'] ?? _coins;
    _lives = userData['lives'] ?? _lives;
    _level = userData['level'] ?? _level;
    _exp = userData['exp'] ?? _exp;
    notifyListeners();
  }

  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }

  void spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      notifyListeners();
    }
  }

  void loseLife() {
    if (_lives > 0) {
      _lives -= 1;
      notifyListeners();
    }
  }

  void addExp(int amount) {
    _exp += amount;
    final newLevel = 1 + (_exp ~/ 300);
    if (newLevel > _level) _level = newLevel;
    notifyListeners();
  }
}
