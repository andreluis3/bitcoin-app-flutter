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
      ),
      _MetricTile(
        label: 'Mínima',
        value: '$symbol${minPrice.toStringAsFixed(0)}',
      ),
      _MetricTile(
        label: 'Volume',
        value: '$symbol${formatCompactVolume(volume)}',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) => metrics[index],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: appTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: appTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
