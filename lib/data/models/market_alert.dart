enum AlertDirection { up, down }

class MarketAlert {
  const MarketAlert({
    required this.id,
    required this.direction,
    required this.price,
    required this.threshold,
    required this.createdAt,
    required this.currency,
  });

  final String id;
  final AlertDirection direction;
  final double price;
  final double threshold;
  final DateTime createdAt;
  final String currency;

  bool get isUp => direction == AlertDirection.up;

  factory MarketAlert.fromJson(Map<String, dynamic> json) {
    return MarketAlert(
      id: json['id'] as String? ?? '',
      direction: AlertDirection.values.firstWhere(
        (value) => value.name == (json['direction'] ?? 'up'),
        orElse: () => AlertDirection.up,
      ),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction.name,
        'price': price,
        'threshold': threshold,
        'createdAt': createdAt.toIso8601String(),
        'currency': currency,
      };
}
