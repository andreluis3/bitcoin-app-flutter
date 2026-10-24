import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:monitor_btc_ai/core/errors/app_exception.dart';
import 'package:monitor_btc_ai/data/models/bitcoin_price.dart';
import 'package:monitor_btc_ai/data/repositories/bitcoin_repository.dart';

void main() {
  group('BitcoinRepository', () {
    test('loads BTC/BRL price and 24-hour change from Binance', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v3/ticker/24hr');
        expect(request.url.queryParameters['symbol'], 'BTCBRL');
        return http.Response(
          jsonEncode({
            'lastPrice': '350000.50',
            'priceChangePercent': '-1.25',
            'closeTime': '1760000000000',
          }),
          200,
        );
      });
      final repository = BitcoinRepository(client: client);

      final price = await repository.getCurrentPrice(
        currency: MarketCurrency.brl,
      );

      expect(price.price, 350000.5);
      expect(price.currency, MarketCurrency.brl);
      expect(price.changePercent24h, -1.25);
      expect(price.timestamp.isUtc, isFalse);
      repository.dispose();
    });

    test(
      'requests the interval and limit for the selected chart period',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/api/v3/klines');
          expect(request.url.queryParameters, {
            'symbol': 'BTCUSDT',
            'interval': '1d',
            'limit': '30',
          });
          return http.Response(
            jsonEncode([
              [
                1760000000000,
                '100',
                '120',
                '90',
                '110',
                '1.5',
                1760003600000,
                '165',
              ],
            ]),
            200,
          );
        });
        final repository = BitcoinRepository(client: client);

        final candles = await repository.getCandles(period: '1M');

        expect(candles, hasLength(1));
        expect(candles.single.open, 100);
        expect(candles.single.close, 110);
        expect(candles.single.volume, 165);
        repository.dispose();
      },
    );

    test(
      'surfaces non-success responses instead of fabricating data',
      () async {
        final repository = BitcoinRepository(
          client: MockClient((_) async => http.Response('Unavailable', 503)),
        );

        expect(
          () => repository.getCurrentPrice(),
          throwsA(isA<AppException>()),
        );
        repository.dispose();
      },
    );
  });
}
