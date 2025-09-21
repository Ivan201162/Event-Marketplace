import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель скидки для бронирования
class BookingDiscount {
  const BookingDiscount({
    this.isOffered = false,
    this.percent,
    this.oldPrice,
    this.newPrice,
    this.offeredAt,
    this.expiresAt,
    this.offeredBy = 'specialist',
    this.reason,
    this.isAccepted = false,
    this.acceptedAt,
    this.acceptedBy,
  });

  /// Создать из документа Firestore
  factory BookingDiscount.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return BookingDiscount(
      isOffered: data['isOffered'] as bool? ?? false,
      percent: (data['percent'] as num?)?.toDouble(),
      oldPrice: (data['oldPrice'] as num?)?.toDouble(),
      newPrice: (data['newPrice'] as num?)?.toDouble(),
      offeredAt: data['offeredAt'] != null
          ? (data['offeredAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      offeredBy: data['offeredBy'] ?? 'specialist',
      reason: data['reason'],
      isAccepted: data['isAccepted'] ?? false,
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      acceptedBy: data['acceptedBy'],
    );
  }

  /// Создать из Map
  factory BookingDiscount.fromMap(Map<String, dynamic> data) => BookingDiscount(
        isOffered: data['isOffered'] ?? false,
        percent: data['percent']?.toDouble(),
        oldPrice: data['oldPrice']?.toDouble(),
        newPrice: data['newPrice']?.toDouble(),
        offeredAt: data['offeredAt'] != null
            ? (data['offeredAt'] as Timestamp).toDate()
            : null,
        expiresAt: data['expiresAt'] != null
            ? (data['expiresAt'] as Timestamp).toDate()
            : null,
        offeredBy: data['offeredBy'] ?? 'specialist',
        reason: data['reason'],
        isAccepted: data['isAccepted'] ?? false,
        acceptedAt: data['acceptedAt'] != null
            ? (data['acceptedAt'] as Timestamp).toDate()
            : null,
        acceptedBy: data['acceptedBy'],
      );
  final bool isOffered;
  final double? percent;
  final double? oldPrice;
  final double? newPrice;
  final DateTime? offeredAt;
  final DateTime? expiresAt;
  final String offeredBy; // 'specialist' или 'system'
  final String? reason;
  final bool isAccepted;
  final DateTime? acceptedAt;
  final String? acceptedBy;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'isOffered': isOffered,
        'percent': percent,
        'oldPrice': oldPrice,
        'newPrice': newPrice,
        'offeredAt': offeredAt != null ? Timestamp.fromDate(offeredAt!) : null,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'offeredBy': offeredBy,
        'reason': reason,
        'isAccepted': isAccepted,
        'acceptedAt':
            acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
        'acceptedBy': acceptedBy,
      };

  /// Создать копию с изменениями
  BookingDiscount copyWith({
    bool? isOffered,
    double? percent,
    double? oldPrice,
    double? newPrice,
    DateTime? offeredAt,
    DateTime? expiresAt,
    String? offeredBy,
    String? reason,
    bool? isAccepted,
    DateTime? acceptedAt,
    String? acceptedBy,
  }) =>
      BookingDiscount(
        isOffered: isOffered ?? this.isOffered,
        percent: percent ?? this.percent,
        oldPrice: oldPrice ?? this.oldPrice,
        newPrice: newPrice ?? this.newPrice,
        offeredAt: offeredAt ?? this.offeredAt,
        expiresAt: expiresAt ?? this.expiresAt,
        offeredBy: offeredBy ?? this.offeredBy,
        reason: reason ?? this.reason,
        isAccepted: isAccepted ?? this.isAccepted,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        acceptedBy: acceptedBy ?? this.acceptedBy,
      );

  /// Проверить, активна ли скидка
  bool get isActive {
    if (!isOffered || isAccepted) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Проверить, истекла ли скидка
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Получить экономию в рублях
  double? get savings {
    if (oldPrice == null || newPrice == null) return null;
    return oldPrice! - newPrice!;
  }

  /// Получить процент скидки
  double? get discountPercent {
    if (percent != null) return percent;
    if (oldPrice == null || newPrice == null) return null;
    return ((oldPrice! - newPrice!) / oldPrice!) * 100;
  }

  /// Получить время до истечения скидки
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  /// Получить статус скидки
  DiscountStatus get status {
    if (!isOffered) return DiscountStatus.notOffered;
    if (isAccepted) return DiscountStatus.accepted;
    if (isExpired) return DiscountStatus.expired;
    return DiscountStatus.pending;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingDiscount &&
        other.isOffered == isOffered &&
        other.percent == percent &&
        other.oldPrice == oldPrice &&
        other.newPrice == newPrice &&
        other.offeredAt == offeredAt &&
        other.expiresAt == expiresAt &&
        other.offeredBy == offeredBy &&
        other.reason == reason &&
        other.isAccepted == isAccepted &&
        other.acceptedAt == acceptedAt &&
        other.acceptedBy == acceptedBy;
  }

  @override
  int get hashCode => Object.hash(
        isOffered,
        percent,
        oldPrice,
        newPrice,
        offeredAt,
        expiresAt,
        offeredBy,
        reason,
        isAccepted,
        acceptedAt,
        acceptedBy,
      );

  @override
  String toString() =>
      'BookingDiscount(isOffered: $isOffered, percent: $percent, status: $status)';
}

/// Статус скидки
enum DiscountStatus {
  notOffered,
  pending,
  accepted,
  expired,
}

/// Расширение для статуса скидки
extension DiscountStatusExtension on DiscountStatus {
  String get displayName {
    switch (this) {
      case DiscountStatus.notOffered:
        return 'Не предложена';
      case DiscountStatus.pending:
        return 'Ожидает ответа';
      case DiscountStatus.accepted:
        return 'Принята';
      case DiscountStatus.expired:
        return 'Истекла';
    }
  }

  String get description {
    switch (this) {
      case DiscountStatus.notOffered:
        return 'Скидка не была предложена';
      case DiscountStatus.pending:
        return 'Скидка ожидает вашего ответа';
      case DiscountStatus.accepted:
        return 'Скидка была принята';
      case DiscountStatus.expired:
        return 'Время действия скидки истекло';
    }
  }
}
