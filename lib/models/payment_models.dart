import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType {
  prepayment, // Предоплата 30%
  postpayment, // Остаток после мероприятия
  full, // Полная оплата
  refund, // Возврат
  dispute, // Спор
}

enum PaymentMethod {
  sbp, // Система быстрых платежей
  yookassa, // ЮKassa
  tinkoff, // Tinkoff Pay
  card, // Банковская карта
  cash, // Наличные
  bankTransfer, // Банковский перевод
}

enum PaymentStatus {
  pending, // Ожидает оплаты
  processing, // Обрабатывается
  completed, // Завершена
  failed, // Неудачная
  cancelled, // Отменена
  refunded, // Возвращена
  disputed, // Спор
}

enum TaxStatus {
  individual, // Физическое лицо
  individualEntrepreneur, // ИП
  selfEmployed, // Самозанятый
  legalEntity, // Юридическое лицо
}

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
  final String? externalPaymentId; // ID в внешней системе
  final String? paymentUrl; // Ссылка для оплаты
  final String? qrCode; // QR-код для оплаты
  final Map<String, dynamic> metadata; // Дополнительные данные
  final String? failureReason; // Причина неудачи
  final DateTime? completedAt;
  final DateTime? refundedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.amount,
    this.taxAmount = 0.0,
    this.netAmount = 0.0,
    required this.type,
    required this.method,
    this.status = PaymentStatus.pending,
    required this.taxStatus,
    this.externalPaymentId,
    this.paymentUrl,
    this.qrCode,
    this.metadata = const {},
    this.failureReason,
    this.completedAt,
    this.refundedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'customerId': customerId,
      'specialistId': specialistId,
      'amount': amount,
      'taxAmount': taxAmount,
      'netAmount': netAmount,
      'type': type.toString().split('.').last,
      'method': method.toString().split('.').last,
      'status': status.toString().split('.').last,
      'taxStatus': taxStatus.toString().split('.').last,
      'externalPaymentId': externalPaymentId,
      'paymentUrl': paymentUrl,
      'qrCode': qrCode,
      'metadata': metadata,
      'failureReason': failureReason,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      bookingId: map['bookingId'] as String,
      customerId: map['customerId'] as String,
      specialistId: map['specialistId'] as String,
      amount: (map['amount'] as num).toDouble(),
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      type: PaymentType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'] as String,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == map['method'] as String,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'] as String,
        orElse: () => PaymentStatus.pending,
      ),
      taxStatus: TaxStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['taxStatus'] as String,
      ),
      externalPaymentId: map['externalPaymentId'] as String?,
      paymentUrl: map['paymentUrl'] as String?,
      qrCode: map['qrCode'] as String?,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map<String, dynamic>? ?? {}),
      failureReason: map['failureReason'] as String?,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      refundedAt: (map['refundedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Payment.fromDocument(DocumentSnapshot doc) {
    return Payment.fromMap(doc.data() as Map<String, dynamic>);
  }

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
    String? externalPaymentId,
    String? paymentUrl,
    String? qrCode,
    Map<String, dynamic>? metadata,
    String? failureReason,
    DateTime? completedAt,
    DateTime? refundedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      externalPaymentId: externalPaymentId ?? this.externalPaymentId,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      qrCode: qrCode ?? this.qrCode,
      metadata: metadata ?? this.metadata,
      failureReason: failureReason ?? this.failureReason,
      completedAt: completedAt ?? this.completedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if payment is completed
  bool get isCompleted => status == PaymentStatus.completed;

  /// Check if payment is pending
  bool get isPending => status == PaymentStatus.pending;

  /// Check if payment is failed
  bool get isFailed => status == PaymentStatus.failed;

  /// Check if payment is refunded
  bool get isRefunded => status == PaymentStatus.refunded;

  /// Get payment method display name
  String get methodDisplayName {
    switch (method) {
      case PaymentMethod.sbp:
        return 'СБП';
      case PaymentMethod.yookassa:
        return 'ЮKassa';
      case PaymentMethod.tinkoff:
        return 'Tinkoff Pay';
      case PaymentMethod.card:
        return 'Банковская карта';
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
    }
  }

  /// Get payment type display name
  String get typeDisplayName {
    switch (type) {
      case PaymentType.prepayment:
        return 'Предоплата';
      case PaymentType.postpayment:
        return 'Остаток';
      case PaymentType.full:
        return 'Полная оплата';
      case PaymentType.refund:
        return 'Возврат';
      case PaymentType.dispute:
        return 'Спор';
    }
  }

  /// Get tax status display name
  String get taxStatusDisplayName {
    switch (taxStatus) {
      case TaxStatus.individual:
        return 'Физическое лицо';
      case TaxStatus.individualEntrepreneur:
        return 'ИП';
      case TaxStatus.selfEmployed:
        return 'Самозанятый';
      case TaxStatus.legalEntity:
        return 'Юридическое лицо';
    }
  }
}

