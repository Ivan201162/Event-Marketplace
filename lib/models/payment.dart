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
  selfEmployed, // Самозанятый
  entrepreneur, // ИП
}

/// Типы налогов
enum TaxType {
  none, // Без налога
  professionalIncome, // Налог на профессиональный доход (самозанятые)
  simplifiedTax, // Упрощенная система налогообложения (ИП)
  vat, // НДС
}

/// Провайдеры платежей
enum PaymentProvider {
  yooKassa, // ЮKassa
  cloudPayments, // CloudPayments
  mock, // Имитация для тестирования
}

/// Модель платежа
class Payment {
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
    this.prepaymentAmount = 0.0,
    this.taxAmount = 0.0,
    this.taxRate = 0.0,
    this.taxType,
  });

  /// Создать из документа Firestore
  factory Payment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
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
      prepaymentAmount: (data['prepaymentAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxType: _parseTaxType(data['taxType']),
    );
  }

  /// Создать объект из Map
  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] ?? '',
        bookingId: map['bookingId'] ?? '',
        userId: map['userId'] ?? '',
        customerId: map['customerId'] ?? map['userId'] ?? '',
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
        prepaymentAmount: (map['prepaymentAmount'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
        taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
        taxType: _parseTaxType(map['taxType']),
      );
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
  final double prepaymentAmount;
  final double taxAmount;
  final double taxRate;
  final TaxType? taxType;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'userId': userId,
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
        'prepaymentAmount': prepaymentAmount,
        'taxAmount': taxAmount,
        'taxRate': taxRate,
        'taxType': taxType?.name,
      };

  /// Копировать с изменениями
  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
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
    double? prepaymentAmount,
    double? taxAmount,
    double? taxRate,
    TaxType? taxType,
  }) =>
      Payment(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        userId: userId ?? this.userId,
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
        prepaymentAmount: prepaymentAmount ?? this.prepaymentAmount,
        taxAmount: taxAmount ?? this.taxAmount,
        taxRate: taxRate ?? this.taxRate,
        taxType: taxType ?? this.taxType,
      );

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
  static PaymentType _parsePaymentType(typeData) {
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
  static PaymentStatus _parsePaymentStatus(statusData) {
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
  static OrganizationType _parseOrganizationType(typeData) {
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
      case 'selfemployed':
      case 'self_employed':
        return OrganizationType.selfEmployed;
      case 'entrepreneur':
        return OrganizationType.entrepreneur;
      case 'individual':
      default:
        return OrganizationType.individual;
    }
  }

  /// Парсинг типа налога
  static TaxType? _parseTaxType(typeData) {
    if (typeData == null) return null;

    final typeString = typeData.toString().toLowerCase();
    switch (typeString) {
      case 'professionalincome':
      case 'professional_income':
        return TaxType.professionalIncome;
      case 'simplifiedtax':
      case 'simplified_tax':
        return TaxType.simplifiedTax;
      case 'vat':
        return TaxType.vat;
      case 'none':
      default:
        return TaxType.none;
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
  String toString() =>
      'Payment(id: $id, type: $type, status: $status, amount: $amount)';
}

/// Конфигурация платежей для разных типов организаций
class PaymentConfiguration {
  // Срок финального платежа

  const PaymentConfiguration({
    required this.organizationType,
    required this.advancePercentage,
    required this.requiresAdvance,
    required this.allowsPostPayment,
    this.maxAdvanceAmount,
    this.advanceDeadline,
    this.finalPaymentDeadline,
  });
  final OrganizationType organizationType;
  final double advancePercentage; // Процент аванса
  final bool requiresAdvance; // Требуется ли аванс
  final bool allowsPostPayment; // Разрешена ли постоплата
  final double? maxAdvanceAmount; // Максимальная сумма аванса
  final Duration? advanceDeadline; // Срок оплаты аванса
  final Duration? finalPaymentDeadline;

  /// Получить конфигурацию по умолчанию для типа организации
  static PaymentConfiguration getDefault(OrganizationType type) {
    switch (type) {
      case OrganizationType.individual:
        return const PaymentConfiguration(
          organizationType: OrganizationType.individual,
          advancePercentage: 30,
          requiresAdvance: true,
          allowsPostPayment: false,
          advanceDeadline: Duration(days: 3),
          finalPaymentDeadline: Duration(days: 1),
        );
      case OrganizationType.commercial:
        return const PaymentConfiguration(
          organizationType: OrganizationType.commercial,
          advancePercentage: 30,
          requiresAdvance: true,
          allowsPostPayment: false,
          advanceDeadline: Duration(days: 7),
          finalPaymentDeadline: Duration(days: 3),
        );
      case OrganizationType.government:
        return const PaymentConfiguration(
          organizationType: OrganizationType.government,
          advancePercentage: 0, // Госучреждения часто работают по постоплате
          requiresAdvance: false,
          allowsPostPayment: true,
          finalPaymentDeadline: Duration(days: 30),
        );
      case OrganizationType.nonProfit:
        return const PaymentConfiguration(
          organizationType: OrganizationType.nonProfit,
          advancePercentage: 20,
          requiresAdvance: true,
          allowsPostPayment: true,
          advanceDeadline: Duration(days: 5),
          finalPaymentDeadline: Duration(days: 7),
        );
      case OrganizationType.selfEmployed:
        return const PaymentConfiguration(
          organizationType: OrganizationType.selfEmployed,
          advancePercentage: 30,
          requiresAdvance: true,
          allowsPostPayment: false,
          advanceDeadline: Duration(days: 3),
          finalPaymentDeadline: Duration(days: 1),
        );
      case OrganizationType.entrepreneur:
        return const PaymentConfiguration(
          organizationType: OrganizationType.entrepreneur,
          advancePercentage: 30,
          requiresAdvance: true,
          allowsPostPayment: false,
          advanceDeadline: Duration(days: 5),
          finalPaymentDeadline: Duration(days: 3),
        );
    }
  }

  /// Рассчитать сумму аванса
  double calculateAdvanceAmount(double totalAmount) {
    if (!requiresAdvance) return 0;

    final advanceAmount = totalAmount * (advancePercentage / 100);

    if (maxAdvanceAmount != null && advanceAmount > maxAdvanceAmount!) {
      return maxAdvanceAmount!;
    }

    return advanceAmount;
  }

  /// Рассчитать сумму финального платежа
  double calculateFinalAmount(double totalAmount, double advanceAmount) =>
      totalAmount - advanceAmount;
}

/// Класс для расчёта налогов
class TaxCalculator {
  /// Рассчитать налог для самозанятого (налог на профессиональный доход)
  static double calculateProfessionalIncomeTax(double amount) {
    // Налог на профессиональный доход: 4% с доходов от физлиц, 6% с доходов от ИП/юрлиц
    return amount * 0.04; // По умолчанию 4% для физлиц
  }

  /// Рассчитать налог для ИП (УСН 6%)
  static double calculateSimplifiedTax(double amount) {
    // УСН "Доходы" - 6% с доходов
    return amount * 0.06;
  }

  /// Рассчитать НДС
  static double calculateVAT(double amount) {
    // НДС 20%
    return amount * 0.20;
  }

  /// Рассчитать налог в зависимости от типа
  static double calculateTax(double amount, TaxType taxType, {bool isFromLegalEntity = false}) {
    switch (taxType) {
      case TaxType.professionalIncome:
        return isFromLegalEntity ? amount * 0.06 : amount * 0.04;
      case TaxType.simplifiedTax:
        return calculateSimplifiedTax(amount);
      case TaxType.vat:
        return calculateVAT(amount);
      case TaxType.none:
      default:
        return 0.0;
    }
  }

  /// Получить ставку налога в процентах
  static double getTaxRate(TaxType taxType, {bool isFromLegalEntity = false}) {
    switch (taxType) {
      case TaxType.professionalIncome:
        return isFromLegalEntity ? 6.0 : 4.0;
      case TaxType.simplifiedTax:
        return 6.0;
      case TaxType.vat:
        return 20.0;
      case TaxType.none:
      default:
        return 0.0;
    }
  }

  /// Получить название налога
  static String getTaxName(TaxType taxType) {
    switch (taxType) {
      case TaxType.professionalIncome:
        return 'Налог на профессиональный доход';
      case TaxType.simplifiedTax:
        return 'УСН (6%)';
      case TaxType.vat:
        return 'НДС (20%)';
      case TaxType.none:
      default:
        return 'Без налога';
    }
  }
}
