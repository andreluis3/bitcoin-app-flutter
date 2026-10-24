
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

  // Identifica consultas e invalida respostas antigas.
  int _requestVersion = 0;

  // Evita consultas simultâneas e agenda uma nova se necessário.
  bool _isRefreshing = false;
  bool _refreshPending = false;

  // Evita comparar preços de moedas diferentes.
  double? _previousPrice;
  MarketCurrency? _previousCurrency;

  static const _upperKeyPrefix = 'btc_alert_upper_';
  static const _lowerKeyPrefix = 'btc_alert_lower_';

  @override
  MarketState build() {
    _repository = ref.watch(bitcoinRepositoryProvider);
    _alertService = ref.watch(alertServiceProvider);
    _notificationService = ref.watch(notificationServiceProvider);

    ref.onDispose(() {
      _requestVersion++;
      _refreshTimer?.cancel();
    });

    Future.microtask(_initialize);

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

  Future<void> _initialize() async {
    try {
      await _loadLimitsFor(state.currency);
    } catch (_) {
      // Se a leitura falhar, a consulta de mercado ainda pode continuar.
    }

    try {
      await _notificationService.initialize();
    } catch (_) {
      // Uma falha nas notificações não deve impedir a consulta da Binance.
    }

    await refresh();

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refresh(silent: true),
    );
  }

  String _currencyKey(MarketCurrency currency) {
    return currency == MarketCurrency.usd ? 'USD' : 'BRL';
  }

  bool _validLimits(double upper, double lower) {
    return upper.isFinite &&
        lower.isFinite &&
        lower > 0 &&
        upper > lower;
  }

  bool _isCurrentRequest(
    int requestVersion,
    MarketCurrency currency,
    String period,
  ) {
    return requestVersion == _requestVersion &&
        currency == state.currency &&
        period == state.selectedPeriod;
  }

  Future<void> _loadLimitsFor(MarketCurrency currency) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _currencyKey(currency);

    final upper = prefs.getDouble('$_upperKeyPrefix$key');
    final lower = prefs.getDouble('$_lowerKeyPrefix$key');

    final hasValidLimits =
        upper != null &&
        lower != null &&
        _validLimits(upper, lower);

    // Não aplique limites de uma moeda que deixou de estar selecionada.
    if (currency != state.currency) return;

    state = state.copyWith(
      upperLimit: hasValidLimits ? upper : 0,
      lowerLimit: hasValidLimits ? lower : 0,
    );
  }

  Future<void> refresh({bool silent = false}) async {
    // Cada nova solicitação invalida as respostas de consultas anteriores.
    _requestVersion++;

    if (_isRefreshing) {
      _refreshPending = true;
      return;
    }

    _isRefreshing = true;

    try {
      while (true) {
        _refreshPending = false;

        final requestVersion = _requestVersion;
        final currency = state.currency;
        final period = state.selectedPeriod;

        if (!silent) {
          state = state.copyWith(
            isLoading: true,
            clearError: true,
          );
        }

        try {
          final results = await Future.wait<Object>([
            _repository.getCurrentPrice(currency: currency),
            _repository.getCandles(
              period: period,
              currency: currency,
            ),
          ]);

          if (!_isCurrentRequest(requestVersion, currency, period)) {
            // Alguma configuração mudou durante a consulta.
            continue;
          }

          final price = results[0] as BitcoinPrice;
          final candles = results[1] as List<BitcoinCandle>;

          var upper = state.upperLimit;
          var lower = state.lowerLimit;

          if (!_validLimits(upper, lower)) {
            final prefs = await SharedPreferences.getInstance();

            if (!_isCurrentRequest(requestVersion, currency, period)) {
              continue;
            }

            final key = _currencyKey(currency);
            final savedUpper =
                prefs.getDouble('$_upperKeyPrefix$key');
            final savedLower =
                prefs.getDouble('$_lowerKeyPrefix$key');

            if (savedUpper != null &&
                savedLower != null &&
                _validLimits(savedUpper, savedLower)) {
              upper = savedUpper;
              lower = savedLower;
            } else {
              // Limites padrão: 5% acima e 5% abaixo do preço.
              upper = price.price * 1.05;
              lower = price.price * 0.95;
            }
          }

          if (!_isCurrentRequest(requestVersion, currency, period)) {
            continue;
          }

          final previous = _previousPrice;
          final sameCurrency = _previousCurrency == currency;

          if (sameCurrency &&
              previous != null &&
              previous > 0 &&
              price.price > 0 &&
              previous != price.price &&
              _validLimits(upper, lower)) {
            final triggered = await _alertService.checkThresholds(
              previousPrice: previous,
              currentPrice: price.price,
              upperLimit: upper,
              lowerLimit: lower,
              currency: currency,
            );

            if (!_isCurrentRequest(requestVersion, currency, period)) {
              continue;
            }

            for (final alert in triggered) {
              if (!_isCurrentRequest(
                requestVersion,
                currency,
                period,
              )) {
                break;
              }

              try {
                await _notificationService.showMarketAlert(alert);
              } catch (_) {
                // Falha na notificação não deve interromper o mercado.
              }
            }
          }

          if (!_isCurrentRequest(requestVersion, currency, period)) {
            continue;
          }

          _previousPrice = price.price;
          _previousCurrency = currency;

          state = state.copyWith(
            price: price,
            chartData: candles,
            upperLimit: upper,
            lowerLimit: lower,
            isLoading: false,
            clearError: true,
          );

          // Se uma nova solicitação chegou durante o processamento,
          // execute outra consulta com as configurações atuais.
          if (_refreshPending ||
              requestVersion != _requestVersion) {
            continue;
          }

          break;
        } catch (error) {
          if (!_isCurrentRequest(requestVersion, currency, period)) {
            continue;
          }

          state = state.copyWith(
            isLoading: false,
            errorMessage:
                'Não foi possível carregar os dados da Binance: $error',
          );

          if (_refreshPending ||
              requestVersion != _requestVersion) {
            continue;
          }

          break;
        }
      }
    } finally {
      _isRefreshing = false;

      // Proteção adicional caso uma solicitação tenha chegado
      // durante a finalização da consulta.
      if (_refreshPending) {
        unawaited(refresh(silent: true));
      }
    }
  }

  Future<void> setCurrency(MarketCurrency currency) async {
    if (currency == state.currency) return;

    // Invalida imediatamente as respostas da moeda anterior.
    _requestVersion++;
    _previousPrice = null;
    _previousCurrency = null;

    state = state.copyWith(
      currency: currency,
      upperLimit: 0,
      lowerLimit: 0,
      isLoading: true,
      clearError: true,
    );

    try {
      await _loadLimitsFor(currency);
    } catch (_) {
      // O refresh continuará mesmo se não for possível ler as preferências.
    }

    await refresh();
  }

  Future<void> setPeriod(String period) async {
    const supportedPeriods = {'1H', '24H', '7D', '1M', '1Y'};

    if (!supportedPeriods.contains(period)) return;
    if (period == state.selectedPeriod) return;

    // Invalida consultas que usavam o período anterior.
    _requestVersion++;

    state = state.copyWith(
      selectedPeriod: period,
      isLoading: true,
      clearError: true,
    );

    await refresh();
  }

  Future<bool> updateThresholds({
    required double upperLimit,
    required double lowerLimit,
  }) async {
    // Valida antes de tocar nas preferências ou no estado.
    if (!_validLimits(upperLimit, lowerLimit)) {
      return false;
    }

    final currency = state.currency;
    final key = _currencyKey(currency);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Guarda os valores antigos para reverter uma gravação parcial.
      final upperKey = '$_upperKeyPrefix$key';
      final lowerKey = '$_lowerKeyPrefix$key';

      final oldUpper = prefs.getDouble(upperKey);
      final oldLower = prefs.getDouble(lowerKey);

      final upperSaved = await prefs.setDouble(
        upperKey,
        upperLimit,
      );

      if (!upperSaved) return false;

      final lowerSaved = await prefs.setDouble(
        lowerKey,
        lowerLimit,
      );

      if (!lowerSaved) {
        // Reverte o primeiro valor se o segundo não for salvo.
        if (oldUpper != null) {
          await prefs.setDouble(upperKey, oldUpper);
        } else {
          await prefs.remove(upperKey);
        }

        return false;
      }

      // A moeda pode ter mudado enquanto os dados eram gravados.
      // Nesse caso, mantenha a persistência da moeda original, mas
      // não aplique os limites à moeda atualmente exibida.
      if (currency == state.currency) {
        state = state.copyWith(
          upperLimit: upperLimit,
          lowerLimit: lowerLimit,
          clearError: true,
        );
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}

final marketControllerProvider =
    NotifierProvider<MarketController, MarketState>(
  MarketController.new,
);
