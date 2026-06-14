class QuestionOption {
  final String id;
  final String text;
  final bool isCorrect;

  QuestionOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> j) => QuestionOption(
    id: j['id'].toString(),
    text: j['text'] ?? '',
    isCorrect: j['is_correct'] == true,
  );
}

class Question {
  final String id;
  final String text;
  final String category;
  final String categorySlug;
  final String difficulty;
  final String type;
  final List<QuestionOption> options;
  final int timeLimit;
  final String explanation;

  Question({
    required this.id,
    required this.text,
    required this.category,
    this.categorySlug = '',
    this.difficulty = 'MEDIUM',
    this.type = 'MCQ',
    required this.options,
    this.timeLimit = 60,
    this.explanation = '',
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    id: j['id'].toString(),
    text: j['text'] ?? '',
    category: j['category'] ?? '',
    categorySlug: j['category_slug'] ?? '',
    difficulty: j['difficulty'] ?? 'MEDIUM',
    type: j['question_type'] ?? 'MCQ',
    options: (j['options'] as List<dynamic>? ?? [])
        .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
        .toList(),
    timeLimit: j['time_limit'] ?? 60,
    explanation: j['explanation'] ?? '',
  );

  bool get requiresWrittenAnswer => type == 'CODING' || options.length <= 1;
}

class Category {
  final int id;
  final String name;
  final String slug;
  final String description;
  final int questionCount;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.questionCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    slug: j['slug'] ?? '',
    description: j['description'] ?? '',
    questionCount: j['question_count'] ?? 0,
  );
}

class LeaderboardEntry {
  final int rank;
  final String username;
  final int level;
  final int exp;
  final int coins;
  final String interestedField;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.level,
    required this.exp,
    required this.coins,
    this.interestedField = '',
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    rank: j['rank'] ?? 0,
    username: j['username'] ?? '',
    level: j['level'] ?? 1,
    exp: j['exp'] ?? 0,
    coins: j['coins'] ?? 0,
    interestedField: j['interested_field'] ?? '',
  );
}

class UserStats {
  final int totalAttempted;
  final double accuracy;
  final int testsPassed;
  final int streak;
  final int dailyCompleted;
  final int dailyGoal;

  UserStats({
    this.totalAttempted = 0,
    this.accuracy = 0,
    this.testsPassed = 0,
    this.streak = 0,
    this.dailyCompleted = 0,
    this.dailyGoal = 5,
  });

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
    totalAttempted: j['total_attempted'] ?? 0,
    accuracy: (j['accuracy'] ?? 0).toDouble(),
    testsPassed: j['tests_passed'] ?? 0,
    streak: j['streak'] ?? 0,
    dailyCompleted: j['daily_completed'] ?? 0,
    dailyGoal: j['daily_goal'] ?? 5,
  );
}
