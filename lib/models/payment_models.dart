import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы платежей
enum PaymentType {
  prepayment, // Предоплата
  postpayment, // Постоплата
  full, // Полная оплата
  refund, // Возврат
}

/// Статусы платежей
enum PaymentStatus {
  pending, // Ожидает оплаты
  processing, // Обрабатывается
  completed, // Завершен
  failed, // Неудачный
  cancelled, // Отменен
  refunded, // Возвращен
}

/// Методы платежей
enum PaymentMethod {
  sbp, // Система быстрых платежей
  yookassa, // ЮKassa
  tinkoff, // Тинькофф
  card, // Банковская карта
  cash, // Наличные
}

/// Статус налогообложения
enum TaxStatus {
  none, // Без налога
  professionalIncome, // НПД (самозанятые)
  simplifiedTax, // УСН (ИП)
  vat, // НДС
}

/// Статус возврата
enum RefundStatus {
  pending, // Ожидает обработки
  processed, // Обработан
  failed, // Неудачный
  cancelled, // Отменен
}

/// Информация о методе платежа
class PaymentMethodInfo {
  final PaymentMethod method;
  final String name;
  final String description;
  final bool isAvailable;
  final String? iconUrl;

  const PaymentMethodInfo({
    required this.method,
    required this.name,
    required this.description,
    required this.isAvailable,
    this.iconUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'method': method.name,
      'name': name,
      'description': description,
      'isAvailable': isAvailable,
      'iconUrl': iconUrl,
    };
  }

  factory PaymentMethodInfo.fromMap(Map<String, dynamic> map) {
    return PaymentMethodInfo(
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PaymentMethod.card,
      ),
      name: map['name'] as String,
      description: map['description'] as String,
      isAvailable: map['isAvailable'] as bool,
      iconUrl: map['iconUrl'] as String?,
    );
  }
}

/// Модель платежа
class Payment {
  final String id;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final double amount;
  final double taxAmount;
  final double netAmount;
  final PaymentType type;
  final PaymentMethod method;
  final PaymentStatus status;
  final TaxStatus taxStatus;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final DateTime? refundedAt;
  final String? externalPaymentId;
  final String? paymentUrl;
  final String? qrCode;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.amount,
    required this.taxAmount,
    required this.netAmount,
    required this.type,
    required this.method,
    required this.status,
    required this.taxStatus,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.failedAt,
    this.refundedAt,
    this.externalPaymentId,
    this.paymentUrl,
    this.qrCode,
  });

  /// Создать из документа Firestore
  factory Payment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (data['netAmount'] as num?)?.toDouble() ?? 0.0,
      type: PaymentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PaymentType.full,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == data['method'],
        orElse: () => PaymentMethod.card,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      taxStatus: TaxStatus.values.firstWhere(
        (e) => e.name == data['taxStatus'],
        orElse: () => TaxStatus.none,
      ),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      failedAt: (data['failedAt'] as Timestamp?)?.toDate(),
      refundedAt: (data['refundedAt'] as Timestamp?)?.toDate(),
      externalPaymentId: data['externalPaymentId'] as String?,
      paymentUrl: data['paymentUrl'] as String?,
      qrCode: data['qrCode'] as String?,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'specialistId': specialistId,
      'amount': amount,
      'taxAmount': taxAmount,
      'netAmount': netAmount,
      'type': type.name,
      'method': method.name,
      'status': status.name,
      'taxStatus': taxStatus.name,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'externalPaymentId': externalPaymentId,
      'paymentUrl': paymentUrl,
      'qrCode': qrCode,
    };
  }

  /// Создать копию с изменениями
  Payment copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? specialistId,
    double? amount,
    double? taxAmount,
    double? netAmount,
    PaymentType? type,
    PaymentMethod? method,
    PaymentStatus? status,
    TaxStatus? taxStatus,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? failedAt,
    DateTime? refundedAt,
    String? externalPaymentId,
    String? paymentUrl,
    String? qrCode,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      amount: amount ?? this.amount,
      taxAmount: taxAmount ?? this.taxAmount,
      netAmount: netAmount ?? this.netAmount,
      type: type ?? this.type,
      method: method ?? this.method,
      status: status ?? this.status,
      taxStatus: taxStatus ?? this.taxStatus,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      externalPaymentId: externalPaymentId ?? this.externalPaymentId,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  /// Проверить, завершен ли платеж
  bool get isCompleted => status == PaymentStatus.completed;

  /// Проверить, неудачен ли платеж
  bool get isFailed => status == PaymentStatus.failed;

  /// Проверить, обрабатывается ли платеж
  bool get isProcessing => status == PaymentStatus.processing;

  /// Проверить, ожидает ли платеж
  bool get isPending => status == PaymentStatus.pending;
}

