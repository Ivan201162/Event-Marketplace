/// Модель ценового диапазона
class PriceRange {
  const PriceRange({
    required this.minPrice,
    required this.maxPrice,
  });

  /// Создать из Map
  factory PriceRange.fromMap(Map<String, dynamic> data) => PriceRange(
        minPrice: (data['minPrice'] as num? ?? 0.0).toDouble(),
        maxPrice: (data['maxPrice'] as num? ?? 0.0).toDouble(),
      );

  final double minPrice;
  final double maxPrice;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'minPrice': minPrice,
        'maxPrice': maxPrice,
      };

  /// Проверить, находится ли цена в диапазоне
  bool contains(double price) => price >= minPrice && price <= maxPrice;

  /// Получить среднюю цену
  double get averagePrice => (minPrice + maxPrice) / 2;

  /// Получить отформатированную строку диапазона
  String get formattedRange {
    if (minPrice == maxPrice) {
      return '${minPrice.toInt()} ₽';
    }
    return '${minPrice.toInt()} - ${maxPrice.toInt()} ₽';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PriceRange &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice;
  }

  @override
  int get hashCode => minPrice.hashCode ^ maxPrice.hashCode;

  @override
  String toString() => 'PriceRange(min: $minPrice, max: $maxPrice)';
}
