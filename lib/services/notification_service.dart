
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    await _plugin.initialize(settings: settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  Future<void> showMarketAlert(MarketAlert alert) async {
    await initialize();

    final isUp = alert.direction == AlertDirection.up;
    final currencySymbol = alert.currency == 'BRL' ? 'R\$' : '\$';

    const androidDetails = AndroidNotificationDetails(
      // Novo ID para criar um canal com a configuração de som atualizada.
      'btc_price_alerts_v2',
      'Alertas de preço do Bitcoin',
      channelDescription:
          'Alertas sonoros quando o Bitcoin atinge um limite configurado.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('btc_alert'),
    );

    await _plugin.show(
      id: alert.id.hashCode,
      title: isUp
          ? 'Bitcoin atingiu o limite superior'
          : 'Bitcoin atingiu o limite inferior',
      body:
          'Preço: $currencySymbol${alert.price.toStringAsFixed(2)} · '
          'Limite: $currencySymbol${alert.threshold.toStringAsFixed(2)}',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
