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
  final upperController = TextEditingController();
  final lowerController = TextEditingController();
  bool _syncingControllers = false;

  @override
  void dispose() {
    upperController.dispose();
    lowerController.dispose();
    super.dispose();
  }

  void _syncLimitFields(double upper, double lower) {
    if (_syncingControllers) return;
    _syncingControllers = true;
    final upperText = upper > 0 ? upper.toStringAsFixed(2) : '';
    final lowerText = lower > 0 ? lower.toStringAsFixed(2) : '';
    if (upperController.text != upperText) {
      upperController.value = TextEditingValue(
        text: upperText,
        selection: TextSelection.collapsed(offset: upperText.length),
      );
    }
    if (lowerController.text != lowerText) {
      lowerController.value = TextEditingValue(
        text: lowerText,
        selection: TextSelection.collapsed(offset: lowerText.length),
      );
    }
    _syncingControllers = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketControllerProvider);
    final controller = ref.read(marketControllerProvider.notifier);
    _syncLimitFields(state.upperLimit, state.lowerLimit);

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
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar agora',
                    onPressed: state.isLoading ? null : () => controller.refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: appSuccess.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: appSuccess.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      state.isLoading && currentPrice.price == 0
                          ? 'Binance: conectando'
                          : 'API: Binance · 5s',
                      style: const TextStyle(color: appSuccess, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cotações públicas · atualização automática',
                      style: TextStyle(color: appTextSecondary, fontSize: 11),
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
                    border: Border.all(color: appDanger.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: appDanger, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SegmentedButton<MarketCurrency>(
                selectedIcon: null,
                segments: const [
                  ButtonSegment(value: MarketCurrency.usd, label: Text('USD')),
                  ButtonSegment(value: MarketCurrency.brl, label: Text('BRL')),
                ],
                selected: {state.currency},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) controller.setCurrency(selection.first);
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['1H', '24H', '7D', '1M', '1Y'].map((period) {
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
                    : state.chartData.map((c) => c.high).reduce((a, b) => a > b ? a : b),
                minPrice: state.chartData.isEmpty
                    ? 0
                    : state.chartData.map((c) => c.low).reduce((a, b) => a < b ? a : b),
                volume: state.chartData.fold(0.0, (sum, candle) => sum + candle.volume),
                currency: state.currency,
              ),
              const SizedBox(height: 16),
              AlertThresholdForm(
                upperController: upperController,
                lowerController: lowerController,
                upperLimit: state.upperLimit,
                lowerLimit: state.lowerLimit,
                onSave: () async {
                  final upper = double.tryParse(upperController.text.trim().replaceAll(',', '.'));
                  final lower = double.tryParse(lowerController.text.trim().replaceAll(',', '.'));
                  if (upper == null || lower == null || upper <= 0 || lower <= 0) {
                    _showMessage('Informe limites numéricos maiores que zero.');
                    return;
                  }
                  if (upper <= lower) {
                    _showMessage('O limite superior deve ser maior que o inferior.');
                    return;
                  }
                  final saved = await controller.updateThresholds(
                    upperLimit: upper,
                    lowerLimit: lower,
                  );
                  if (!mounted) return;
                  _showMessage(
                    saved ? 'Limites salvos neste dispositivo.' : 'Não foi possível salvar os limites.',
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
