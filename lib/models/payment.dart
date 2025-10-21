import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Payment method enum
enum PaymentMethod {
  card,
  bankTransfer,
  digitalWallet,
  cryptocurrency,
  cash,
  sbp,
}

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  disputed,
}

/// Payment type enum
enum PaymentType {
  booking,
  subscription,
  deposit,
  prepayment,
  finalPayment,
  fullPayment,
  penalty,
  bonus,
  hold,
}

/// Tax status enum
enum TaxStatus {
  none,
  individual,
  individualEntrepreneur,
  selfEmployed,
  legalEntity,
  professionalIncome,
  simplifiedTax,
  vat,
  notCalculated,
  calculated,
  paid,
  exempt,
}

/// Payment model
class Payment extends Equatable {
  final String id;
  final String userId;
  final String? specialistId;
  final String? bookingId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final PaymentType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final String? transactionId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String? receiptUrl;
  final double? fee;
  final double? taxAmount;
  final TaxStatus? taxStatus;
  final String? typeDisplayName;
  final String? methodDisplayName;
  final String? taxStatusDisplayName;
  final bool isCompleted;
  final double? netAmount;
  final DateTime? completedAt;
  final bool isPending;
  final String? failureReason;
  final String? duration;
  final String? formattedDuration;
  final bool isFailed;
  final String? commission;
  final String? formattedCommission;
  final String? formattedNetAmount;
  final bool isSuccessful;

  const Payment({
    required this.id,
    required this.userId,
    this.specialistId,
    this.bookingId,
    required this.amount,
    this.currency = 'RUB',
    required this.method,
    required this.status,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.transactionId,
    this.description,
    this.metadata,
    this.receiptUrl,
    this.fee,
    this.taxAmount,
    this.taxStatus,
    this.typeDisplayName,
    this.methodDisplayName,
    this.taxStatusDisplayName,
    this.isCompleted = false,
    this.netAmount,
    this.completedAt,
    this.isPending = false,
    this.failureReason,
    this.duration,
    this.formattedDuration,
    this.isFailed = false,
    this.commission,
    this.formattedCommission,
    this.formattedNetAmount,
    this.isSuccessful = false,
  });

