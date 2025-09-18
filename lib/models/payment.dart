import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы платежей
enum PaymentType {
  advance, // Аванс
  finalPayment, // Финальный платеж
  fullPayment, // Полная оплата
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

/// Типы организаций для расчета платежей
enum OrganizationType {
  individual, // Физическое лицо
  commercial, // Коммерческая организация
  government, // Государственное учреждение
  nonProfit, // Некоммерческая организация
}

/// Модель платежа
class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final String customerId;
  final String specialistId;
  final PaymentType type;
  final PaymentStatus status;
  final double amount;
  final double? originalAmount; // Оригинальная сумма до скидок/комиссий
  final String currency;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final String? paymentMethod;
  final String? transactionId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final OrganizationType organizationType;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.customerId,
    required this.specialistId,
    required this.type,
    required this.status,
    required this.amount,
    this.originalAmount,
    required this.currency,
    required this.createdAt,
    this.completedAt,
    this.failedAt,
    this.paymentMethod,
    this.transactionId,
    this.description,
    this.metadata,
    this.organizationType = OrganizationType.individual,
  });

  /// Создать из документа Firestore
  factory Payment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      type: _parsePaymentType(data['type']),
      status: _parsePaymentStatus(data['status']),
      amount:
          (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0,
      originalAmount: data['originalAmount'] != null
          ? (data['originalAmount'] as num).toDouble()
          : null,
      currency: data['currency'] ?? 'RUB',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      failedAt: data['failedAt'] != null
          ? (data['failedAt'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'],
      transactionId: data['transactionId'],
      description: data['description'],
      metadata: data['metadata'],
      organizationType: _parseOrganizationType(data['organizationType']),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'specialistId': specialistId,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'originalAmount': originalAmount,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'description': description,
      'metadata': metadata,
      'organizationType': organizationType.name,
    };
  }

  /// Копировать с изменениями
  Payment copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? specialistId,
    PaymentType? type,
    PaymentStatus? status,
    double? amount,
    double? originalAmount,
    String? currency,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? failedAt,
    String? paymentMethod,
    String? transactionId,
    String? description,
    Map<String, dynamic>? metadata,
    OrganizationType? organizationType,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      originalAmount: originalAmount ?? this.originalAmount,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      organizationType: organizationType ?? this.organizationType,
    );
  }

  /// Получить отображаемое название типа платежа
  String get typeDisplayName {
    switch (type) {
      case PaymentType.advance:
        return 'Аванс';
      case PaymentType.finalPayment:
        return 'Финальный платеж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
      case PaymentType.refund:
        return 'Возврат';
    }
  }

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает оплаты';
      case PaymentStatus.processing:
        return 'Обрабатывается';
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

  /// Получить цвет статуса
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

  /// Проверить, завершен ли платеж
  bool get isCompleted => status == PaymentStatus.completed;

  /// Проверить, ожидает ли платеж
  bool get isPending => status == PaymentStatus.pending;

  /// Проверить, неудачный ли платеж
  bool get isFailed => status == PaymentStatus.failed;

  /// Парсинг типа платежа
  static PaymentType _parsePaymentType(dynamic typeData) {
    if (typeData == null) return PaymentType.advance;

    final typeString = typeData.toString().toLowerCase();
    switch (typeString) {
      case 'finalPayment':
        return PaymentType.finalPayment;
      case 'fullPayment':
        return PaymentType.fullPayment;
      case 'refund':
        return PaymentType.refund;
      case 'advance':
      default:
        return PaymentType.advance;
    }
  }

  /// Парсинг статуса платежа
  static PaymentStatus _parsePaymentStatus(dynamic statusData) {
    if (statusData == null) return PaymentStatus.pending;

    final statusString = statusData.toString().toLowerCase();
    switch (statusString) {
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  /// Парсинг типа организации
  static OrganizationType _parseOrganizationType(dynamic typeData) {
    if (typeData == null) return OrganizationType.individual;

    final typeString = typeData.toString().toLowerCase();
    switch (typeString) {
      case 'commercial':
        return OrganizationType.commercial;
      case 'government':
        return OrganizationType.government;
      case 'nonprofit':
      case 'non_profit':
        return OrganizationType.nonProfit;
      case 'individual':
      default:
        return OrganizationType.individual;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Payment(id: $id, type: $type, status: $status, amount: $amount)';
  }

  /// Создать объект из Map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      specialistId: map['specialistId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'RUB',
      type: PaymentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PaymentType.fullPayment,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] ?? '',
      transactionId: map['transactionId'],
      description: map['description'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

/// Конфигурация платежей для разных типов организаций
class PaymentConfiguration {
  final OrganizationType organizationType;
  final double advancePercentage; // Процент аванса
  final bool requiresAdvance; // Требуется ли аванс
  final bool allowsPostPayment; // Разрешена ли постоплата
  final double? maxAdvanceAmount; // Максимальная сумма аванса
  final Duration? advanceDeadline; // Срок оплаты аванса
  final Duration? finalPaymentDeadline; // Срок финального платежа

  const PaymentConfiguration({
    required this.organizationType,
    required this.advancePercentage,
    required this.requiresAdvance,
    required this.allowsPostPayment,
    this.maxAdvanceAmount,
    this.advanceDeadline,
    this.finalPaymentDeadline,
  });

  /// Получить конфигурацию по умолчанию для типа организации
  static PaymentConfiguration getDefault(OrganizationType type) {
    switch (type) {
      case OrganizationType.individual:
        return const PaymentConfiguration(
          organizationType: OrganizationType.individual,
          advancePercentage: 30.0,
          requiresAdvance: true,
          allowsPostPayment: false,
          advanceDeadline: Duration(days: 3),
          finalPaymentDeadline: Duration(days: 1),
        );
      case OrganizationType.commercial:
        return const PaymentConfiguration(
          organizationType: OrganizationType.commercial,
          advancePercentage: 30.0,
          requiresAdvance: true,
          allowsPostPayment: false,
          advanceDeadline: Duration(days: 7),
          finalPaymentDeadline: Duration(days: 3),
        );
      case OrganizationType.government:
        return const PaymentConfiguration(
          organizationType: OrganizationType.government,
          advancePercentage: 0.0, // Госучреждения часто работают по постоплате
          requiresAdvance: false,
          allowsPostPayment: true,
          finalPaymentDeadline: Duration(days: 30),
        );
      case OrganizationType.nonProfit:
        return const PaymentConfiguration(
          organizationType: OrganizationType.nonProfit,
          advancePercentage: 20.0,
          requiresAdvance: true,
          allowsPostPayment: true,
          advanceDeadline: Duration(days: 5),
          finalPaymentDeadline: Duration(days: 7),
        );
    }
  }

  /// Рассчитать сумму аванса
  double calculateAdvanceAmount(double totalAmount) {
    if (!requiresAdvance) return 0.0;

    final advanceAmount = totalAmount * (advancePercentage / 100);

    if (maxAdvanceAmount != null && advanceAmount > maxAdvanceAmount!) {
      return maxAdvanceAmount!;
    }

    return advanceAmount;
  }

  /// Рассчитать сумму финального платежа
  double calculateFinalAmount(double totalAmount, double advanceAmount) {
    return totalAmount - advanceAmount;
  }
}
