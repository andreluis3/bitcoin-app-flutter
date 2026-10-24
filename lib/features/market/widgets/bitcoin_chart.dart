import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/models/bitcoin_candle.dart';

class BitcoinChart extends StatelessWidget {
  const BitcoinChart({required this.candles, super.key});

  final List<BitcoinCandle> candles;

  @override
  Widget build(BuildContext context) {
    final spots = candles.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final candle = entry.value;
      return FlSpot(index, candle.close);
    }).toList();

    if (spots.isEmpty) {
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

    final minY =
        spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.02;

    return Container(
      height: 210,
      padding: const EdgeInsets.all(12),
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
              const Text('Histórico de preço'),
              const Spacer(),
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
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: appAccentEnd,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: appAccentEnd.withValues(alpha: 0.15),
                    ),
                    spots: spots,
                  ),
                ],
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
