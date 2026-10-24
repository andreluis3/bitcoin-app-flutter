import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../data/models/bitcoin_price.dart';

String formatPrice(double price, {required MarketCurrency currency}) {
  final currencySymbol = currency == MarketCurrency.usd ? '\$' : 'R\$';
  final format = NumberFormat.currency(
    locale: 'en_US',
    symbol: currencySymbol,
    decimalDigits: 2,
  );
  return format.format(price);
}

String formatPercent(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

String formatCompactVolume(double value) {
  if (value >= 1e9) {
    return '${(value / 1e9).toStringAsFixed(2)}B';
  }
  if (value >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(2)}M';
  }
  if (value >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(2)}K';
  }
  return value.toStringAsFixed(0);
}

String formatDateTime(DateTime dateTime) {
  return DateFormat('dd/MM HH:mm').format(dateTime);
}

String formatMarketLabel(MarketCurrency currency) {
  switch (currency) {
    case MarketCurrency.usd:
      return 'USD';
    case MarketCurrency.brl:
      return 'BRL';
  }
}

String formatAmount(double value) {
  return NumberFormat.decimalPattern().format(value);
}

double clampDouble(double value, double min, double max) =>
    math.min(math.max(value, min), max);
