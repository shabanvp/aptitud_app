import 'dart:convert';

import '../models/user.dart';
import 'api_service.dart';

class CandidateService {
  static Future<CandidateListResponse?> fetchTopCandidates() async {
    try {
      final res = await ApiService.get('/api/recruiter/candidates/');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return CandidateListResponse.fromJson(body);
      }
    } catch (_) {}
    return null;
  }

  static Future<CandidateProfile?> fetchCandidateDetail(String username) async {
    try {
      final res = await ApiService.get('/api/recruiter/candidates/$username/');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return CandidateProfile.fromJson(body);
      }
    } catch (_) {}
    return null;
  }
}
