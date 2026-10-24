import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/bitcoin_price.dart';

class BitcoinPriceCard extends StatelessWidget {
  const BitcoinPriceCard({
    required this.price,
    required this.currency,
    required this.changePercent24h,
    required this.isLoading,
    super.key,
  });

  final BitcoinPrice price;
  final MarketCurrency currency;
  final double changePercent24h;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercent24h >= 0;
    final priceText = isLoading
        ? 'Conectando...'
        : price.price == 0
        ? '--'
        : formatPrice(price.price, currency: currency);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [appAccentStart, appAccentEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bitcoin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: appTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Binance',
                  style: TextStyle(color: appTextPrimary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            priceText,
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(color: appTextPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: isPositive ? appSuccess : appDanger,
              ),
              const SizedBox(width: 8),
              Text(
                isLoading || price.price == 0
                    ? 'Aguardando cotação'
                    : formatPercent(changePercent24h),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isPositive ? appSuccess : appDanger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
