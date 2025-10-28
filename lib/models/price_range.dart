class PriceRange {

  const PriceRange(
      {required this.min, required this.max, this.currency = 'RUB',});

  factory PriceRange.fromMap(Map<String, dynamic> map) {
    return PriceRange(
      min: (map['min'] as num?)?.toDouble() ?? 0.0,
      max: (map['max'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'RUB',
    );
  }
  final double min;
  final double max;
  final String currency;

  Map<String, dynamic> toMap() {
    return {'min': min, 'max': max, 'currency': currency};
  }

  bool contains(double price) {
    return price >= min && price <= max;
  }

  String get displayText {
    if (min == max) {
      return '${min.toStringAsFixed(0)} $currency';
    }
    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} $currency';
  }

  String get formattedRange {
    if (min == max) {
      return '${min.toStringAsFixed(0)} $currency';
    }
    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} $currency';
  }

  // Геттеры для совместимости с существующим кодом
  double get minPrice => min;
  double get maxPrice => max;

  PriceRange copyWith({double? min, double? max, String? currency}) {
    return PriceRange(
      min: min ?? this.min,
      max: max ?? this.max,
      currency: currency ?? this.currency,
    );
  }
}
