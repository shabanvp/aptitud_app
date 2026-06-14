class Message {
  final int id;
  final String sender;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }
}

class Conversation {
  final int id;
  final List<String> participants;
  final List<Message> messages;
  final DateTime updatedAt;
  String? otherUsername;

  Conversation({
    required this.id,
    required this.participants,
    required this.messages,
    required this.updatedAt,
    this.otherUsername,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? 0,
      participants: List<String>.from(json['participants'] ?? []),
      messages: (json['messages'] as List?)?.map((m) => Message.fromJson(m)).toList() ?? [],
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      otherUsername: json['other_user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'messages': messages.map((m) => m.toJson()).toList(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
