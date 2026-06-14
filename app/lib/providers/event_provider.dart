import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class EventProvider with ChangeNotifier {
  List<Event> _events = [];
  List<Event> _recruiterEvents = [];
  Event? _selectedEvent;
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  List<Event> get recruiterEvents => _recruiterEvents;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAvailableEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.get('/events/');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _events = (body['events'] as List)
            .map((e) => Event.fromJson(e))
            .toList();
      } else {
        _error = 'Failed to load events';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecruiterEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.get('/events/api/recruiter/');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _recruiterEvents = (body['events'] as List)
            .map((e) => Event.fromJson(e))
            .toList();
      } else {
        _error = 'Failed to load recruiter events';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEventDetail(int eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.get('/events/$eventId/');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _selectedEvent = Event.fromJson(body['event']);
      } else {
        _error = 'Failed to load event';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required int totalQuestions,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.post('/events/api/create/', {
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'total_questions': totalQuestions,
      });
      if (response.statusCode == 201) {
        await fetchRecruiterEvents();
      } else {
        final body = jsonDecode(response.body);
        _error = body['error'] ?? 'Failed to create event';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitEventAnswers(int eventId, Map<String, dynamic> answers) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.post(
        '/events/$eventId/take/',
        {'answers': answers},
      );
      if (response.statusCode == 200) {
        _selectedEvent = null;
        notifyListeners();
      } else {
        _error = 'Failed to submit event';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }
}
