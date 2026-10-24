import '../data/models/market_alert.dart';
import '../data/repositories/bitcoin_repository.dart';

class AlertService {
  AlertService(this._repository);

  final BitcoinRepository _repository;

  Future<List<MarketAlert>> getAlertHistory() {
    return _repository.getAlertHistory();
  }

  bool validateThresholds({
    required double upperLimit,
    required double lowerLimit,
  }) {
    return upperLimit > lowerLimit;
  }
}
