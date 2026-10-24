import '../data/models/bitcoin_candle.dart';
import '../data/models/bitcoin_price.dart';
import '../data/repositories/bitcoin_repository.dart';

class MarketDataService {
  MarketDataService(this._repository);

  final BitcoinRepository _repository;

  Future<BitcoinPrice> fetchCurrentPrice({
    MarketCurrency currency = MarketCurrency.usd,
  }) {
    return _repository.getCurrentPrice(currency: currency);
  }

  Future<List<BitcoinCandle>> fetchChartData({
    required String period,
    MarketCurrency currency = MarketCurrency.usd,
  }) {
    return _repository.getCandles(period: period, currency: currency);
  }
}
