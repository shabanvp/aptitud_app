class User {
  final String id;
  final String username;
  final String email;
  final int level;
  final int exp;
  final int coins;
  final int lives;
  final String? avatar;
  final bool isCompany;
  final String? interestedField;
  final String? currentStatus;
  final String? hiringFocus;
  final String? organization;
  
  User({
    required this.id,
    required this.username,
    required this.email,
    this.level = 1,
    this.exp = 0,
    this.coins = 0,
    this.lives = 5,
    this.avatar,
    this.isCompany = false,
    this.interestedField,
    this.currentStatus,
    this.hiringFocus,
    this.organization,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      level: json['level'] is int ? json['level'] : int.tryParse(json['level']?.toString() ?? '') ?? 1,
      exp: json['exp'] is int ? json['exp'] : int.tryParse(json['exp']?.toString() ?? '') ?? 0,
      coins: json['coins'] is int ? json['coins'] : int.tryParse(json['coins']?.toString() ?? '') ?? 0,
      lives: json['lives'] is int ? json['lives'] : int.tryParse(json['lives']?.toString() ?? '') ?? 5,
      avatar: json['avatar'],
      isCompany: json['is_company'] == true,
      interestedField: json['interested_field'],
      currentStatus: json['current_status'],
      hiringFocus: json['hiring_focus'],
      organization: json['organization'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'level': level,
      'exp': exp,
      'coins': coins,
      'lives': lives,
      'avatar': avatar,
      'is_company': isCompany,
      'interested_field': interestedField,
      'current_status': currentStatus,
      'hiring_focus': hiringFocus,
      'organization': organization,
    };
  }

  factory User.mockCandidate() {
    return User(
      id: '1',
      username: 'alex_dev',
      email: 'alex@example.com',
      level: 5,
      exp: 1200,
      coins: 450,
      lives: 3,
      isCompany: false,
      interestedField: 'Software Engineering',
      currentStatus: 'Student',
    );
  }

  factory User.mockCompany() {
    return User(
      id: '2',
      username: 'tech_corp',
      email: 'hr@techcorp.com',
      isCompany: true,
      organization: 'Tech Corp',
      hiringFocus: 'Full Stack Developers',
    );
  }
}

class CandidateAttempt {
  final String category;
  final int score;
  final String? completedAt;

  CandidateAttempt({
    required this.category,
    required this.score,
    this.completedAt,
  });

  factory CandidateAttempt.fromJson(Map<String, dynamic> json) {
    return CandidateAttempt(
      category: json['category'] ?? 'General',
      score: json['score'] is int ? json['score'] : int.tryParse(json['score']?.toString() ?? '') ?? 0,
      completedAt: json['completed_at'] as String?,
    );
  }
}

class CandidateCategoryStat {
  final String category;
  final double avgScore;
  final int count;

  CandidateCategoryStat({
    required this.category,
    required this.avgScore,
    required this.count,
  });

  factory CandidateCategoryStat.fromJson(Map<String, dynamic> json) {
    return CandidateCategoryStat(
      category: json['category'] ?? 'General',
      avgScore: json['avg_score'] is num ? (json['avg_score'] as num).toDouble() : double.tryParse(json['avg_score']?.toString() ?? '') ?? 0.0,
      count: json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '') ?? 0,
    );
  }
}

class CandidateProfile {
  final User user;
  final int totalAttempts;
  final List<CandidateAttempt> recentAttempts;
  final List<CandidateCategoryStat> categoryStats;

  CandidateProfile({
    required this.user,
    required this.totalAttempts,
    required this.recentAttempts,
    required this.categoryStats,
  });

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    return CandidateProfile(
      user: User.fromJson(json['candidate'] as Map<String, dynamic>),
      totalAttempts: json['candidate']['total_attempts'] is int
          ? json['candidate']['total_attempts']
          : int.tryParse(json['candidate']['total_attempts']?.toString() ?? '') ?? 0,
      recentAttempts: (json['candidate']['recent_attempts'] as List?)?.map((item) => CandidateAttempt.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      categoryStats: (json['candidate']['category_stats'] as List?)?.map((item) => CandidateCategoryStat.fromJson(item as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class CandidateListResponse {
  final List<User> candidates;
  final int newCandidatesCount;
  final int totalCandidates;

  CandidateListResponse({
    required this.candidates,
    required this.newCandidatesCount,
    required this.totalCandidates,
  });

  factory CandidateListResponse.fromJson(Map<String, dynamic> json) {
    return CandidateListResponse(
      candidates: (json['candidates'] as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList(),
      newCandidatesCount: json['new_candidates_count'] is int
          ? json['new_candidates_count']
          : int.tryParse(json['new_candidates_count']?.toString() ?? '') ?? 0,
      totalCandidates: json['total_candidates'] is int
          ? json['total_candidates']
          : int.tryParse(json['total_candidates']?.toString() ?? '') ?? 0,
    );
  }
}
