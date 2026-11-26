import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';

import '../../core/errors/app_exception.dart';
import '../models/bitcoin_candle.dart';
import '../models/bitcoin_price.dart';
import '../models/market_alert.dart';

class BitcoinRepository {
  BitcoinRepository({http.Client? client}) : _client = client ?? http.Client();

  static const _hosts = [
    'api.binance.com',
    'api1.binance.com',
    'api2.binance.com',
    'api3.binance.com',
  ];
  static const _cacheMaxAge = Duration(hours: 24);
  final http.Client _client;

  void dispose() => _client.close();

  Future<BitcoinPrice> getCurrentPrice({
    MarketCurrency currency = MarketCurrency.usd,
  }) async {
    final symbol = _symbolFor(currency);
    try {
      final response = await _getWithFallback('/ticker/24hr', {'symbol': symbol});
      final json = _decodeObject(response.body);
      final price = BitcoinPrice(
        price: _parseNumber(json['lastPrice'], 'lastPrice'),
        currency: currency,
        changePercent24h: _parseNumber(json['priceChangePercent'], 'priceChangePercent'),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          _parseNumber(json['closeTime'], 'closeTime').toInt(),
          isUtc: true,
        ).toLocal(),
      );
      await _saveCache(_priceCacheKey(currency), price.toJson());
      return price;
    } catch (error) {
      final cached = await _readCache(_priceCacheKey(currency));
      if (cached != null) return BitcoinPrice.fromJson(cached);
      if (error is AppException) rethrow;
      throw AppException('Não foi possível atualizar a cotação e não há cache local disponível. $error');
    }
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

    try {
    final response = await _getWithFallback('/klines', {
      'symbol': _symbolFor(currency),
      'interval': interval,
      'limit': '$limit',
    });
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const AppException(
        'A Binance retornou candles em formato inválido.',
      );
    }

    final candles = decoded.map((entry) {
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
    await _saveCache(_candlesCacheKey(currency, period), {
      'savedAt': DateTime.now().toIso8601String(),
      'items': candles.map((candle) => candle.toJson()).toList(),
    });
    return candles;
    } catch (error) {
      final cached = await _readCache(_candlesCacheKey(currency, period));
      final items = cached?['items'];
      if (items is List) {
        return items.whereType<Map>().map((item) => BitcoinCandle.fromJson(
          Map<String, dynamic>.from(item),
        )).toList();
      }
      if (error is AppException) rethrow;
      throw AppException('Não foi possível atualizar o gráfico e não há cache local disponível. $error');
    }
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

  String _priceCacheKey(MarketCurrency currency) => 'btc_price_${currency.name}';
  String _candlesCacheKey(MarketCurrency currency, String period) =>
      'btc_candles_${currency.name}_$period';

  Future<void> _saveCache(String key, Map<String, dynamic> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode({
        ...value,
        'savedAt': DateTime.now().toIso8601String(),
      }));
    } catch (_) {
      // A falha ao persistir o cache não invalida uma resposta online válida.
    }
  }

  Future<Map<String, dynamic>?> _readCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final savedAt = DateTime.tryParse(decoded['savedAt']?.toString() ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > _cacheMaxAge) {
        return null;
      }
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<http.Response> _getWithFallback(
    String path,
    Map<String, String> queryParameters,
  ) async {
    Object? lastError;
    for (final host in _hosts) {
      final uri = Uri.https(host, '/api/v3$path', queryParameters);
      try {
        final response = await _client.get(uri).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) return response;
        // Falhas de autenticação/requisição não melhoram mudando de host.
        if (response.statusCode >= 400 && response.statusCode < 500 &&
            response.statusCode != 429) {
          throw AppException('A Binance respondeu com HTTP ${response.statusCode}.');
        }
        lastError = AppException('Endpoint $host indisponível (HTTP ${response.statusCode}).');
      } on TimeoutException catch (error) {
        lastError = error;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
    }
    throw AppException('Todos os endpoints públicos da Binance falharam. ${lastError ?? ''}');
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