class TaxCalculation {
  final String id;
  final String paymentId;
  final TaxStatus taxStatus;
  final double grossAmount;
  final double taxRate;
  final double taxAmount;
  final double netAmount;
  final Map<String, dynamic> calculationDetails;
  final DateTime calculatedAt;

  TaxCalculation({
    required this.id,
    required this.paymentId,
    required this.taxStatus,
    required this.grossAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.netAmount,
    this.calculationDetails = const {},
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'taxStatus': taxStatus.toString().split('.').last,
      'grossAmount': grossAmount,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'netAmount': netAmount,
      'calculationDetails': calculationDetails,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
    };
  }

  factory TaxCalculation.fromMap(Map<String, dynamic> map) {
    return TaxCalculation(
      id: map['id'] as String,
      paymentId: map['paymentId'] as String,
      taxStatus: TaxStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['taxStatus'] as String,
      ),
      grossAmount: (map['grossAmount'] as num).toDouble(),
      taxRate: (map['taxRate'] as num).toDouble(),
      taxAmount: (map['taxAmount'] as num).toDouble(),
      netAmount: (map['netAmount'] as num).toDouble(),
      calculationDetails: Map<String, dynamic>.from(map['calculationDetails'] as Map<String, dynamic>? ?? {}),
      calculatedAt: (map['calculatedAt'] as Timestamp).toDate(),
    );
  }
}

class RefundRequest {
  final String id;
  final String paymentId;
  final String reason;
  final double amount;
  final RefundStatus status;
  final String? externalRefundId;
  final String? rejectionReason;
  final DateTime requestedAt;
  final DateTime? processedAt;

  RefundRequest({
    required this.id,
    required this.paymentId,
    required this.reason,
    required this.amount,
    this.status = RefundStatus.pending,
    this.externalRefundId,
    this.rejectionReason,
    required this.requestedAt,
    this.processedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'reason': reason,
      'amount': amount,
      'status': status.toString().split('.').last,
      'externalRefundId': externalRefundId,
      'rejectionReason': rejectionReason,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }

  factory RefundRequest.fromMap(Map<String, dynamic> map) {
    return RefundRequest(
      id: map['id'] as String,
      paymentId: map['paymentId'] as String,
      reason: map['reason'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: RefundStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'] as String,
        orElse: () => RefundStatus.pending,
      ),
      externalRefundId: map['externalRefundId'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      processedAt: (map['processedAt'] as Timestamp?)?.toDate(),
    );
  }
}

enum RefundStatus {
  pending,
  approved,
  rejected,
  processed,
}

class PaymentMethodInfo {
  final PaymentMethod method;
  final String name;
  final String description;
  final String iconUrl;
  final bool isAvailable;
  final double? fee;
  final Map<String, dynamic> configuration;

  PaymentMethodInfo({
    required this.method,
    required this.name,
    required this.description,
    this.iconUrl = '',
    this.isAvailable = true,
    this.fee,
    this.configuration = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'method': method.toString().split('.').last,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'isAvailable': isAvailable,
      'fee': fee,
      'configuration': configuration,
    };
  }

  factory PaymentMethodInfo.fromMap(Map<String, dynamic> map) {
    return PaymentMethodInfo(
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == map['method'] as String,
      ),
      name: map['name'] as String,
      description: map['description'] as String,
      iconUrl: map['iconUrl'] as String? ?? '',
      isAvailable: map['isAvailable'] as bool? ?? true,
      fee: (map['fee'] as num?)?.toDouble(),
      configuration: Map<String, dynamic>.from(map['configuration'] as Map<String, dynamic>? ?? {}),
    );
  }
}
