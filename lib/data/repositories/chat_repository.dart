import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/chat_message.dart';

class ChatRepository {
  static const _messagesBoxName = 'btc_chat_messages';
  static const _metadataBoxName = 'btc_chat_metadata';
  static const _lastInteractionKey = 'last_interaction_id';

  Box<dynamic> get _messagesBox => Hive.box(_messagesBoxName);
  Box<dynamic> get _metadataBox => Hive.box(_metadataBoxName);

  Future<List<ChatMessage>> getMessages() async {
    final messages = _messagesBox.values
        .whereType<Map>()
        .map((value) => ChatMessage.fromMap(
              Map<String, dynamic>.from(value),
            ))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return messages;
  }

  Future<void> saveMessage(ChatMessage message) async {
    await _messagesBox.put(message.id, message.toMap());
  }

  String? getLastInteractionId() {
    return _metadataBox.get(_lastInteractionKey) as String?;
  }

  Future<void> saveLastInteractionId(String interactionId) async {
    await _metadataBox.put(_lastInteractionKey, interactionId);
  }

  Future<void> clearConversation() async {
    await _messagesBox.clear();
    await _metadataBox.delete(_lastInteractionKey);
  }
}
