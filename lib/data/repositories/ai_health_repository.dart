import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/ai_health_event.dart';

class AiHealthRepository {
  static const String boxName = 'btc_ai_health_events';
  static const int _maxEvents = 100;

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  Future<void> add(AiHealthEvent event) async {
    await _box.put(event.id, event.toMap());

    final entries = _box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

    if (entries.length > _maxEvents) {
      final excess = entries.length - _maxEvents;
      for (final old in entries.take(excess)) {
        final id = old['id'];
        if (id != null) {
          await _box.delete(id);
        }
      }
    }
  }

  Future<List<AiHealthEvent>> getRecent({int limit = 30}) async {
    final events = <AiHealthEvent>[];

    for (final value in _box.values) {
      if (value is! Map) continue;
      final map = Map<String, dynamic>.from(value);
      final id = map['id']?.toString();
      final type = map['type']?.toString();
      final message = map['message']?.toString();
      if (id == null || type == null || message == null) continue;

      events.add(
        AiHealthEvent(
          id: id,
          type: type,
          message: message,
          createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
          model: map['model']?.toString(),
        ),
      );
    }

    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final safeLimit = limit < 0 ? 0 : limit;
    return events.take(safeLimit).toList();
  }
}
