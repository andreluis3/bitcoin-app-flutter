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

  @override
  void dispose() {
    upperController.dispose();
    lowerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketControllerProvider);
    final controller = ref.read(marketControllerProvider.notifier);

    upperController.text = state.upperLimit.toStringAsFixed(0);
    lowerController.text = state.lowerLimit.toStringAsFixed(0);

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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  FilledButton.tonal(
                    onPressed: controller.refresh,
                    child: const Text('Atualizar'),
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
                      state.isLoading ? 'Binance: conectando' : 'API: Binance',
                      style: const TextStyle(
                        color: appSuccess,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: const Text(
                      'Cotações públicas em tempo real · atualização manual',
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['1H', '24H', '7D', '1M', '1Y']
                        .map(
                          (period) => ChoiceChip(
                            label: Text(period),
                            selected: state.selectedPeriod == period,
                            onSelected: (_) => controller.setPeriod(period),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.isLoading)
                const SizedBox(
                  height: 210,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                BitcoinChart(candles: state.chartData),
              const SizedBox(height: 16),
              MarketMetrics(
                maxPrice: state.chartData.fold(
                  0.0,
                  (previousValue, candle) =>
                      candle.high > previousValue ? candle.high : previousValue,
                ),
                minPrice: state.chartData.fold(
                  0.0,
                  (previousValue, candle) =>
                      candle.low < previousValue || previousValue == 0
                      ? candle.low
                      : previousValue,
                ),
                volume: state.chartData.fold(
                  0.0,
                  (previousValue, candle) => previousValue + candle.volume,
                ),
                currency: state.currency,
              ),
              const SizedBox(height: 16),
              AlertThresholdForm(
                upperController: upperController,
                lowerController: lowerController,
                upperLimit: state.upperLimit,
                lowerLimit: state.lowerLimit,
                onSave: () {
                  final upper =
                      double.tryParse(upperController.text) ?? state.upperLimit;
                  final lower =
                      double.tryParse(lowerController.text) ?? state.lowerLimit;

                  if (upper <= 0 || lower <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Use valores maiores que zero para definir os limites.',
                        ),
                      ),
                    );
                    return;
                  }

                  if (upper <= lower) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'O limite superior deve ser maior que o inferior.',
                        ),
                      ),
                    );
                    return;
                  }

                  controller.updateThresholds(
                    upperLimit: upper,
                    lowerLimit: lower,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Limites salvos com sucesso.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
