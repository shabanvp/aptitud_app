import 'dart:convert';

import '../models/event.dart';
import '../services/api_service.dart';

class EventService {
  static Future<List<Event>> fetchRecruiterEvents() async {
    try {
      final res = await ApiService.get('/events/api/recruiter/');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return (body['events'] as List)
            .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> createEvent({
    required String title,
    required String description,
    required int totalQuestions,
    required int timeLimitSeconds,
    required String thresholdType,
    required int thresholdValue,
    required String startTime,
    required String endTime,
    int? categoryId,
  }) async {
    try {
      final res = await ApiService.post('/events/api/create/', {
        'title': title,
        'description': description,
        'total_questions': totalQuestions,
        'time_limit_seconds': timeLimitSeconds,
        'threshold_type': thresholdType,
        'threshold_value': thresholdValue,
        'start_time': startTime,
        'end_time': endTime,
        'category_id': categoryId,
        'is_active': true,
      });
      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
