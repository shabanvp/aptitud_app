import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // 10.0.2.2 is the special IP to access your developer machine's localhost from Android Emulator.
  // Using localhost for web, windows and other platforms.
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
      return 'http://$host:8001';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.27.151.98:8001';
    }
    return 'http://localhost:8001';
  }

  static String get websocketBaseUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme).toString();
  }

  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get headers {
    final Map<String, String> h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      h['Authorization'] = 'Token $_token';
    }
    return h;
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: headers);
  }
}
