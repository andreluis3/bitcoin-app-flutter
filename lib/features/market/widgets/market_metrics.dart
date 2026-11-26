import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/bitcoin_price.dart';

class MarketMetrics extends StatelessWidget {
  const MarketMetrics({
    required this.maxPrice,
    required this.minPrice,
    required this.volume,
    required this.currency,
    super.key,
  });

  final double maxPrice;
  final double minPrice;
  final double volume;
  final MarketCurrency currency;

  @override
  Widget build(BuildContext context) {
    final symbol = currency == MarketCurrency.usd ? '\$' : 'R\$';

    final metrics = [
      _MetricTile(
        label: 'Máxima',
        value: '$symbol${maxPrice.toStringAsFixed(0)}',
        icon: Icons.trending_up_rounded,
      ),
      _MetricTile(
        label: 'Mínima',
        value: '$symbol${minPrice.toStringAsFixed(0)}',
        icon: Icons.trending_down_rounded,
      ),
      _MetricTile(
        label: 'Volume',
        value: '$symbol${formatCompactVolume(volume)}',
        icon: Icons.bar_chart_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: metrics[0]),
                  const SizedBox(width: 10),
                  Expanded(child: metrics[1]),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: metrics[2],
              ),
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < metrics.length; i++) ...[
              Expanded(child: metrics[i]),
              if (i != metrics.length - 1)
                const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: appAccentEnd,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: appTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: appTextPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}