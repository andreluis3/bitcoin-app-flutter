import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/bitcoin_candle.dart';
import '../../data/models/bitcoin_price.dart';
import '../../data/repositories/bitcoin_repository.dart';

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
  int _refreshId = 0;

  @override
  MarketState build() {
    _repository = ref.watch(bitcoinRepositoryProvider);
    Future.microtask(refresh);

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

  Future<void> refresh() async {
    final refreshId = ++_refreshId;
    final currency = state.currency;
    final selectedPeriod = state.selectedPeriod;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearError: true,
    );

    try {
      final price = await _repository.getCurrentPrice(currency: currency);
      final chartData = await _repository.getCandles(
        period: selectedPeriod,
        currency: currency,
      );
      if (refreshId != _refreshId) return;

      final currencyChanged = state.price.currency != currency;

      state = state.copyWith(
        price: price,
        chartData: chartData,
        upperLimit: currencyChanged || state.upperLimit == 0
            ? price.price * 1.05
            : state.upperLimit,
        lowerLimit: currencyChanged || state.lowerLimit == 0
            ? price.price * 0.95
            : state.lowerLimit,
        isLoading: false,
        errorMessage: null,
        clearError: true,
      );
    } on Exception catch (error) {
      if (refreshId != _refreshId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível carregar os dados da Binance: $error',
      );
    }
  }

  void setCurrency(MarketCurrency currency) {
    state = state.copyWith(currency: currency);
    refresh();
  }

  void setPeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
    refresh();
  }

  void updateThresholds({
    required double upperLimit,
    required double lowerLimit,
  }) {
    if (upperLimit <= lowerLimit || upperLimit <= 0 || lowerLimit <= 0) {
      return;
    }
    state = state.copyWith(upperLimit: upperLimit, lowerLimit: lowerLimit);
  }
}

final marketControllerProvider =
    NotifierProvider<MarketController, MarketState>(MarketController.new);
