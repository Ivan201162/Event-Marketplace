import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Типы платежей
enum PaymentType {
  deposit, // Предоплата
  finalPayment, // Окончательный платеж
  fullPayment, // Полная оплата
  prepayment, // Предоплата
  refund, // Возврат
  penalty, // Штраф
  bonus, // Бонус
  hold, // Заморозка средств
}

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.deposit:
        return 'Предоплата';
      case PaymentType.finalPayment:
        return 'Окончательный платеж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
      case PaymentType.prepayment:
        return 'Предоплата';
      case PaymentType.refund:
        return 'Возврат';
      case PaymentType.penalty:
        return 'Штраф';
      case PaymentType.bonus:
        return 'Бонус';
      case PaymentType.hold:
        return 'Заморозка средств';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentType.deposit:
        return Icons.payment;
      case PaymentType.finalPayment:
        return Icons.check_circle;
      case PaymentType.fullPayment:
        return Icons.account_balance_wallet;
      case PaymentType.prepayment:
        return Icons.payment;
      case PaymentType.refund:
        return Icons.undo;
      case PaymentType.penalty:
        return Icons.warning;
      case PaymentType.bonus:
        return Icons.card_giftcard;
      case PaymentType.hold:
        return Icons.pause_circle;
    }
  }
}

/// Статусы платежей
enum PaymentStatus {
  pending, // Ожидает оплаты
  processing, // В обработке
  completed, // Завершен
  failed, // Неудачный
  cancelled, // Отменен
  refunded, // Возвращен
  disputed, // Оспорен
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Ожидает оплаты';
      case PaymentStatus.processing:
        return 'В обработке';
      case PaymentStatus.completed:
        return 'Завершен';
      case PaymentStatus.failed:
        return 'Неудачный';
      case PaymentStatus.cancelled:
        return 'Отменен';
      case PaymentStatus.refunded:
        return 'Возвращен';
      case PaymentStatus.disputed:
        return 'Оспорен';
    }
  }
}

/// Методы оплаты
enum PaymentMethod {
  card, // Банковская карта
  bankTransfer, // Банковский перевод
  cash, // Наличные
  digitalWallet, // Электронный кошелек
  cryptocurrency, // Криптовалюта
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.card:
        return 'Банковская карта';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.digitalWallet:
        return 'Электронный кошелек';
      case PaymentMethod.cryptocurrency:
        return 'Криптовалюта';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.digitalWallet:
        return Icons.qr_code;
      case PaymentMethod.cryptocurrency:
        return Icons.currency_bitcoin;
    }
  }

  bool get isAvailable {
    switch (this) {
      case PaymentMethod.card:
        return true;
      case PaymentMethod.bankTransfer:
        return true;
      case PaymentMethod.cash:
        return true;
      case PaymentMethod.digitalWallet:
        return true;
      case PaymentMethod.cryptocurrency:
        return false; // Пока не поддерживается
    }
  }

  String get method => displayName;

  String get description {
    switch (this) {
      case PaymentMethod.card:
        return 'Оплата банковской картой';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
      case PaymentMethod.cash:
        return 'Оплата наличными';
      case PaymentMethod.digitalWallet:
        return 'Электронный кошелек';
      case PaymentMethod.cryptocurrency:
        return 'Криптовалюта';
    }
  }

  double get fee {
    switch (this) {
      case PaymentMethod.card:
        return 0.03; // 3%
      case PaymentMethod.bankTransfer:
        return 0.01; // 1%
      case PaymentMethod.cash:
        return 0; // 0%
      case PaymentMethod.digitalWallet:
        return 0.02; // 2%
      case PaymentMethod.cryptocurrency:
        return 0.05; // 5%
    }
  }
}

/// Статус налогообложения
enum TaxStatus {
  none, // Без налога
  individual, // Физическое лицо
  individualEntrepreneur, // ИП
  selfEmployed, // Самозанятый
  legalEntity, // Юридическое лицо
  professionalIncome, // НПД (самозанятые)
  simplifiedTax, // УСН (ИП)
  vat, // НДС
}

/// Тип организации
enum OrganizationType {
  individual, // Физическое лицо
  individualEntrepreneur, // ИП
  selfEmployed, // Самозанятый
  legalEntity, // Юридическое лицо
  government, // Государственное учреждение
  nonProfit, // Некоммерческая организация
}

/// Информация о методе платежа
class PaymentMethodInfo {
  const PaymentMethodInfo({
    required this.method,
    required this.name,
    required this.description,
    required this.isAvailable,
    this.fee,
    this.iconUrl,
  });

  factory PaymentMethodInfo.fromMap(Map<String, dynamic> map) => PaymentMethodInfo(
        method: PaymentMethod.values.firstWhere(
          (e) => e.name == map['method'],
          orElse: () => PaymentMethod.card,
        ),
        name: map['name'] as String,
        description: map['description'] as String,
        isAvailable: map['isAvailable'] as bool,
        fee: map['fee'] != null ? (map['fee'] as num).toDouble() : null,
        iconUrl: map['iconUrl'] as String?,
      );

