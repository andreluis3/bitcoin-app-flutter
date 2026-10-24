import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/market_alert.dart';
import '../data/models/bitcoin_price.dart';
import '../data/repositories/bitcoin_repository.dart';

class AlertService {
  AlertService(this._repository);

  final BitcoinRepository _repository;

  static const _historyKey = 'btc_market_alert_history_v1';
  static const _maxHistory = 100;

  Future<List<MarketAlert>> getAlertHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);

    if (raw == null || raw.isEmpty) {
      return <MarketAlert>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return <MarketAlert>[];
      }

      final history = decoded
          .whereType<Map>()
          .map(
            (item) => MarketAlert.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      history.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return history;
    } catch (_) {
      return <MarketAlert>[];
    }
  }

  Future<List<MarketAlert>> checkThresholds({
    required double previousPrice,
    required double currentPrice,
    required double upperLimit,
    required double lowerLimit,
    required MarketCurrency currency,
  }) async {
    final currencyCode =
        currency == MarketCurrency.usd ? 'USD' : 'BRL';

    final events = <MarketAlert>[];

    // Dispara apenas quando o preço cruza o limite,
    // não em cada atualização acima ou abaixo dele.
    if (previousPrice < upperLimit &&
        currentPrice >= upperLimit) {
      events.add(
        _createAlert(
          direction: AlertDirection.up,
          price: currentPrice,
          threshold: upperLimit,
          currency: currencyCode,
        ),
      );
    }

    if (previousPrice > lowerLimit &&
        currentPrice <= lowerLimit) {
      events.add(
        _createAlert(
          direction: AlertDirection.down,
          price: currentPrice,
          threshold: lowerLimit,
          currency: currencyCode,
        ),
      );
    }

    if (events.isNotEmpty) {
      // Garante uma lista modificável antes de inserir os eventos.
      final history = List<MarketAlert>.from(
        await getAlertHistory(),
      );

      history.insertAll(0, events);

      final limited = history
          .take(_maxHistory)
          .map((alert) => alert.toJson())
          .toList();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _historyKey,
        jsonEncode(limited),
      );
    }

    return events;
  }

  MarketAlert _createAlert({
    required AlertDirection direction,
    required double price,
    required double threshold,
    required String currency,
  }) {
    final now = DateTime.now();

    return MarketAlert(
      id: '${now.microsecondsSinceEpoch}_${direction.name}',
      direction: direction,
      price: price,
      threshold: threshold,
      createdAt: now,
      currency: currency,
    );
  }

  bool validateThresholds({
    required double upperLimit,
    required double lowerLimit,
  }) =>
      upperLimit > lowerLimit && lowerLimit > 0;
}

final alertServiceProvider = Provider<AlertService>((ref) {
  return AlertService(ref.watch(bitcoinRepositoryProvider));
});
