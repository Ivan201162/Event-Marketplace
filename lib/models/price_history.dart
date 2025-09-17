import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель истории изменений цены
class PriceHistory {
  final String id;
  final String bookingId;
  final double oldPrice;
  final double newPrice;
  final double? discountPercent;
  final String reason;
  final String changedBy; // 'specialist', 'customer', 'system'
  final DateTime changedAt;
  final Map<String, dynamic>? metadata;

  const PriceHistory({
    required this.id,
    required this.bookingId,
    required this.oldPrice,
    required this.newPrice,
    this.discountPercent,
    required this.reason,
    required this.changedBy,
    required this.changedAt,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory PriceHistory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceHistory(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      oldPrice: (data['oldPrice'] as num).toDouble(),
      newPrice: (data['newPrice'] as num).toDouble(),
      discountPercent: data['discountPercent']?.toDouble(),
      reason: data['reason'] ?? '',
      changedBy: data['changedBy'] ?? '',
      changedAt: (data['changedAt'] as Timestamp).toDate(),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Создать из Map
  factory PriceHistory.fromMap(Map<String, dynamic> data) {
    return PriceHistory(
      id: data['id'] ?? '',
      bookingId: data['bookingId'] ?? '',
      oldPrice: (data['oldPrice'] as num).toDouble(),
      newPrice: (data['newPrice'] as num).toDouble(),
      discountPercent: data['discountPercent']?.toDouble(),
      reason: data['reason'] ?? '',
      changedBy: data['changedBy'] ?? '',
      changedAt: (data['changedAt'] as Timestamp).toDate(),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'discountPercent': discountPercent,
      'reason': reason,
      'changedBy': changedBy,
      'changedAt': Timestamp.fromDate(changedAt),
      'metadata': metadata,
    };
  }

  /// Получить изменение цены
  double get priceChange => newPrice - oldPrice;

  /// Получить процент изменения
  double get priceChangePercent => (priceChange / oldPrice) * 100;

  /// Проверить, является ли изменение скидкой
  bool get isDiscount => newPrice < oldPrice;

  /// Получить экономию
  double get savings => isDiscount ? oldPrice - newPrice : 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PriceHistory &&
        other.id == id &&
        other.bookingId == bookingId &&
        other.oldPrice == oldPrice &&
        other.newPrice == newPrice &&
        other.discountPercent == discountPercent &&
        other.reason == reason &&
        other.changedBy == changedBy &&
        other.changedAt == changedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      bookingId,
      oldPrice,
      newPrice,
      discountPercent,
      reason,
      changedBy,
      changedAt,
    );
  }

  @override
  String toString() {
    return 'PriceHistory(id: $id, bookingId: $bookingId, oldPrice: $oldPrice, newPrice: $newPrice, reason: $reason)';
  }
}
