import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/bitcoin_price.dart';
import '../../../data/models/market_alert.dart';

class AlertHistoryTile extends StatelessWidget {
  const AlertHistoryTile({required this.alert, super.key});

  final MarketAlert alert;

  @override
  Widget build(BuildContext context) {
    final typeColor = alert.isUp ? appSuccess : appDanger;
    final typeLabel = alert.isUp ? 'UP' : 'DOWN';
    final currency = alert.currency == 'USD' ? MarketCurrency.usd : MarketCurrency.brl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                typeLabel,
                style: TextStyle(color: typeColor, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preço ${formatPrice(alert.price, currency: currency)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Limite ${formatPrice(alert.threshold, currency: currency)}',
                  style: const TextStyle(color: appTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatDateTime(alert.createdAt),
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: appTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.currency,
                  style: const TextStyle(color: appTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