/// Модель расчета налогов
class TaxCalculation {
  final String id;
  final String paymentId;
  final double grossAmount;
  final double taxAmount;
  final double netAmount;
  final double taxRate;
  final TaxStatus taxStatus;
  final DateTime calculatedAt;

  const TaxCalculation({
    required this.id,
    required this.paymentId,
    required this.grossAmount,
    required this.taxAmount,
    required this.netAmount,
    required this.taxRate,
    required this.taxStatus,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'grossAmount': grossAmount,
      'taxAmount': taxAmount,
      'netAmount': netAmount,
      'taxRate': taxRate,
      'taxStatus': taxStatus.name,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
    };
  }

  factory TaxCalculation.fromMap(Map<String, dynamic> map) {
    return TaxCalculation(
      id: map['id'] as String,
      paymentId: map['paymentId'] as String,
      grossAmount: (map['grossAmount'] as num).toDouble(),
      taxAmount: (map['taxAmount'] as num).toDouble(),
      netAmount: (map['netAmount'] as num).toDouble(),
      taxRate: (map['taxRate'] as num).toDouble(),
      taxStatus: TaxStatus.values.firstWhere(
        (e) => e.name == map['taxStatus'],
        orElse: () => TaxStatus.none,
      ),
      calculatedAt: (map['calculatedAt'] as Timestamp).toDate(),
    );
  }
}

/// Модель запроса на возврат
class RefundRequest {
  final String id;
  final String paymentId;
  final String reason;
  final double amount;
  final RefundStatus status;
  final String? externalRefundId;
  final DateTime requestedAt;
  final DateTime? processedAt;

  const RefundRequest({
    required this.id,
    required this.paymentId,
    required this.reason,
    required this.amount,
    required this.status,
    this.externalRefundId,
    required this.requestedAt,
    this.processedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'reason': reason,
      'amount': amount,
      'status': status.name,
      'externalRefundId': externalRefundId,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }

  factory RefundRequest.fromMap(Map<String, dynamic> map) {
    return RefundRequest(
      id: map['id'] as String,
      paymentId: map['paymentId'] as String,
      reason: map['reason'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: RefundStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RefundStatus.pending,
      ),
      externalRefundId: map['externalRefundId'] as String?,
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      processedAt: (map['processedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Статистика платежей
class PaymentStatistics {
  final int totalPayments;
  final int completedPayments;
  final int failedPayments;
  final double totalAmount;
  final double totalTaxAmount;
  final double totalNetAmount;
  final double averageAmount;

  const PaymentStatistics({
    required this.totalPayments,
    required this.completedPayments,
    required this.failedPayments,
    required this.totalAmount,
    required this.totalTaxAmount,
    required this.totalNetAmount,
    required this.averageAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalPayments': totalPayments,
      'completedPayments': completedPayments,
      'failedPayments': failedPayments,
      'totalAmount': totalAmount,
      'totalTaxAmount': totalTaxAmount,
      'totalNetAmount': totalNetAmount,
      'averageAmount': averageAmount,
    };
  }

  factory PaymentStatistics.fromMap(Map<String, dynamic> map) {
    return PaymentStatistics(
      totalPayments: map['totalPayments'] as int,
      completedPayments: map['completedPayments'] as int,
      failedPayments: map['failedPayments'] as int,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      totalTaxAmount: (map['totalTaxAmount'] as num).toDouble(),
      totalNetAmount: (map['totalNetAmount'] as num).toDouble(),
      averageAmount: (map['averageAmount'] as num).toDouble(),
    );
  }
}
