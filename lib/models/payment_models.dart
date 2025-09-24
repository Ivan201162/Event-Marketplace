import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип платежа
enum PaymentType {
  prepayment, // Аванс
  finalPayment, // Финальный платёж
  fullPayment, // Полная оплата
}

extension PaymentTypeExtension on PaymentType {
  String get typeDisplayName {
    switch (this) {
      case PaymentType.prepayment:
        return 'Аванс';
      case PaymentType.finalPayment:
        return 'Финальный платёж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
    }
  }
}

/// Статус платежа
enum PaymentStatus {
  pending, // Ожидает оплаты
  processing, // Обрабатывается
  completed, // Завершён
  failed, // Неудачный
  cancelled, // Отменён
  refunded, // Возвращён
}

/// Способ оплаты
enum PaymentMethod {
  card, // Банковская карта
  sbp, // Система быстрых платежей
  yookassa, // ЮKassa
  bankTransfer, // Банковский перевод
}

extension PaymentMethodExtension on PaymentMethod {
  String get methodDisplayName {
    switch (this) {
      case PaymentMethod.card:
        return 'Банковская карта';
      case PaymentMethod.sbp:
        return 'СБП';
      case PaymentMethod.yookassa:
        return 'ЮKassa';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
    }
  }
}

/// Схема оплаты
enum PaymentScheme {
  partialPrepayment, // Частичная предоплата (30/70)
  fullPrepayment, // Полная предоплата
  postPayment, // Постоплата
}

/// Модель платежа
class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.amount,
    required this.type,
    required this.status,
    required this.method,
    required this.scheme,
    required this.createdAt,
    this.processedAt,
    this.completedAt,
    this.failedAt,
    this.cancelledAt,
    this.refundedAt,
    this.transactionId,
    this.paymentUrl,
    this.description,
    this.metadata,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final double amount;
  final PaymentType type;
  final PaymentStatus status;
  final PaymentMethod method;
  final PaymentScheme scheme;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  final String? transactionId;
  final String? paymentUrl;
  final String? description;
  final Map<String, dynamic>? metadata;

  /// Создать из Map
  factory Payment.fromMap(Map<String, dynamic> data) {
    return Payment(
      id: data['id'] as String,
      bookingId: data['bookingId'] as String,
      customerId: data['customerId'] as String,
      specialistId: data['specialistId'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: PaymentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PaymentType.prepayment,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == data['method'],
        orElse: () => PaymentMethod.card,
      ),
      scheme: PaymentScheme.values.firstWhere(
        (e) => e.name == data['scheme'],
        orElse: () => PaymentScheme.partialPrepayment,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      failedAt: data['failedAt'] != null
          ? (data['failedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      refundedAt: data['refundedAt'] != null
          ? (data['refundedAt'] as Timestamp).toDate()
          : null,
      transactionId: data['transactionId'] as String?,
      paymentUrl: data['paymentUrl'] as String?,
      description: data['description'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'customerId': customerId,
      'specialistId': specialistId,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'method': method.name,
      'scheme': scheme.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'transactionId': transactionId,
      'paymentUrl': paymentUrl,
      'description': description,
      'metadata': metadata,
    };
  }

  /// Копировать с изменениями
  Payment copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? specialistId,
    double? amount,
    PaymentType? type,
    PaymentStatus? status,
    PaymentMethod? method,
    PaymentScheme? scheme,
    DateTime? createdAt,
    DateTime? processedAt,
    DateTime? completedAt,
    DateTime? failedAt,
    DateTime? cancelledAt,
    DateTime? refundedAt,
    String? transactionId,
    String? paymentUrl,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      method: method ?? this.method,
      scheme: scheme ?? this.scheme,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      refundedAt: refundedAt ?? this.refundedAt,
      transactionId: transactionId ?? this.transactionId,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Получить отображаемое имя типа платежа
  String get typeDisplayName {
    switch (type) {
      case PaymentType.prepayment:
        return 'Аванс';
      case PaymentType.finalPayment:
        return 'Финальный платёж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
    }
  }

  /// Получить отображаемое имя статуса
  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает оплаты';
      case PaymentStatus.processing:
        return 'Обрабатывается';
      case PaymentStatus.completed:
        return 'Завершён';
      case PaymentStatus.failed:
        return 'Неудачный';
      case PaymentStatus.cancelled:
        return 'Отменён';
      case PaymentStatus.refunded:
        return 'Возвращён';
    }
  }

  /// Получить отображаемое имя метода оплаты
  String get methodDisplayName {
    switch (method) {
      case PaymentMethod.card:
        return 'Банковская карта';
      case PaymentMethod.sbp:
        return 'СБП';
      case PaymentMethod.yookassa:
        return 'ЮKassa';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
    }
  }

  /// Получить отображаемое имя схемы оплаты
  String get schemeDisplayName {
    switch (scheme) {
      case PaymentScheme.partialPrepayment:
        return 'Частичная предоплата (30/70)';
      case PaymentScheme.fullPrepayment:
        return 'Полная предоплата';
      case PaymentScheme.postPayment:
        return 'Постоплата';
    }
  }

  /// Проверить, завершён ли платёж
  bool get isCompleted => status == PaymentStatus.completed;

  /// Проверить, ожидает ли платёж
  bool get isPending => status == PaymentStatus.pending;

  /// Проверить, обрабатывается ли платёж
  bool get isProcessing => status == PaymentStatus.processing;

  /// Проверить, неудачный ли платёж
  bool get isFailed => status == PaymentStatus.failed;

  /// Проверить, отменён ли платёж
  bool get isCancelled => status == PaymentStatus.cancelled;

  /// Проверить, возвращён ли платёж
  bool get isRefunded => status == PaymentStatus.refunded;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Payment{id: $id, bookingId: $bookingId, amount: $amount, type: $type, status: $status}';
  }
}
