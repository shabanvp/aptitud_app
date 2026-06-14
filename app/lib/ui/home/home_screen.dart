import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_state_provider.dart';
import '../../services/question_service.dart';
import '../tests/category_practice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _categories = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _loadingCategories = true;
  bool _loadingLeaderboard = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await QuestionService.fetchCategories();
    final lb = await QuestionService.fetchLeaderboard(limit: 5);
    if (mounted) {
      setState(() {
        _categories = cats;
        _leaderboard = lb;
        _loadingCategories = false;
        _loadingLeaderboard = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadingCategories = true;
      _loadingLeaderboard = true;
    });
    await _loadData();
    if (mounted) {
      await Provider.of<GameStateProvider>(
        context,
        listen: false,
      ).refreshStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final gameState = Provider.of<GameStateProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroHeader(
                user: user,
                gameState: gameState,
                onLogout: auth.logout,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            // Daily Challenge
            SliverToBoxAdapter(
              child: _DailyChallengeCard(stats: gameState.stats),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            // Categories
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Practice by Category'),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _loadingCategories
                  ? const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : _categories.isEmpty
                  ? const _EmptyState(
                      message:
                          'No categories yet.\nAdd questions via the Django admin panel.',
                    )
                  : _CategoryRow(categories: _categories),
            ),
            // Progress Stats
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Your Progress'),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _ProgressStats(stats: gameState.stats)),
            // Leaderboard
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverToBoxAdapter(
              child: _SectionTitle(title: '🏆 Top Rankers'),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _loadingLeaderboard
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : _LeaderboardList(entries: _leaderboard),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HERO HEADER
// ═══════════════════════════════════════════════════════════════
class _HeroHeader extends StatelessWidget {
  final dynamic user;
  final GameStateProvider gameState;
  final VoidCallback onLogout;
  const _HeroHeader({
    required this.user,
    required this.gameState,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final int xpForNextLevel = gameState.level * 300;
    final double xpProgress =
        ((gameState.exp % xpForNextLevel) / xpForNextLevel).clamp(0.0, 1.0);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
        ? 'Good Afternoon,'
        : 'Good Evening,';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.2),
            AppTheme.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (user?.username ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
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
                      greeting,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      user?.username ?? 'Candidate',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Hearts
              if (MediaQuery.of(context).size.width > 300) ...[
                _HeartsRow(lives: gameState.lives),
                const SizedBox(width: 8),
              ],
              // Logout
              GestureDetector(
                onTap: onLogout,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Level + XP bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Level ${gameState.level}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${gameState.exp % xpForNextLevel} / $xpForNextLevel XP',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _MiniStat(
                icon: Icons.monetization_on_rounded,
                color: AppTheme.accent,
                value: '${gameState.coins} Coins',
              ),
              _MiniStat(
                icon: Icons.bolt,
                color: AppTheme.secondary,
                value: '${gameState.exp} XP',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeartsRow extends StatelessWidget {
  final int lives;
  const _HeartsRow({required this.lives});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          Icons.favorite,
          size: 14,
          color: i < lives ? AppTheme.error : AppTheme.surfaceLight,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(
        value,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════
// DAILY CHALLENGE CARD
// ═══════════════════════════════════════════════════════════════
class _DailyChallengeCard extends StatelessWidget {
  final UserStats? stats;
  const _DailyChallengeCard({this.stats});

  @override
  Widget build(BuildContext context) {
    final completed = stats?.dailyCompleted ?? 0;
    final goal = stats?.dailyGoal ?? 5;
    final progress = (completed / goal).clamp(0.0, 1.0);
    final isDone = completed >= goal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (isDone ? AppTheme.accent : AppTheme.secondary).withValues(
                alpha: 0.15,
              ),
              AppTheme.primary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDone ? AppTheme.accent : AppTheme.secondary).withValues(
              alpha: 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDone ? AppTheme.accent : AppTheme.secondary)
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone
                        ? Icons.emoji_events_rounded
                        : Icons.local_fire_department,
                    color: isDone ? AppTheme.accent : AppTheme.secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDone
                            ? 'Daily Challenge Complete! 🎉'
                            : 'Daily Challenge',
                        style: TextStyle(
                          color: isDone ? AppTheme.accent : AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isDone
                            ? 'You earned +150 XP & 30 Coins!'
                            : 'Complete $goal questions → +150 XP & 30 Coins',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isDone ? AppTheme.accent : AppTheme.secondary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$completed/$goal',
                    style: TextStyle(
                      color: isDone ? AppTheme.accent : AppTheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? AppTheme.accent : AppTheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION TITLE
// ═══════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY ROW  (real data from Django)
// ═══════════════════════════════════════════════════════════════
class _CategoryRow extends StatelessWidget {
  final List<Category> categories;
  const _CategoryRow({required this.categories});

  static const _catColors = [
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFFF6B35),
    Color(0xFF3B82F6),
    Color(0xFF84CC16),
  ];
  static const _catIcons = [
    Icons.calculate,
    Icons.psychology,
    Icons.code,
    Icons.menu_book,
    Icons.account_tree,
    Icons.lightbulb,
    Icons.school,
    Icons.quiz_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final color = _catColors[i % _catColors.length];
          final icon = _catIcons[i % _catIcons.length];

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryPracticeScreen(category: cat),
              ),
            ),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cat.questionCount} Qs',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROGRESS STATS  (real data from Django)
// ═══════════════════════════════════════════════════════════════
class _ProgressStats extends StatelessWidget {
  final UserStats? stats;
  const _ProgressStats({this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final items = [
      {
        'label': 'Questions\nAttempted',
        'value': '${s?.totalAttempted ?? 0}',
        'icon': Icons.quiz,
        'color': AppTheme.primary,
      },
      {
        'label': 'Accuracy',
        'value': s != null ? '${s.accuracy}%' : '—',
        'icon': Icons.track_changes,
        'color': AppTheme.secondary,
      },
      {
        'label': 'Streak\n(Days)',
        'value': '${s?.streak ?? 0}',
        'icon': Icons.local_fire_department,
        'color': AppTheme.accent,
      },
      {
        'label': 'Tests\nPassed',
        'value': '${s?.testsPassed ?? 0}',
        'icon': Icons.verified,
        'color': const Color(0xFF06B6D4),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              final color = item['color'] as Color;
              return Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, color: color, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['value'] as String,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            item['label'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LEADERBOARD LIST  (real data from Django)
// ═══════════════════════════════════════════════════════════════
class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _LeaderboardList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState(
        message: 'No rankers yet.\nBe the first to complete a test!',
      );
    }

    final medals = ['🥇', '🥈', '🥉'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            ...entries.asMap().entries.map((e) {
              final i = e.key;
              final entry = e.value;
              final medal = i < 3 ? medals[i] : '#${entry.rank}';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: i < entries.length - 1
                      ? Border(
                          bottom: BorderSide(
                            color: AppTheme.surfaceLight.withValues(alpha: 0.4),
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        medal,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: i < 3 ? 20 : 13,
                          color: i < 3 ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.7),
                            AppTheme.secondary.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          entry.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.username,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (entry.interestedField.isNotEmpty)
                            Text(
                              entry.interestedField,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lvl ${entry.level}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${entry.exp} XP',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    ),
  );
}
