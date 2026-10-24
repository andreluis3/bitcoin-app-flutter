import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/models/market_alert.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        DarwinFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> showMarketAlert(MarketAlert alert) async {
    await initialize();
    final isUp = alert.direction == AlertDirection.up;
    final currencySymbol = alert.currency == 'BRL' ? 'R\$' : '\$';
    final details = AndroidNotificationDetails(
      'btc_price_alerts',
      'Alertas de preço do Bitcoin',
      channelDescription: 'Notificações quando o Bitcoin atinge um limite configurado.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    );

    await _plugin.show(
      alert.id.hashCode,
      isUp ? 'Bitcoin atingiu o limite superior' : 'Bitcoin atingiu o limite inferior',
      'Preço: $currencySymbol${alert.price.toStringAsFixed(2)} · '
          'Limite: $currencySymbol${alert.threshold.toStringAsFixed(2)}',
      NotificationDetails(android: details, iOS: const DarwinNotificationDetails()),
    );
  }
}