  final PaymentMethod method;
  final String name;
  final String description;
  final bool isAvailable;
  final double? fee;
  final String? iconUrl;

  Map<String, dynamic> toMap() => {
        'method': method.name,
        'name': name,
        'description': description,
        'isAvailable': isAvailable,
        'fee': fee,
        'iconUrl': iconUrl,
      };
}

/// Модель платежа
class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.specialistId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.method,
    required this.description,
    this.transactionId,
    this.paymentProvider,
    this.providerTransactionId,
    this.fee,
    this.tax,
    this.totalAmount,
    this.metadata,
    required this.createdAt,
    this.processedAt,
    this.completedAt,
    this.failedAt,
    this.cancelledAt,
    this.refundedAt,
    this.dueDate,
    this.refundReason,
  });

  /// Создать платеж из документа Firestore
  factory Payment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Payment(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      type: PaymentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PaymentType.deposit,
      ),
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'RUB',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == data['method'],
        orElse: () => PaymentMethod.card,
      ),
      description: data['description'] as String? ?? '',
      transactionId: data['transactionId'] as String?,
      paymentProvider: data['paymentProvider'] as String?,
      providerTransactionId: data['providerTransactionId'] as String?,
      fee: data['fee'] != null ? (data['fee'] as num).toDouble() : null,
      tax: data['tax'] != null ? (data['tax'] as num).toDouble() : null,
      totalAmount: data['totalAmount'] != null ? (data['totalAmount'] as num).toDouble() : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null ? (data['processedAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      failedAt: data['failedAt'] != null ? (data['failedAt'] as Timestamp).toDate() : null,
      cancelledAt: data['cancelledAt'] != null ? (data['cancelledAt'] as Timestamp).toDate() : null,
      refundedAt: data['refundedAt'] != null ? (data['refundedAt'] as Timestamp).toDate() : null,
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      refundReason: data['refundReason'] as String?,
    );
  }

  final String id;
  final String bookingId;
  final String userId;
  final String specialistId;
  final PaymentType type;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentMethod method;
  final String description;
  final String? transactionId;
  final String? paymentProvider;
  final String? providerTransactionId;
  final double? fee;
  final double? tax;
  final double? totalAmount;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  final DateTime? dueDate;
  final String? refundReason;

  // Дополнительные методы для совместимости
  String get typeDisplayName {
    switch (type) {
      case PaymentType.deposit:
        return 'Предоплата';
      case PaymentType.finalPayment:
        return 'Окончательный платеж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
      case PaymentType.prepayment:
        return 'Предоплата';
      case PaymentType.refund:
        return 'Возврат';
      case PaymentType.penalty:
        return 'Штраф';
      case PaymentType.bonus:
        return 'Бонус';
      case PaymentType.hold:
        return 'Заморозка средств';
    }
  }

  String get methodDisplayName {
    switch (method) {
      case PaymentMethod.card:
        return 'Банковская карта';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.digitalWallet:
        return 'Электронный кошелек';
      case PaymentMethod.cryptocurrency:
        return 'Криптовалюта';
    }
  }

  String? get failureReason => failedAt != null ? 'Платеж не прошел' : null;
  bool get isPending => status == PaymentStatus.pending;
  DateTime? get paidAt => completedAt;

  // Tax-related getters
  String get taxStatusDisplayName {
    // TODO: Implement tax status logic
    return 'Без налога';
  }

  double get taxAmount => tax ?? 0.0;
  double get netAmount => amount - taxAmount;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'userId': userId,
        'specialistId': specialistId,
        'type': type.name,
        'amount': amount,
        'currency': currency,
        'status': status.name,
        'method': method.name,
        'description': description,
        'transactionId': transactionId,
        'paymentProvider': paymentProvider,
        'providerTransactionId': providerTransactionId,
        'fee': fee,
        'tax': tax,
        'totalAmount': totalAmount,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
        'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
        'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'refundReason': refundReason,
      };

  /// Создать копию с изменениями
  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? specialistId,
    PaymentType? type,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? method,
    String? description,
    String? transactionId,
    String? paymentProvider,
    String? providerTransactionId,
    double? fee,
    double? tax,
    double? totalAmount,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? processedAt,
    DateTime? completedAt,
    DateTime? failedAt,
    DateTime? cancelledAt,
    DateTime? refundedAt,
    DateTime? dueDate,
    String? refundReason,
  }) =>
      Payment(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        userId: userId ?? this.userId,
        specialistId: specialistId ?? this.specialistId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        status: status ?? this.status,
        method: method ?? this.method,
        description: description ?? this.description,
        transactionId: transactionId ?? this.transactionId,
        paymentProvider: paymentProvider ?? this.paymentProvider,
        providerTransactionId: providerTransactionId ?? this.providerTransactionId,
        fee: fee ?? this.fee,
        tax: tax ?? this.tax,
        totalAmount: totalAmount ?? this.totalAmount,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        processedAt: processedAt ?? this.processedAt,
        completedAt: completedAt ?? this.completedAt,
        failedAt: failedAt ?? this.failedAt,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        refundedAt: refundedAt ?? this.refundedAt,
        dueDate: dueDate ?? this.dueDate,
        refundReason: refundReason ?? this.refundReason,
      );

  /// Получить итоговую сумму к оплате
  double get finalAmount {
    if (totalAmount != null) return totalAmount!;

    var total = amount;
    if (fee != null) total += fee!;
    if (tax != null) total += tax!;

    return total;
  }

  /// Проверить, является ли платеж активным
  bool get isActive => status == PaymentStatus.pending || status == PaymentStatus.processing;

  /// Проверить, завершен ли платеж
  bool get isCompleted => status == PaymentStatus.completed;

  /// Проверить, неудачен ли платеж
  bool get isFailed => status == PaymentStatus.failed;

  /// Проверить, отменен ли платеж
  bool get isCancelled => status == PaymentStatus.cancelled;

  /// Проверить, возвращен ли платеж
  bool get isRefunded => status == PaymentStatus.refunded;

  /// Проверить, просрочен ли платеж
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && isActive;

  /// Получить иконку для типа платежа
  String get typeIcon {
    switch (type) {
      case PaymentType.deposit:
        return '💰';
      case PaymentType.finalPayment:
        return '💳';
      case PaymentType.refund:
        return '↩️';
      case PaymentType.penalty:
        return '⚠️';
      case PaymentType.bonus:
        return '🎁';
      case PaymentType.hold:
        return '🔒';
    }
  }

  /// Получить название типа платежа
  String get typeName {
    switch (type) {
      case PaymentType.deposit:
        return 'Предоплата';
      case PaymentType.finalPayment:
        return 'Окончательный платеж';
      case PaymentType.refund:
        return 'Возврат';
      case PaymentType.penalty:
        return 'Штраф';
      case PaymentType.bonus:
        return 'Бонус';
      case PaymentType.hold:
        return 'Заморозка средств';
    }
  }

  /// Получить название метода оплаты
  String get methodName {
    switch (method) {
      case PaymentMethod.card:
        return 'Банковская карта';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.digitalWallet:
        return 'Электронный кошелек';
      case PaymentMethod.cryptocurrency:
        return 'Криптовалюта';
    }
  }

  /// Получить цвет для статуса
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

  /// Получить название статуса
  String get statusName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает оплаты';
      case PaymentStatus.processing:
        return 'В обработке';
      case PaymentStatus.completed:
        return 'Завершен';
      case PaymentStatus.failed:
        return 'Неудачный';
      case PaymentStatus.cancelled:
        return 'Отменен';
      case PaymentStatus.refunded:
        return 'Возвращен';
    }
  }

  /// Форматировать сумму
  String get formattedAmount => '${amount.toStringAsFixed(2)} $currency';

  /// Форматировать итоговую сумму
  String get formattedTotalAmount => '${finalAmount.toStringAsFixed(2)} $currency';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Payment(id: $id, type: $type, amount: $amount, status: $status)';
}

