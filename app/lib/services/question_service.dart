import 'dart:convert';
import '../models/question.dart';
import 'api_service.dart';

class QuestionService {
  // ── Categories ────────────────────────────────────────────────
  static Future<List<Category>> fetchCategories() async {
    try {
      final res = await ApiService.get('/api/tests/categories/');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (body['categories'] as List)
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Questions (simple, backward-compat) ──────────────────────
  static Future<List<Question>> fetchQuestions({
    String? categorySlug,
    String? difficulty,
    int limit = 20,
  }) async {
    final result = await fetchQuestionsPaged(
      categorySlug: categorySlug,
      difficulty: difficulty,
      limit: limit,
    );
    return result.questions;
  }

  // ── Paginated questions (offset-based) ───────────────────────
  static Future<({List<Question> questions, int total})> fetchQuestionsPaged({
    String? categorySlug,
    String? difficulty,
    int limit = 20,
    int offset = 0,
  }) async {
    String endpoint = '/api/tests/questions/?limit=$limit&offset=$offset';
    if (categorySlug != null && categorySlug.isNotEmpty) {
      endpoint += '&category=$categorySlug';
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      endpoint += '&difficulty=$difficulty';
    }
    try {
      final res = await ApiService.get(endpoint);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final questions = (body['questions'] as List)
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList();
        final total = body['total'] as int? ?? questions.length;
        return (questions: questions, total: total);
      }
    } catch (_) {}
    return (questions: <Question>[], total: 0);
  }

  // ── Submit single answer ──────────────────────────────────────
  static Future<Map<String, dynamic>?> submitAnswer({
    required String questionId,
    String? selectedOptionId,
    bool isDailyChallenge = false,
    String? codeAnswer,
  }) async {
    try {
      final body = {
        'question_id': int.tryParse(questionId) ?? questionId,
        'daily_challenge': isDailyChallenge,
      };
      if (selectedOptionId != null) {
        body['selected_option_id'] = int.tryParse(selectedOptionId) ?? selectedOptionId;
      }
      if (codeAnswer != null) {
        body['code_answer'] = codeAnswer;
      }

      final res = await ApiService.post('/api/tests/submit/', body);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Leaderboard ───────────────────────────────────────────────
  static Future<List<LeaderboardEntry>> fetchLeaderboard({int limit = 10}) async {
    try {
      final res = await ApiService.get('/api/tests/leaderboard/?limit=$limit');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (body['leaderboard'] as List)
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ── User stats ────────────────────────────────────────────────
  static Future<UserStats?> fetchUserStats() async {
    try {
      final res = await ApiService.get('/api/tests/stats/');
      if (res.statusCode == 200) {
        return UserStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
