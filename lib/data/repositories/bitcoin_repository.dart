import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';
import '../models/bitcoin_candle.dart';
import '../models/bitcoin_price.dart';
import '../models/market_alert.dart';

class BitcoinRepository {
  BitcoinRepository({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.https('api.binance.com', '/api/v3');
  final http.Client _client;

  void dispose() => _client.close();

  Future<BitcoinPrice> getCurrentPrice({
    MarketCurrency currency = MarketCurrency.usd,
  }) async {
    final symbol = _symbolFor(currency);
    final response = await _get(
      _baseUri.replace(
        path: '${_baseUri.path}/ticker/24hr',
        queryParameters: {'symbol': symbol},
      ),
    );
    final json = _decodeObject(response.body);

    return BitcoinPrice(
      price: _parseNumber(json['lastPrice'], 'lastPrice'),
      currency: currency,
      changePercent24h: _parseNumber(
        json['priceChangePercent'],
        'priceChangePercent',
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        _parseNumber(json['closeTime'], 'closeTime').toInt(),
        isUtc: true,
      ).toLocal(),
    );
  }

  Future<List<BitcoinCandle>> getCandles({
    required String period,
    MarketCurrency currency = MarketCurrency.usd,
  }) async {
    final (interval, limit) = switch (period) {
      '1H' => ('5m', 12),
      '24H' => ('1h', 24),
      '7D' => ('4h', 42),
      '1M' => ('1d', 30),
      '1Y' => ('1w', 52),
      _ => throw AppException('Período de gráfico inválido: $period.'),
    };

    final response = await _get(
      _baseUri.replace(
        path: '${_baseUri.path}/klines',
        queryParameters: {
          'symbol': _symbolFor(currency),
          'interval': interval,
          'limit': '$limit',
        },
      ),
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const AppException(
        'A Binance retornou candles em formato inválido.',
      );
    }

    return decoded.map((entry) {
      if (entry is! List || entry.length < 8) {
        throw const AppException('A Binance retornou um candle incompleto.');
      }
      return BitcoinCandle(
        time: DateTime.fromMillisecondsSinceEpoch(
          _parseNumber(entry[0], 'openTime').toInt(),
          isUtc: true,
        ).toLocal(),
        open: _parseNumber(entry[1], 'open'),
        high: _parseNumber(entry[2], 'high'),
        low: _parseNumber(entry[3], 'low'),
        close: _parseNumber(entry[4], 'close'),
        volume: _parseNumber(entry[7], 'quoteAssetVolume'),
      );
    }).toList();
  }

  Future<List<MarketAlert>> getAlertHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final now = DateTime.now();
    return [
      MarketAlert(
        id: 'alert-1',
        direction: AlertDirection.up,
        price: 87240.0,
        threshold: 87000.0,
        createdAt: now.subtract(const Duration(hours: 2)),
        currency: 'USD',
      ),
      MarketAlert(
        id: 'alert-2',
        direction: AlertDirection.down,
        price: 86450.0,
        threshold: 86800.0,
        createdAt: now.subtract(const Duration(hours: 6)),
        currency: 'USD',
      ),
      MarketAlert(
        id: 'alert-3',
        direction: AlertDirection.up,
        price: 87890.0,
        threshold: 87500.0,
        createdAt: now.subtract(const Duration(days: 1)),
        currency: 'USD',
      ),
    ];
  }

  Future<http.Response> _get(Uri uri) async {
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw AppException(
        'A Binance respondeu com o status ${response.statusCode}.',
      );
    }
    return response;
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AppException('A Binance retornou dados em formato inválido.');
    }
    return decoded;
  }

  double _parseNumber(Object? value, String field) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null || !number.isFinite) {
      throw AppException('A Binance retornou um valor inválido para $field.');
    }
    return number;
  }

  String _symbolFor(MarketCurrency currency) {
    return currency == MarketCurrency.usd ? 'BTCUSDT' : 'BTCBRL';
  }
}

final bitcoinRepositoryProvider = Provider<BitcoinRepository>((ref) {
  final repository = BitcoinRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
