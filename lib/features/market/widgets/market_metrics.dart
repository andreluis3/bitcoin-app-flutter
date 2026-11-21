
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 380 ? 2 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 88,
          ),
          itemBuilder: (context, index) => metrics[index],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: appTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: appTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
