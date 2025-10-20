import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Payment status enum
enum PaymentStatus {
  pending('Ожидает оплаты'),
  processing('Обрабатывается'),
  completed('Завершен'),
  failed('Неудачный'),
  cancelled('Отменен'),
  refunded('Возвращен');

  const PaymentStatus(this.displayName);
  final String displayName;
}

/// Payment method enum
enum PaymentMethod {
  card('Банковская карта'),
  applePay('Apple Pay'),
  googlePay('Google Pay'),
  yooMoney('ЮMoney'),
  sberbank('Сбербанк'),
  tinkoff('Тинькофф');

  const PaymentMethod(this.displayName);
  final String displayName;
}

/// Payment type enum
enum PaymentType {
  booking('Оплата бронирования'),
  commission('Комиссия платформы'),
  refund('Возврат средств'),
  payout('Выплата специалисту'),
  subscription('Подписка'),
  premium('Премиум функции');

  const PaymentType(this.displayName);
  final String displayName;
}

/// Payment model
class Payment extends Equatable {
  final String id;
  final String userId;
  final String? specialistId;
  final String? bookingId;
  final PaymentType type;
  final PaymentMethod method;
  final PaymentStatus status;
  final int amount; // in kopecks
  final int commission; // in kopecks
  final String currency;
  final String description;
  final Map<String, dynamic>? metadata;
  final String? stripePaymentIntentId;
  final String? stripeChargeId;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;

  const Payment({
    required this.id,
    required this.userId,
    this.specialistId,
    this.bookingId,
    required this.type,
    required this.method,
    required this.status,
    required this.amount,
    required this.commission,
    required this.currency,
    required this.description,
    this.metadata,
    this.stripePaymentIntentId,
    this.stripeChargeId,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.failedAt,
  });

  /// Create Payment from Firestore document
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Payment(
      id: doc.id,
      userId: data['userId'] ?? '',
      specialistId: data['specialistId'],
      bookingId: data['bookingId'],
      type: PaymentType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => PaymentType.booking,
      ),
      method: PaymentMethod.values.firstWhere(
        (method) => method.name == data['method'],
        orElse: () => PaymentMethod.card,
      ),
      status: PaymentStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      amount: data['amount'] ?? 0,
      commission: data['commission'] ?? 0,
      currency: data['currency'] ?? 'RUB',
      description: data['description'] ?? '',
      metadata: data['metadata'],
      stripePaymentIntentId: data['stripePaymentIntentId'],
      stripeChargeId: data['stripeChargeId'],
      failureReason: data['failureReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      failedAt: data['failedAt'] != null ? (data['failedAt'] as Timestamp).toDate() : null,
    );
  }

  /// Convert Payment to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'specialistId': specialistId,
      'bookingId': bookingId,
      'type': type.name,
      'method': method.name,
      'status': status.name,
      'amount': amount,
      'commission': commission,
      'currency': currency,
      'description': description,
      'metadata': metadata,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeChargeId': stripeChargeId,
      'failureReason': failureReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
    };
  }

  /// Create a copy of Payment with updated fields
  Payment copyWith({
    String? id,
    String? userId,
    String? specialistId,
    String? bookingId,
    PaymentType? type,
    PaymentMethod? method,
    PaymentStatus? status,
    int? amount,
    int? commission,
    String? currency,
    String? description,
    Map<String, dynamic>? metadata,
    String? stripePaymentIntentId,
    String? stripeChargeId,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? failedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialistId: specialistId ?? this.specialistId,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      method: method ?? this.method,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      commission: commission ?? this.commission,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeChargeId: stripeChargeId ?? this.stripeChargeId,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
    );
  }

  /// Get formatted amount string
  String get formattedAmount {
    final rubles = amount / 100;
    return '${rubles.toStringAsFixed(2)} ₽';
  }

  /// Get formatted commission string
  String get formattedCommission {
    final rubles = commission / 100;
    return '${rubles.toStringAsFixed(2)} ₽';
  }

  /// Get net amount (amount - commission)
  int get netAmount => amount - commission;

  /// Get formatted net amount string
  String get formattedNetAmount {
    final rubles = netAmount / 100;
    return '${rubles.toStringAsFixed(2)} ₽';
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case PaymentStatus.pending:
        return 'orange';
      case PaymentStatus.processing:
        return 'blue';
      case PaymentStatus.completed:
        return 'green';
      case PaymentStatus.failed:
        return 'red';
      case PaymentStatus.cancelled:
        return 'grey';
      case PaymentStatus.refunded:
        return 'purple';
    }
  }

  /// Check if payment is successful
  bool get isSuccessful => status == PaymentStatus.completed;

  /// Check if payment is pending
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;

  /// Check if payment is failed
  bool get isFailed => status == PaymentStatus.failed || status == PaymentStatus.cancelled;

  /// Check if payment can be refunded
  bool get canBeRefunded => status == PaymentStatus.completed;

  /// Get payment duration
  Duration? get duration {
    if (completedAt != null) {
      return completedAt!.difference(createdAt);
    }
    return null;
  }

  /// Get formatted duration
  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'В процессе';

    if (dur.inSeconds < 60) {
      return '${dur.inSeconds} сек';
    } else if (dur.inMinutes < 60) {
      return '${dur.inMinutes} мин';
    } else {
      return '${dur.inHours} ч ${dur.inMinutes % 60} мин';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        specialistId,
        bookingId,
        type,
        method,
        status,
        amount,
        commission,
        currency,
        description,
        metadata,
        stripePaymentIntentId,
        stripeChargeId,
        failureReason,
        createdAt,
        updatedAt,
        completedAt,
        failedAt,
      ];
}