  /// Create Payment from Firestore document
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      userId: data['userId'] ?? '',
      specialistId: data['specialistId'],
      bookingId: data['bookingId'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'RUB',
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == data['method'],
        orElse: () => PaymentMethod.card,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      type: PaymentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PaymentType.booking,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
      transactionId: data['transactionId'],
      description: data['description'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      receiptUrl: data['receiptUrl'],
      fee: data['fee']?.toDouble(),
      taxAmount: data['taxAmount']?.toDouble(),
      taxStatus: data['taxStatus'] != null
          ? TaxStatus.values.firstWhere(
              (e) => e.name == data['taxStatus'],
              orElse: () => TaxStatus.notCalculated,
            )
          : null,
      typeDisplayName: data['typeDisplayName'],
      methodDisplayName: data['methodDisplayName'],
      taxStatusDisplayName: data['taxStatusDisplayName'],
      isCompleted: data['isCompleted'] ?? false,
      netAmount: data['netAmount']?.toDouble(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      isPending: data['isPending'] ?? false,
      failureReason: data['failureReason'],
      duration: data['duration'],
      formattedDuration: data['formattedDuration'],
      isFailed: data['isFailed'] ?? false,
      commission: data['commission'],
      formattedCommission: data['formattedCommission'],
      formattedNetAmount: data['formattedNetAmount'],
      isSuccessful: data['isSuccessful'] ?? false,
    );
  }

  /// Convert Payment to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'specialistId': specialistId,
      'bookingId': bookingId,
      'amount': amount,
      'currency': currency,
      'method': method.name,
      'status': status.name,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'transactionId': transactionId,
      'description': description,
      'metadata': metadata,
      'receiptUrl': receiptUrl,
      'fee': fee,
      'taxAmount': taxAmount,
      'taxStatus': taxStatus?.name,
      'typeDisplayName': typeDisplayName,
      'methodDisplayName': methodDisplayName,
      'taxStatusDisplayName': taxStatusDisplayName,
      'isCompleted': isCompleted,
      'netAmount': netAmount,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isPending': isPending,
      'failureReason': failureReason,
      'duration': duration,
      'formattedDuration': formattedDuration,
      'isFailed': isFailed,
      'commission': commission,
      'formattedCommission': formattedCommission,
      'formattedNetAmount': formattedNetAmount,
      'isSuccessful': isSuccessful,
    };
  }

  /// Create a copy with updated fields
  Payment copyWith({
    String? id,
    String? userId,
    String? specialistId,
    String? bookingId,
    double? amount,
    String? currency,
    PaymentMethod? method,
    PaymentStatus? status,
    PaymentType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    String? transactionId,
    String? description,
    Map<String, dynamic>? metadata,
    String? receiptUrl,
    double? fee,
    double? taxAmount,
    TaxStatus? taxStatus,
    String? typeDisplayName,
    String? methodDisplayName,
    String? taxStatusDisplayName,
    bool? isCompleted,
    double? netAmount,
    DateTime? completedAt,
    bool? isPending,
    String? failureReason,
    String? duration,
    String? formattedDuration,
    bool? isFailed,
    String? commission,
    String? formattedCommission,
    String? formattedNetAmount,
    bool? isSuccessful,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialistId: specialistId ?? this.specialistId,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      transactionId: transactionId ?? this.transactionId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      fee: fee ?? this.fee,
      taxAmount: taxAmount ?? this.taxAmount,
      taxStatus: taxStatus ?? this.taxStatus,
      typeDisplayName: typeDisplayName ?? this.typeDisplayName,
      methodDisplayName: methodDisplayName ?? this.methodDisplayName,
      taxStatusDisplayName: taxStatusDisplayName ?? this.taxStatusDisplayName,
      isCompleted: isCompleted ?? this.isCompleted,
      netAmount: netAmount ?? this.netAmount,
      completedAt: completedAt ?? this.completedAt,
      isPending: isPending ?? this.isPending,
      failureReason: failureReason ?? this.failureReason,
      duration: duration ?? this.duration,
      formattedDuration: formattedDuration ?? this.formattedDuration,
      isFailed: isFailed ?? this.isFailed,
      commission: commission ?? this.commission,
      formattedCommission: formattedCommission ?? this.formattedCommission,
      formattedNetAmount: formattedNetAmount ?? this.formattedNetAmount,
      isSuccessful: isSuccessful ?? this.isSuccessful,
    );
  }

  /// Get formatted amount
  String get formattedAmount => '${amount.toStringAsFixed(2)} $currency';

  /// Get status color
  String get statusColor {
    switch (status) {
      case PaymentStatus.pending:
        return '#FFA500';
      case PaymentStatus.processing:
        return '#2196F3';
      case PaymentStatus.completed:
        return '#4CAF50';
      case PaymentStatus.failed:
        return '#F44336';
      case PaymentStatus.cancelled:
        return '#9E9E9E';
      case PaymentStatus.refunded:
        return '#FF9800';
      case PaymentStatus.disputed:
        return '#E91E63';
    }
  }

  /// Get status text
  String get statusText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.processing:
        return 'Обрабатывается';
      case PaymentStatus.completed:
        return 'Завершено';
      case PaymentStatus.failed:
        return 'Неудачно';
      case PaymentStatus.cancelled:
        return 'Отменено';
      case PaymentStatus.refunded:
        return 'Возвращено';
      case PaymentStatus.disputed:
        return 'Спор';
    }
  }

  /// Get method icon
  String get methodIcon {
    switch (method) {
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.bankTransfer:
        return '🏦';
      case PaymentMethod.digitalWallet:
        return '📱';
      case PaymentMethod.cryptocurrency:
        return '₿';
      case PaymentMethod.cash:
        return '💵';
    }
  }

  /// Get type icon
  String get typeIcon {
    switch (type) {
      case PaymentType.booking:
        return '📅';
      case PaymentType.subscription:
        return '🔄';
      case PaymentType.deposit:
        return '💰';
      case PaymentType.prepayment:
        return '⏰';
      case PaymentType.finalPayment:
        return '✅';
      case PaymentType.fullPayment:
        return '💯';
      case PaymentType.penalty:
        return '⚠️';
      case PaymentType.bonus:
        return '🎁';
      case PaymentType.hold:
        return '🔒';
    }
  }

  /// Get display name for payment type
  String get displayName {
    switch (type) {
      case PaymentType.booking:
        return 'Бронирование';
      case PaymentType.subscription:
        return 'Подписка';
      case PaymentType.deposit:
        return 'Депозит';
      case PaymentType.prepayment:
        return 'Предоплата';
      case PaymentType.finalPayment:
        return 'Финальный платеж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
      case PaymentType.penalty:
        return 'Штраф';
      case PaymentType.bonus:
        return 'Бонус';
      case PaymentType.hold:
        return 'Блокировка';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        specialistId,
        bookingId,
        amount,
        currency,
        method,
        status,
        type,
        createdAt,
        updatedAt,
        paidAt,
        transactionId,
        description,
        metadata,
        receiptUrl,
        fee,
        taxAmount,
        taxStatus,
        typeDisplayName,
        methodDisplayName,
        taxStatusDisplayName,
        isCompleted,
        netAmount,
        completedAt,
        isPending,
        failureReason,
        duration,
        formattedDuration,
        isFailed,
        commission,
        formattedCommission,
        formattedNetAmount,
        isSuccessful,
      ];

  @override
  String toString() {
    return 'Payment(id: $id, amount: $amount, status: $status, type: $type)';
  }
}
