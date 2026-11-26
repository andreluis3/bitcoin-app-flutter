import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/models/bitcoin_price.dart';
import 'market_controller.dart';
import 'widgets/alert_threshold_form.dart';
import 'widgets/bitcoin_chart.dart';
import 'widgets/bitcoin_price_card.dart';
import 'widgets/market_metrics.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final TextEditingController upperController = TextEditingController();
  final TextEditingController lowerController = TextEditingController();

  final ScrollController _periodScrollController = ScrollController();

  final Map<MarketCurrency, String> _upperDrafts = {};
  final Map<MarketCurrency, String> _lowerDrafts = {};

  MarketCurrency? _lastCurrency;

  double? _lastUpperLimit;
  double? _lastLowerLimit;

  bool _isEditingUpper = false;
  bool _isEditingLower = false;
  bool _isSaving = false;

  static const List<String> _periods = [
    '1H',
    '24H',
    '7D',
    '1M',
    '1Y',
  ];

  @override
  void initState() {
    super.initState();

    upperController.addListener(_onUpperChanged);
    lowerController.addListener(_onLowerChanged);
  }

  void _onUpperChanged() {
    final currency = _lastCurrency;

    if (currency == null) return;

    _upperDrafts[currency] = upperController.text;

    if (!_isEditingUpper && upperController.text.isNotEmpty) {
      _isEditingUpper = true;
    }
  }

  void _onLowerChanged() {
    final currency = _lastCurrency;

    if (currency == null) return;

    _lowerDrafts[currency] = lowerController.text;

    if (!_isEditingLower && lowerController.text.isNotEmpty) {
      _isEditingLower = true;
    }
  }

  String _formatLimit(double value) {
    return value > 0 ? value.toStringAsFixed(2) : '';
  }

  void _setControllerText(
    TextEditingController controller,
    String text,
  ) {
    if (controller.text == text) return;

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _syncLimitFields({
    required MarketCurrency currency,
    required double upper,
    required double lower,
  }) {
    final currencyChanged = _lastCurrency != currency;

    final limitsChanged =
        _lastUpperLimit != upper || _lastLowerLimit != lower;

    if (!currencyChanged && !limitsChanged) return;

    if (currencyChanged) {
      final previousCurrency = _lastCurrency;

      if (previousCurrency != null) {
        _upperDrafts[previousCurrency] = upperController.text;
        _lowerDrafts[previousCurrency] = lowerController.text;
      }

      _lastCurrency = currency;

      _isEditingUpper = false;
      _isEditingLower = false;

      _setControllerText(
        upperController,
        _upperDrafts[currency] ?? _formatLimit(upper),
      );

      _setControllerText(
        lowerController,
        _lowerDrafts[currency] ?? _formatLimit(lower),
      );
    } else {
      if (!_isEditingUpper) {
        _setControllerText(
          upperController,
          _formatLimit(upper),
        );
      }

      if (!_isEditingLower) {
        _setControllerText(
          lowerController,
          _formatLimit(lower),
        );
      }
    }

    _lastUpperLimit = upper;
    _lastLowerLimit = lower;
  }

  @override
  void dispose() {
    upperController.removeListener(_onUpperChanged);
    lowerController.removeListener(_onLowerChanged);

    upperController.dispose();
    lowerController.dispose();

    _periodScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketControllerProvider);
    final controller = ref.read(marketControllerProvider.notifier);

    _syncLimitFields(
      currency: state.currency,
      upper: state.upperLimit,
      lower: state.lowerLimit,
    );

    final currentPrice = state.price;

    final maxPrice = state.chartData.isEmpty
        ? 0.0
        : state.chartData
            .map((c) => c.high)
            .reduce((a, b) => a > b ? a : b);

    final minPrice = state.chartData.isEmpty
        ? 0.0
        : state.chartData
            .map((c) => c.low)
            .reduce((a, b) => a < b ? a : b);

    final volume = state.chartData.fold<double>(
      0,
      (sum, candle) => sum + candle.volume,
    );

    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STATUS DA API
                  _buildApiStatus(state, currentPrice),

                  const SizedBox(height: 18),

                  // SELETOR DE MOEDA
                  _buildCurrencySelector(state, controller),

                  const SizedBox(height: 16),

                  // CARD BITCOIN
                  BitcoinPriceCard(
                    price: currentPrice,
                    currency: state.currency,
                    changePercent24h: currentPrice.changePercent24h,
                    isLoading:
                        state.isLoading && currentPrice.price == 0,
                  ),

                  const SizedBox(height: 22),

                  // SELETOR ÚNICO DE PERÍODO
                  _buildPeriodSelector(
                    state: state,
                    controller: controller,
                  ),

                  const SizedBox(height: 16),

                  // GRÁFICO
                  if (state.chartData.isEmpty && state.isLoading)
                    const SizedBox(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    BitcoinChart(
                      candles: state.chartData,
                      currency: state.currency,
                    ),

                  const SizedBox(height: 18),

                  // ESTATÍSTICAS
                  MarketMetrics(
                    maxPrice: maxPrice,
                    minPrice: minPrice,
                    volume: volume,
                    currency: state.currency,
                  ),

                  const SizedBox(height: 20),

                  // LIMITES DE ALERTA
                  AlertThresholdForm(
                    upperController: upperController,
                    lowerController: lowerController,
                    upperLimit: state.upperLimit,
                    lowerLimit: state.lowerLimit,
                    onSave: () {
                      if (!_isSaving) {
                        _saveLimits(controller);
                      }
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiStatus(dynamic state, dynamic currentPrice) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: appSuccess.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: appSuccess.withValues(alpha: 0.30),
            ),
          ),
          child: Text(
            state.isLoading && currentPrice.price == 0
                ? 'Binance: conectando'
                : 'API: Binance · 5s',
            style: const TextStyle(
              color: appSuccess,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Cotações públicas · atualização automática',
            style: TextStyle(
              color: appTextSecondary,
              fontSize: 11,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Atualizar agora',
          onPressed: state.isLoading
              ? null
              : () => ref
                  .read(marketControllerProvider.notifier)
                  .refresh(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector(
    dynamic state,
    MarketController controller,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<MarketCurrency>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: MarketCurrency.usd,
            label: Text('USDT'),
          ),
          ButtonSegment(
            value: MarketCurrency.brl,
            label: Text('BRL'),
          ),
        ],
        selected: {state.currency},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            controller.setCurrency(selection.first);
          }
        },
      ),
    );
  }

  Widget _buildPeriodSelector({
    required dynamic state,
    required MarketController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              color: appAccentEnd,
              size: 21,
            ),
            const SizedBox(width: 9),
            const Text(
              'Período',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              state.selectedPeriod,
              style: const TextStyle(
                color: appTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),

        Scrollbar(
          controller: _periodScrollController,
          thumbVisibility: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _periodScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: _periods.map((period) {
                final selected = state.selectedPeriod == period;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 66,
                    height: 46,
                    child: ChoiceChip(
                      label: Center(
                        child: Text(period),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        controller.setPeriod(period);
                      },
                      showCheckmark: true,
                      padding: EdgeInsets.zero,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : appTextSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveLimits(MarketController controller) async {
    if (_isSaving) return;

    final upper = double.tryParse(
      upperController.text.trim().replaceAll(',', '.'),
    );

    final lower = double.tryParse(
      lowerController.text.trim().replaceAll(',', '.'),
    );

    if (upper == null ||
        lower == null ||
        !upper.isFinite ||
        !lower.isFinite ||
        upper <= 0 ||
        lower <= 0) {
      _showMessage('Informe limites numéricos maiores que zero.');
      return;
    }

    if (upper <= lower) {
      _showMessage(
        'O limite superior deve ser maior que o inferior.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final saved = await controller.updateThresholds(
        upperLimit: upper,
        lowerLimit: lower,
      );

      if (!mounted) return;

      if (saved) {
        final currency =
            ref.read(marketControllerProvider).currency;

        _upperDrafts[currency] = _formatLimit(upper);
        _lowerDrafts[currency] = _formatLimit(lower);

        _isEditingUpper = false;
        _isEditingLower = false;

        _setControllerText(
          upperController,
          _formatLimit(upper),
        );

        _setControllerText(
          lowerController,
          _formatLimit(lower),
        );

        _showMessage('Limites salvos neste dispositivo.');
      } else {
        _showMessage('Não foi possível salvar os limites.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Erro ao salvar os limites: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}