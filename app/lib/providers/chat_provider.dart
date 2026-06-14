import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  String? _error;

  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.get('/inbox/');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _conversations = (body['conversations'] as List)
            .map((c) => Conversation.fromJson(c))
            .toList();
      } else {
        _error = 'Failed to load conversations';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchConversation(int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.get('/chat/$conversationId/');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _currentConversation = Conversation.fromJson(body['conversation']);
      } else {
        _error = 'Failed to load conversation';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startChat(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.post('/chat/start/$username/', {});
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _currentConversation = Conversation.fromJson(body['conversation']);
      } else {
        _error = 'Failed to start chat';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(int conversationId, String content) async {
    try {
      final response = await ApiService.post(
        '/chat/$conversationId/send/',
        {'content': content},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (_currentConversation != null) {
          _currentConversation!.messages.add(Message.fromJson(body['message']));
          notifyListeners();
        }
      } else {
        _error = 'Failed to send message';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearCurrentConversation() {
    _currentConversation = null;
    notifyListeners();
  }
}
