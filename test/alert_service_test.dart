import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monitor_btc_ai/data/models/bitcoin_price.dart';
import 'package:monitor_btc_ai/data/models/market_alert.dart';
import 'package:monitor_btc_ai/services/alert_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AlertService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = AlertService();
  });

  test('registra o primeiro alerta quando o histórico está vazio', () async {
    final events = await service.checkThresholds(
      previousPrice: 99,
      currentPrice: 101,
      upperLimit: 100,
      lowerLimit: 90,
      currency: MarketCurrency.usd,
    );

    expect(events, hasLength(1));
    expect(events.single.direction, AlertDirection.up);

    final history = await service.getAlertHistory();
    expect(history, hasLength(1));
    expect(history.single.id, events.single.id);
  });

  test('mantém os alertas mais recentes primeiro', () async {
    await service.checkThresholds(
      previousPrice: 99,
      currentPrice: 101,
      upperLimit: 100,
      lowerLimit: 90,
      currency: MarketCurrency.usd,
    );

    await Future<void>.delayed(const Duration(milliseconds: 1));

    final secondEvents = await service.checkThresholds(
      previousPrice: 91,
      currentPrice: 89,
      upperLimit: 110,
      lowerLimit: 90,
      currency: MarketCurrency.brl,
    );

    expect(secondEvents, hasLength(1));

    final history = await service.getAlertHistory();
    expect(history, hasLength(2));
    expect(history.first.id, secondEvents.single.id);
    expect(history.first.currency, 'BRL');
  });

  test('histórico inválido é tratado como vazio', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('btc_market_alert_history_v1', '{inválido');

    expect(await service.getAlertHistory(), isEmpty);

    final events = await service.checkThresholds(
      previousPrice: 99,
      currentPrice: 101,
      upperLimit: 100,
      lowerLimit: 90,
      currency: MarketCurrency.usd,
    );

    expect(events, hasLength(1));
    expect(await service.getAlertHistory(), hasLength(1));
  });
}
