class Event {
  final String id;
  final String title;
  final String recruiterId;
  final String recruiterUsername;
  final String category;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int totalQuestions;
  final int timeLimitSeconds;

  Event({
    required this.id,
    required this.title,
    required this.recruiterId,
    this.recruiterUsername = '',
    required this.category,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.totalQuestions = 10,
    this.timeLimitSeconds = 600,
  });

  bool get isLive {
    final now = DateTime.now();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }

  bool get isActive => isLive;

  bool get isUpcoming {
    return DateTime.now().isBefore(startTime);
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return Event(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      recruiterId:
          json['recruiter_id']?.toString() ??
          json['recruiterId']?.toString() ??
          '',
      recruiterUsername:
          json['recruiter_username'] as String? ??
          json['recruiterUsername'] as String? ??
          json['recruiter']?['username'] as String? ??
          '',
      category: category != null ? category['name'] as String? ?? '' : '',
      description: json['description'] as String? ?? '',
      startTime:
          DateTime.tryParse(json['start_time'] as String? ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(json['end_time'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      totalQuestions: json['total_questions'] as int? ?? 10,
      timeLimitSeconds: json['time_limit_seconds'] as int? ?? 600,
    );
  }
}
