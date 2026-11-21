class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String content;
  final ChatMessageRole role;
  final DateTime createdAt;

  bool get isUser => role == ChatMessageRole.user;

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      content: map['content'] as String,
      role: ChatMessageRole.values.firstWhere(
        (value) => value.name == map['role'],
        orElse: () => ChatMessageRole.assistant,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

enum ChatMessageRole { user, assistant }
