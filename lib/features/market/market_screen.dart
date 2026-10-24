
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

  // Rascunhos independentes para cada moeda.
  final Map<MarketCurrency, String> _upperDrafts = {};
  final Map<MarketCurrency, String> _lowerDrafts = {};

  MarketCurrency? _lastCurrency;
  double? _lastUpperLimit;
  double? _lastLowerLimit;

  bool _isEditingUpper = false;
  bool _isEditingLower = false;
  bool _isSaving = false;

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
      // Guarda o que estava sendo digitado na moeda anterior.
      final previousCurrency = _lastCurrency;
      if (previousCurrency != null) {
        _upperDrafts[previousCurrency] = upperController.text;
        _lowerDrafts[previousCurrency] = lowerController.text;
      }

      _lastCurrency = currency;
      _isEditingUpper = false;
      _isEditingLower = false;

      // Restaura o rascunho da moeda selecionada, se existir.
      final upperDraft = _upperDrafts[currency];
      final lowerDraft = _lowerDrafts[currency];

      _setControllerText(
        upperController,
        upperDraft ?? _formatLimit(upper),
      );
      _setControllerText(
        lowerController,
        lowerDraft ?? _formatLimit(lower),
      );
    } else {
      // Atualizações periódicas de preço não alteram os campos.
      // Só sincroniza limites realmente alterados externamente
      // quando o respectivo campo não está em edição.
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

    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bitcoin Monitor',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar agora',
                    onPressed: state.isLoading
                        ? null
                        : () => controller.refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: appSuccess.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: appSuccess.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      state.isLoading && currentPrice.price == 0
                          ? 'Binance: conectando'
                          : 'API: Binance · 5s',
                      style: const TextStyle(
                        color: appSuccess,
                        fontSize: 11,
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
                ],
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appDanger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: appDanger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      color: appDanger,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SegmentedButton<MarketCurrency>(
                selectedIcon: null,
                segments: const [
                  ButtonSegment(
                    value: MarketCurrency.usd,
                    label: Text('USD'),
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
              const SizedBox(height: 16),
              BitcoinPriceCard(
                price: currentPrice,
                currency: state.currency,
                changePercent24h: currentPrice.changePercent24h,
                isLoading: state.isLoading && currentPrice.price == 0,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Período',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['1H', '24H', '7D', '1M', '1Y']
                        .map((period) {
                      return ChoiceChip(
                        label: Text(period),
                        selected: state.selectedPeriod == period,
                        onSelected: (_) => controller.setPeriod(period),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Mantém o gráfico visível durante atualizações silenciosas.
              if (state.chartData.isEmpty && state.isLoading)
                const SizedBox(
                  height: 210,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                BitcoinChart(
                  candles: state.chartData,
                  currency: state.currency,
                ),
              const SizedBox(height: 16),
              MarketMetrics(
                maxPrice: state.chartData.isEmpty
                    ? 0
                    : state.chartData
                        .map((c) => c.high)
                        .reduce((a, b) => a > b ? a : b),
                minPrice: state.chartData.isEmpty
                    ? 0
                    : state.chartData
                        .map((c) => c.low)
                        .reduce((a, b) => a < b ? a : b),
                volume: state.chartData.fold(
                  0.0,
                  (sum, candle) => sum + candle.volume,
                ),
                currency: state.currency,
              ),
              const SizedBox(height: 16),
              AlertThresholdForm(
                upperController: upperController,
                lowerController: lowerController,
                upperLimit: state.upperLimit,
                lowerLimit: state.lowerLimit,
                onSave: _isSaving ? null : () => _saveLimits(controller),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
        final currency = ref.read(marketControllerProvider).currency;

        _upperDrafts[currency] = _formatLimit(upper);
        _lowerDrafts[currency] = _formatLimit(lower);

        _isEditingUpper = false;
        _isEditingLower = false;

        _setControllerText(upperController, _formatLimit(upper));
        _setControllerText(lowerController, _formatLimit(lower));

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
