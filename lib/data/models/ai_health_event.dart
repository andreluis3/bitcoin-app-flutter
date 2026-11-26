
class AiHealthEvent {
  const AiHealthEvent({required this.id, required this.type, required this.message, required this.createdAt, this.model});
  final String id, type, message;
  final DateTime createdAt;
  final String? model;
  Map<String, dynamic> toMap() => {
    'id': id, 'type': type, 'message': message,
    'createdAt': createdAt.toIso8601String(), 'model': model,
  };
}