/// Модель финансового отчета
class FinancialReport {
  const FinancialReport({
    required this.userId,
    required this.period,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.paymentCount,
    required this.completedPayments,
    required this.pendingPayments,
    required this.failedPayments,
    required this.refundedPayments,
    required this.currency,
    required this.generatedAt,
    this.breakdown,
  });

  /// Создать из документа Firestore
  factory FinancialReport.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return FinancialReport(
      userId: data['userId'] as String? ?? '',
      period: data['period'] as String? ?? '',
      totalIncome: (data['totalIncome'] as num).toDouble(),
      totalExpenses: (data['totalExpenses'] as num).toDouble(),
      netIncome: (data['netIncome'] as num).toDouble(),
      paymentCount: data['paymentCount'] as int? ?? 0,
      completedPayments: data['completedPayments'] as int? ?? 0,
      pendingPayments: data['pendingPayments'] as int? ?? 0,
      failedPayments: data['failedPayments'] as int? ?? 0,
      refundedPayments: data['refundedPayments'] as int? ?? 0,
      currency: data['currency'] as String? ?? 'RUB',
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      breakdown: data['breakdown'] as Map<String, dynamic>?,
    );
  }

  final String userId;
  final String period; // например, "2024-01" для января 2024
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;
  final int paymentCount;
  final int completedPayments;
  final int pendingPayments;
  final int failedPayments;
  final int refundedPayments;
  final String currency;
  final DateTime generatedAt;
  final Map<String, dynamic>? breakdown;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'period': period,
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netIncome': netIncome,
        'paymentCount': paymentCount,
        'completedPayments': completedPayments,
        'pendingPayments': pendingPayments,
        'failedPayments': failedPayments,
        'refundedPayments': refundedPayments,
        'currency': currency,
        'generatedAt': Timestamp.fromDate(generatedAt),
        'breakdown': breakdown,
      };

  /// Форматировать доходы
  String get formattedIncome => '${totalIncome.toStringAsFixed(2)} $currency';

  /// Форматировать расходы
  String get formattedExpenses => '${totalExpenses.toStringAsFixed(2)} $currency';

  /// Форматировать чистый доход
  String get formattedNetIncome => '${netIncome.toStringAsFixed(2)} $currency';
}
