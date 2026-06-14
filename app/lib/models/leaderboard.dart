class LeaderboardEntry {
  final int rank;
  final String username;
  final int level;
  final int exp;
  final int coins;
  final double avgScore;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.level,
    required this.exp,
    required this.coins,
    required this.avgScore,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      username: json['username'] ?? '',
      level: json['level'] ?? 1,
      exp: json['exp'] ?? 0,
      coins: json['coins'] ?? 0,
      avgScore: (json['avg_score'] ?? 0.0).toDouble(),
    );
  }
}

class UserStats {
  final int totalAttempts;
  final double avgScore;
  final int coinsEarned;
  final int levelReached;
  final List<CategoryStat> categoryStats;

  UserStats({
    required this.totalAttempts,
    required this.avgScore,
    required this.coinsEarned,
    required this.levelReached,
    required this.categoryStats,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalAttempts: json['total_attempts'] ?? 0,
      avgScore: (json['avg_score'] ?? 0.0).toDouble(),
      coinsEarned: json['coins_earned'] ?? 0,
      levelReached: json['level_reached'] ?? 1,
      categoryStats: (json['category_stats'] as List?)
          ?.map((c) => CategoryStat.fromJson(c))
          .toList() ??
          [],
    );
  }
}

class CategoryStat {
  final String category;
  final double avgScore;
  final int attemptCount;

  CategoryStat({
    required this.category,
    required this.avgScore,
    required this.attemptCount,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] ?? '',
      avgScore: (json['avg_score'] ?? 0.0).toDouble(),
      attemptCount: json['count'] ?? 0,
    );
  }
}
