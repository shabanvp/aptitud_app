class Profile {
  final String id;
  final String username;
  final String email;
  final int level;
  final int exp;
  final int coins;
  final int lives;
  final String avatar;
  final String? interestedField;
  final String? currentStatus;
  final String? organization;
  final String? hiringFocus;
  final bool isCompany;
  final DateTime dateJoined;
  final List<dynamic>? recentAttempts;
  final List<dynamic>? categoryStats;
  final int? totalAttempts;

  Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.level,
    required this.exp,
    required this.coins,
    required this.lives,
    required this.avatar,
    this.interestedField,
    this.currentStatus,
    this.organization,
    this.hiringFocus,
    required this.isCompany,
    required this.dateJoined,
    this.recentAttempts,
    this.categoryStats,
    this.totalAttempts,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      level: json['level'] ?? 1,
      exp: json['exp'] ?? 0,
      coins: json['coins'] ?? 0,
      lives: json['lives'] ?? 5,
      avatar: json['avatar'] ?? '',
      interestedField: json['interested_field'],
      currentStatus: json['current_status'],
      organization: json['organization'],
      hiringFocus: json['hiring_focus'],
      isCompany: json['is_company'] ?? false,
      dateJoined: DateTime.parse(json['date_joined'] ?? DateTime.now().toIso8601String()),
      recentAttempts: json['recent_attempts'],
      categoryStats: json['category_stats'],
      totalAttempts: json['total_attempts'],
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
      'interested_field': interestedField,
      'current_status': currentStatus,
      'organization': organization,
      'hiring_focus': hiringFocus,
      'is_company': isCompany,
      'date_joined': dateJoined.toIso8601String(),
    };
  }
}
