import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/question.dart';
import 'api_service.dart';

class MultiplayerTopics {
  final List<Category> categories;
  final int coins;
  final int lives;
  final int entryFeeCoins;
  final int entryFeeLives;
  final int winnerRewardCoins;

  MultiplayerTopics({
    required this.categories,
    required this.coins,
    required this.lives,
    required this.entryFeeCoins,
    required this.entryFeeLives,
    required this.winnerRewardCoins,
  });

  factory MultiplayerTopics.fromJson(Map<String, dynamic> json) {
    return MultiplayerTopics(
      coins: json['coins'] ?? 0,
      lives: json['lives'] ?? 0,
      entryFeeCoins: json['entry_fee_coins'] ?? 20,
      entryFeeLives: json['entry_fee_lives'] ?? 1,
      winnerRewardCoins: json['winner_reward_coins'] ?? 40,
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MultiplayerService {
  static Future<MultiplayerTopics> fetchTopics() async {
    final response = await ApiService.get('/api/multiplayer/topics/');
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw body['error'] ?? 'Unable to load multiplayer topics.';
    }

    return MultiplayerTopics.fromJson(body);
  }

  static WebSocketChannel connectMatchmaking(String token) {
    final uri = Uri.parse(
      '${ApiService.websocketBaseUrl}/ws/matchmaking/',
    ).replace(queryParameters: {'token': token});
    return WebSocketChannel.connect(uri);
  }

  static String gameUrl({required int matchId, required String token}) {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/multiplayer/game/$matchId/',
    ).replace(queryParameters: {'token': token});
    return uri.toString();
  }
}
