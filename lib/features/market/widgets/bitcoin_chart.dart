import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/bitcoin_candle.dart';
import '../../../data/models/bitcoin_price.dart';

class BitcoinChart extends StatelessWidget {
  const BitcoinChart({
    required this.candles,
    required this.currency,
    super.key,
  });

  final List<BitcoinCandle> candles;
  final MarketCurrency currency;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Container(
        height: 210,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appBorder),
        ),
        child: const Center(
          child: Text(
            'Nenhum candle disponível para este período.',
            style: TextStyle(color: appTextSecondary),
          ),
        ),
      );
    }

    final spots = candles.asMap().entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.close))
        .toList();

    final prices = candles.map((candle) => candle.close);
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final range = maxPrice - minPrice;
    final padding = range == 0 ? maxPrice.abs() * 0.01 : range * 0.12;
    final minY = (minPrice - padding).clamp(0, double.infinity).toDouble();
    final maxY = maxPrice + padding;

    return Container(
      height: 252,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Histórico de preço',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: appBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Binance',
                  style: TextStyle(color: appTextSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (candles.length - 1).toDouble().clamp(1, double.infinity).toDouble(),
                minY: minY,
                maxY: maxY <= minY ? minY + 1 : maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.round().clamp(0, candles.length - 1);
                        final candle = candles[index];
                        final price = formatPrice(
                          candle.close,
                          currency: currency,
                        );
                        final date = DateFormat('dd/MM/yyyy HH:mm').format(candle.time);
                        return LineTooltipItem(
                          '$price\n$date',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: appAccentEnd,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: appAccentEnd.withValues(alpha: 0.12),
                    ),
                    spots: spots,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toque ou arraste sobre a linha para ver preço, data e hora.',
            style: TextStyle(color: appTextSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
