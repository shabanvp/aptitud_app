import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/theme.dart';
import '../../models/question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_state_provider.dart';
import '../../services/multiplayer_service.dart';
import 'match_webview_screen.dart';

class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  List<Category> _topics = [];
  Category? _selectedTopic;
  bool _loading = true;
  bool _searching = false;
  String? _error;
  String _status = 'Choose a topic to start a real-time VS match.';
  int _entryFeeCoins = 20;
  int _entryFeeLives = 1;
  int _winnerRewardCoins = 40;
  int _elapsedSeconds = 0;
  Timer? _timer;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTopics());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await MultiplayerService.fetchTopics();
      if (!mounted) return;

      Provider.of<GameStateProvider>(
        context,
        listen: false,
      ).syncFromServer({'coins': data.coins, 'lives': data.lives});

      setState(() {
        _topics = data.categories;
        _selectedTopic = data.categories.isNotEmpty
            ? data.categories.first
            : null;
        _entryFeeCoins = data.entryFeeCoins;
        _entryFeeLives = data.entryFeeLives;
        _winnerRewardCoins = data.winnerRewardCoins;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startSearch() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final gameState = Provider.of<GameStateProvider>(context, listen: false);
    final topic = _selectedTopic;

    if (token == null || token.isEmpty) {
      _showSnack('Please log in again before starting Battle.');
      return;
    }
    if (topic == null) {
      _showSnack('Choose a topic first.');
      return;
    }
    if (gameState.coins < _entryFeeCoins || gameState.lives < _entryFeeLives) {
      _showSnack(
        'You need $_entryFeeCoins coins and $_entryFeeLives life to play VS mode.',
      );
      return;
    }

    _channel?.sink.close();
    final channel = MultiplayerService.connectMatchmaking(token);
    _channel = channel;

    setState(() {
      _searching = true;
      _elapsedSeconds = 0;
      _status = 'Searching in ${topic.name}...';
      _error = null;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });

    channel.stream.listen(
      (message) => _handleMatchmakingMessage(message, token),
      onError: (_) => _stopSearch(
        error:
            'Could not connect to matchmaking. Is the Django server running?',
      ),
      onDone: () {
        if (_searching) {
          _stopSearch(error: 'Matchmaking connection closed.');
        }
      },
    );

    channel.sink.add(
      jsonEncode({'action': 'search_match', 'topic': topic.slug}),
    );
  }

  void _handleMatchmakingMessage(dynamic message, String token) {
    final data = jsonDecode(message as String) as Map<String, dynamic>;
    final type = data['type'];

    if (type == 'match_found') {
      final matchId = data['match_id'] as int;
      final opponent = data['opponent'] as Map<String, dynamic>? ?? {};
      _timer?.cancel();
      _channel?.sink.close();
      _channel = null;
      setState(() {
        _searching = false;
        _status = 'Match found against ${opponent['username'] ?? 'opponent'}!';
      });
      Provider.of<GameStateProvider>(context, listen: false).refreshStats();
      _showMatchFoundDialog(
        matchId: matchId,
        token: token,
        opponent: opponent['username'] ?? 'Opponent',
      );
      return;
    }

    if (type == 'error') {
      _stopSearch(error: data['message'] ?? 'Unable to find a match.');
      return;
    }

    if (type == 'search_cancelled') {
      _stopSearch();
    }
  }

  void _cancelSearch() {
    if (_searching) {
      _channel?.sink.add(jsonEncode({'action': 'cancel_search'}));
    }
    _stopSearch();
  }

  void _stopSearch({String? error}) {
    _timer?.cancel();
    _channel?.sink.close();
    _channel = null;

    if (!mounted) return;
    setState(() {
      _searching = false;
      _error = error;
      _status = error ?? 'Choose a topic to start a real-time VS match.';
    });
  }

  void _openMatch({
    required int matchId,
    required String token,
    required String opponent,
  }) {
    final url = MultiplayerService.gameUrl(matchId: matchId, token: token);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchWebViewScreen(
          url: url,
          opponentName: opponent,
        ),
      ),
    );
  }

  void _showMatchFoundDialog({
    required int matchId,
    required String token,
    required String opponent,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Match Found! 🎮',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'You are matched with $opponent. Ready to battle?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openMatch(matchId: matchId, token: token, opponent: opponent);
            },
            child: const Text('OPEN MATCH'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameStateProvider>(context);
    final canPlay =
        gameState.coins >= _entryFeeCoins && gameState.lives >= _entryFeeLives;

    return RefreshIndicator(
      onRefresh: _loadTopics,
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            sliver: SliverToBoxAdapter(
              child: _BattleHeader(
                coins: gameState.coins,
                lives: gameState.lives,
                entryFeeCoins: _entryFeeCoins,
                entryFeeLives: _entryFeeLives,
                winnerRewardCoins: _winnerRewardCoins,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _MatchmakingPanel(
                searching: _searching,
                status: _status,
                elapsedSeconds: _elapsedSeconds,
                canPlay: canPlay,
                selectedTopic: _selectedTopic,
                onFindMatch: _startSearch,
                onCancel: _cancelSearch,
              ),
            ),
          ),
          if (_error != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(child: _ErrorBanner(message: _error!)),
            ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Choose Battle Topic',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (_topics.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No multiplayer topics available right now.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount: _topics.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  return _TopicCard(
                    topic: topic,
                    selected: topic.slug == _selectedTopic?.slug,
                    enabled: !_searching,
                    onTap: () => setState(() => _selectedTopic = topic),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BattleHeader extends StatelessWidget {
  final int coins;
  final int lives;
  final int entryFeeCoins;
  final int entryFeeLives;
  final int winnerRewardCoins;

  const _BattleHeader({
    required this.coins,
    required this.lives,
    required this.entryFeeCoins,
    required this.entryFeeLives,
    required this.winnerRewardCoins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.sports_esports_rounded,
                color: AppTheme.primary,
                size: 34,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'VS Online Players',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Entry costs $entryFeeCoins coins and $entryFeeLives life. Winner takes $winnerRewardCoins coins.',
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ResourceChip(
                icon: Icons.monetization_on_rounded,
                label: '$coins Coins',
                color: AppTheme.accent,
              ),
              _ResourceChip(
                icon: Icons.favorite_rounded,
                label: '$lives Lives',
                color: AppTheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchmakingPanel extends StatelessWidget {
  final bool searching;
  final String status;
  final int elapsedSeconds;
  final bool canPlay;
  final Category? selectedTopic;
  final VoidCallback onFindMatch;
  final VoidCallback onCancel;

  const _MatchmakingPanel({
    required this.searching,
    required this.status,
    required this.elapsedSeconds,
    required this.canPlay,
    required this.selectedTopic,
    required this.onFindMatch,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.16),
            AppTheme.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (searching)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 4,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Icon(
                Icons.radar_rounded,
                color: AppTheme.primary,
                size: 42,
              ),
            ),
          Text(
            selectedTopic == null ? 'Select a topic' : selectedTopic!.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searching ? '$status ${elapsedSeconds}s' : status,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: searching ? onCancel : (canPlay ? onFindMatch : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: searching ? AppTheme.error : AppTheme.primary,
                disabledBackgroundColor: AppTheme.surfaceLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                searching ? 'CANCEL SEARCH' : 'FIND OPPONENT',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Category topic;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primary : AppTheme.secondary;

    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: selected ? 0.7 : 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    topic.name.isEmpty ? '?' : topic.name[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.description.isEmpty
                          ? '${topic.questionCount} questions ready'
                          : topic.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: color,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ResourceChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.error, fontSize: 12),
      ),
    );
  }
}
