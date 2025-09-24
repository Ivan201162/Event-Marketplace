import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус налогоплательщика
enum TaxpayerStatus {
  individual, // Физическое лицо
  individualEntrepreneur, // Индивидуальный предприниматель
  selfEmployed, // Самозанятый
  governmentInstitution, // Государственное учреждение
  nonProfit, // Некоммерческая организация
}

/// Тип налога
enum TaxType {
  incomeTax, // Налог на доходы физических лиц (НДФЛ)
  simplifiedTax, // Упрощённая система налогообложения (УСН)
  professionalIncomeTax, // Налог на профессиональный доход (НПД)
  vat, // Налог на добавленную стоимость (НДС)
}

/// Модель налогового учёта
class TaxRecord {
  const TaxRecord({
    required this.id,
    required this.specialistId,
    required this.paymentId,
    required this.amount,
    required this.taxType,
    required this.taxRate,
    required this.taxAmount,
    required this.netAmount,
    required this.period,
    required this.createdAt,
    this.paidAt,
    this.deadline,
    this.status,
    this.metadata,
  });

  final String id;
  final String specialistId;
  final String paymentId;
  final double amount; // Общая сумма
  final TaxType taxType;
  final double taxRate; // Ставка налога в процентах
  final double taxAmount; // Сумма налога
  final double netAmount; // Чистая сумма после налога
  final String period; // Период (например, "2024-01")
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? deadline;
  final String? status;
  final Map<String, dynamic>? metadata;

  /// Создать из Map
  factory TaxRecord.fromMap(Map<String, dynamic> data) {
    return TaxRecord(
      id: data['id'] as String,
      specialistId: data['specialistId'] as String,
      paymentId: data['paymentId'] as String,
      amount: (data['amount'] as num).toDouble(),
      taxType: TaxType.values.firstWhere(
        (e) => e.name == data['taxType'],
        orElse: () => TaxType.incomeTax,
      ),
      taxRate: (data['taxRate'] as num).toDouble(),
      taxAmount: (data['taxAmount'] as num).toDouble(),
      netAmount: (data['netAmount'] as num).toDouble(),
      period: data['period'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      deadline: data['deadline'] != null
          ? (data['deadline'] as Timestamp).toDate()
          : null,
      status: data['status'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'specialistId': specialistId,
      'paymentId': paymentId,
      'amount': amount,
      'taxType': taxType.name,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'netAmount': netAmount,
      'period': period,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'status': status,
      'metadata': metadata,
    };
  }

  /// Получить отображаемое имя типа налога
  String get taxTypeDisplayName {
    switch (taxType) {
      case TaxType.incomeTax:
        return 'НДФЛ';
      case TaxType.simplifiedTax:
        return 'УСН';
      case TaxType.professionalIncomeTax:
        return 'НПД';
      case TaxType.vat:
        return 'НДС';
    }
  }

  /// Проверить, оплачен ли налог
  bool get isPaid => paidAt != null;

  /// Проверить, просрочен ли налог
  bool get isOverdue => deadline != null && DateTime.now().isAfter(deadline!) && !isPaid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaxRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TaxRecord{id: $id, specialistId: $specialistId, taxType: $taxType, taxAmount: $taxAmount}';
  }
}

/// Модель налогового профиля специалиста
class TaxProfile {
  const TaxProfile({
    required this.specialistId,
    required this.taxpayerStatus,
    required this.taxNumber,
    required this.updatedAt,
    this.inn, // ИНН
    this.snils, // СНИЛС
    this.ogrnip, // ОГРНИП (для ИП)
    this.taxRate, // Ставка налога
    this.taxType, // Тип налогообложения
    this.isActive,
    this.metadata,
  });

  final String specialistId;
  final TaxpayerStatus taxpayerStatus;
  final String taxNumber;
  final DateTime updatedAt;
  final String? inn;
  final String? snils;
  final String? ogrnip;
  final double? taxRate;
  final TaxType? taxType;
  final bool? isActive;
  final Map<String, dynamic>? metadata;

  /// Создать из Map
  factory TaxProfile.fromMap(Map<String, dynamic> data) {
    return TaxProfile(
      specialistId: data['specialistId'] as String,
      taxpayerStatus: TaxpayerStatus.values.firstWhere(
        (e) => e.name == data['taxpayerStatus'],
        orElse: () => TaxpayerStatus.individual,
      ),
      taxNumber: data['taxNumber'] as String,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      inn: data['inn'] as String?,
      snils: data['snils'] as String?,
      ogrnip: data['ogrnip'] as String?,
      taxRate: data['taxRate'] != null ? (data['taxRate'] as num).toDouble() : null,
      taxType: data['taxType'] != null
          ? TaxType.values.firstWhere(
              (e) => e.name == data['taxType'],
              orElse: () => TaxType.incomeTax,
            )
          : null,
      isActive: data['isActive'] as bool?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'taxpayerStatus': taxpayerStatus.name,
      'taxNumber': taxNumber,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'inn': inn,
      'snils': snils,
      'ogrnip': ogrnip,
      'taxRate': taxRate,
      'taxType': taxType?.name,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Получить отображаемое имя статуса налогоплательщика
  String get taxpayerStatusDisplayName {
    switch (taxpayerStatus) {
      case TaxpayerStatus.individual:
        return 'Физическое лицо';
      case TaxpayerStatus.individualEntrepreneur:
        return 'Индивидуальный предприниматель';
      case TaxpayerStatus.selfEmployed:
        return 'Самозанятый';
      case TaxpayerStatus.governmentInstitution:
        return 'Государственное учреждение';
      case TaxpayerStatus.nonProfit:
        return 'Некоммерческая организация';
    }
  }

  /// Получить рекомендуемую ставку налога
  double get recommendedTaxRate {
    switch (taxpayerStatus) {
      case TaxpayerStatus.individual:
        return 13.0; // НДФЛ
      case TaxpayerStatus.individualEntrepreneur:
        return 6.0; // УСН "Доходы"
      case TaxpayerStatus.selfEmployed:
        return 4.0; // НПД для услуг
      case TaxpayerStatus.governmentInstitution:
        return 0.0; // Освобождены от налогов
      case TaxpayerStatus.nonProfit:
        return 0.0; // Освобождены от налогов
    }
  }

  /// Получить рекомендуемый тип налога
  TaxType get recommendedTaxType {
    switch (taxpayerStatus) {
      case TaxpayerStatus.individual:
        return TaxType.incomeTax;
      case TaxpayerStatus.individualEntrepreneur:
        return TaxType.simplifiedTax;
      case TaxpayerStatus.selfEmployed:
        return TaxType.professionalIncomeTax;
      case TaxpayerStatus.governmentInstitution:
        return TaxType.incomeTax; // Не применяется
      case TaxpayerStatus.nonProfit:
        return TaxType.incomeTax; // Не применяется
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaxProfile &&
          runtimeType == other.runtimeType &&
          specialistId == other.specialistId;

  @override
  int get hashCode => specialistId.hashCode;

  @override
  String toString() {
    return 'TaxProfile{specialistId: $specialistId, taxpayerStatus: $taxpayerStatus}';
  }
}
