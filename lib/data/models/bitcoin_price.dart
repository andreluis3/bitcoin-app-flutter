class BitcoinPrice {
  const BitcoinPrice({
    required this.price,
    required this.currency,
    required this.changePercent24h,
    required this.timestamp,
  });

  final double price;
  final MarketCurrency currency;
  final double changePercent24h;
  final DateTime timestamp;

  factory BitcoinPrice.fromJson(Map<String, dynamic> json) {
    return BitcoinPrice(
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: MarketCurrency.values.firstWhere(
        (currency) => currency.name == (json['currency'] ?? 'usd'),
        orElse: () => MarketCurrency.usd,
      ),
      changePercent24h: (json['changePercent24h'] as num?)?.toDouble() ?? 0,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'currency': currency.name,
      'changePercent24h': changePercent24h,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum MarketCurrency { usd, brl }
