import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/bitcoin_candle.dart';
import '../../data/models/bitcoin_price.dart';
import '../../data/models/market_alert.dart';
import '../../data/repositories/bitcoin_repository.dart';
import '../../services/alert_service.dart';
import '../../services/notification_service.dart';

class MarketState {
  const MarketState({
    required this.currency,
    required this.selectedPeriod,
    required this.price,
    required this.chartData,
    required this.upperLimit,
    required this.lowerLimit,
    required this.isLoading,
    required this.errorMessage,
  });

  final MarketCurrency currency;
  final String selectedPeriod;
  final BitcoinPrice price;
  final List<BitcoinCandle> chartData;
  final double upperLimit;
  final double lowerLimit;
  final bool isLoading;
  final String? errorMessage;

  MarketState copyWith({
    MarketCurrency? currency,
    String? selectedPeriod,
    BitcoinPrice? price,
    List<BitcoinCandle>? chartData,
    double? upperLimit,
    double? lowerLimit,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MarketState(
      currency: currency ?? this.currency,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      price: price ?? this.price,
      chartData: chartData ?? this.chartData,
      upperLimit: upperLimit ?? this.upperLimit,
      lowerLimit: lowerLimit ?? this.lowerLimit,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class MarketController extends Notifier<MarketState> {
  late BitcoinRepository _repository;
  late AlertService _alertService;
  late NotificationService _notificationService;
  Timer? _refreshTimer;
  int _refreshId = 0;
  bool _isRefreshing = false;
  double? _previousPrice;
  bool _limitsLoaded = false;

  static const _upperKeyPrefix = 'btc_alert_upper_';
  static const _lowerKeyPrefix = 'btc_alert_lower_';

  @override
  MarketState build() {
    _repository = ref.watch(bitcoinRepositoryProvider);
    _alertService = ref.watch(alertServiceProvider);
    _notificationService = ref.watch(notificationServiceProvider);

    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    Future.microtask(() async {
      await _loadLimits();
      await _notificationService.initialize();
      await refresh();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => refresh(silent: true),
      );
    });

    return MarketState(
      currency: MarketCurrency.usd,
      selectedPeriod: '24H',
      price: BitcoinPrice(
        price: 0,
        currency: MarketCurrency.usd,
        changePercent24h: 0,
        timestamp: DateTime.now(),
      ),
      chartData: const [],
      upperLimit: 0,
      lowerLimit: 0,
      isLoading: true,
      errorMessage: null,
    );
  }

  Future<void> _loadLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyKey = _currencyKey(state.currency);
    final upper = prefs.getDouble('$_upperKeyPrefix$currencyKey');
    final lower = prefs.getDouble('$_lowerKeyPrefix$currencyKey');
    if (upper != null && lower != null && upper > lower && lower > 0) {
      state = state.copyWith(upperLimit: upper, lowerLimit: lower);
    }
    _limitsLoaded = true;
  }

  String _currencyKey(MarketCurrency currency) =>
      currency == MarketCurrency.usd ? 'USD' : 'BRL';

  Future<void> refresh({bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    final refreshId = ++_refreshId;
    final currency = state.currency;
    final selectedPeriod = state.selectedPeriod;

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final results = await Future.wait<Object>([
        _repository.getCurrentPrice(currency: currency),
        _repository.getCandles(period: selectedPeriod, currency: currency),
      ]);
      if (refreshId != _refreshId) return;

      final price = results[0] as BitcoinPrice;
      final candles = results[1] as List<BitcoinCandle>;
      final currencyChanged = state.price.currency != currency;

      var upper = state.upperLimit;
      var lower = state.lowerLimit;

      if (!_limitsLoaded || currencyChanged || upper <= 0 || lower <= 0) {
        final prefs = await SharedPreferences.getInstance();
        final key = _currencyKey(currency);
        final savedUpper = prefs.getDouble('$_upperKeyPrefix$key');
        final savedLower = prefs.getDouble('$_lowerKeyPrefix$key');
        if (savedUpper != null && savedLower != null &&
            savedUpper > savedLower && savedLower > 0) {
          upper = savedUpper;
          lower = savedLower;
        } else {
          upper = price.price * 1.05;
          lower = price.price * 0.95;
        }
      }

      final previous = _previousPrice;
      if (previous != null && previous > 0 && previous != price.price) {
        final triggered = await _alertService.checkThresholds(
          previousPrice: previous,
          currentPrice: price.price,
          upperLimit: upper,
          lowerLimit: lower,
          currency: currency,
        );
        for (final alert in triggered) {
          await _notificationService.showMarketAlert(alert);
        }
      }
      _previousPrice = price.price;

      state = state.copyWith(
        price: price,
        chartData: candles,
        upperLimit: upper,
        lowerLimit: lower,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      if (refreshId == _refreshId) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Não foi possível carregar os dados da Binance: $error',
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> setCurrency(MarketCurrency currency) async {
    if (currency == state.currency) return;
    _previousPrice = null;
    state = state.copyWith(currency: currency, isLoading: true, clearError: true);
    await _loadLimitsFor(currency);
    await refresh();
  }

  Future<void> _loadLimitsFor(MarketCurrency currency) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _currencyKey(currency);
    final upper = prefs.getDouble('$_upperKeyPrefix$key');
    final lower = prefs.getDouble('$_lowerKeyPrefix$key');
    state = state.copyWith(
      upperLimit: upper ?? 0,
      lowerLimit: lower ?? 0,
    );
  }

  Future<void> setPeriod(String period) async {
    if (period == state.selectedPeriod) return;
    state = state.copyWith(selectedPeriod: period, isLoading: true);
    await refresh();
  }

  Future<bool> updateThresholds({
    required double upperLimit,
    required double lowerLimit,
  }) async {
    if (upperLimit <= lowerLimit || upperLimit <= 0 || lowerLimit <= 0) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _currencyKey(state.currency);
    final upperSaved = await prefs.setDouble('$_upperKeyPrefix$key', upperLimit);
    final lowerSaved = await prefs.setDouble('$_lowerKeyPrefix$key', lowerLimit);
    if (!upperSaved || !lowerSaved) return false;

    state = state.copyWith(upperLimit: upperLimit, lowerLimit: lowerLimit);
    return true;
  }
}

final marketControllerProvider =
    NotifierProvider<MarketController, MarketState>(MarketController.new);
