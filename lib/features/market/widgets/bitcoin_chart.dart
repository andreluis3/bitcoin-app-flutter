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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final chartHeight = width < 360
            ? 230.0
            : width < 600
                ? 270.0
                : 330.0;

        if (candles.isEmpty) {
          return Container(
            width: double.infinity,
            height: chartHeight,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: appSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: appBorder),
            ),
            child: const Center(
              child: Text(
                'Nenhum candle disponível para este período.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appTextSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        final spots = candles.asMap().entries.map((entry) {
          return FlSpot(
            entry.key.toDouble(),
            entry.value.close,
          );
        }).toList();

        final prices = candles.map((c) => c.close);

        final minPrice = prices.reduce((a, b) => a < b ? a : b);
        final maxPrice = prices.reduce((a, b) => a > b ? a : b);

        final range = maxPrice - minPrice;

        final padding = range == 0
            ? maxPrice.abs() * 0.01
            : range * 0.12;

        final minY = (minPrice - padding)
            .clamp(0, double.infinity)
            .toDouble();

        final maxY = maxPrice + padding;

        return Container(
          width: double.infinity,
          height: chartHeight,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          decoration: BoxDecoration(
            color: appSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: appBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABEÇALHO
              Row(
                children: [
                  const Icon(
                    Icons.show_chart_rounded,
                    color: appAccentEnd,
                    size: 23,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Histórico de preço',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: appBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Binance',
                      style: TextStyle(
                        color: appTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // GRÁFICO
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (candles.length - 1)
                        .toDouble()
                        .clamp(1, double.infinity)
                        .toDouble(),

                    minY: minY,
                    maxY: maxY <= minY ? minY + 1 : maxY,

                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: range > 0 ? range / 3 : null,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: appBorder.withValues(alpha: 0.55),
                          strokeWidth: 0.7,
                          dashArray: [4, 5],
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: appBorder.withValues(alpha: 0.35),
                          strokeWidth: 0.6,
                          dashArray: [4, 5],
                        );
                      },
                    ),

                    borderData: FlBorderData(show: false),

                    titlesData: const FlTitlesData(
                      show: false,
                    ),

                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.x
                                .round()
                                .clamp(0, candles.length - 1);

                            final candle = candles[index];

                            final price = formatPrice(
                              candle.close,
                              currency: currency,
                            );

                            final date = DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(candle.time);

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
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: appAccentEnd,
                        barWidth: 2.8,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(
                          show: false,
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: appAccentEnd.withValues(
                            alpha: 0.13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Toque ou arraste sobre a linha para ver preço, data e hora.',
                style: TextStyle(
                  color: appTextSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}