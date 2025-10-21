import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус налогообложения
enum TaxStatus {
  none, // Без налогообложения
  professionalIncome, // НПД (самозанятые)
  simplifiedTax, // УСН
  vat, // НДС
}

/// Модель расчета налогов
class TaxCalculation {
  const TaxCalculation({
    required this.id,
    required this.paymentId,
    required this.grossAmount,
    required this.taxAmount,
    required this.netAmount,
    required this.taxRate,
    required this.taxStatus,
    required this.calculatedAt,
    this.description,
    this.metadata,
  });

  final String id;
  final String paymentId;
  final double grossAmount;
  final double taxAmount;
  final double netAmount;
  final double taxRate;
  final TaxStatus taxStatus;
  final DateTime calculatedAt;
  final String? description;
  final Map<String, dynamic>? metadata;

  /// Создать из Map
  factory TaxCalculation.fromMap(Map<String, dynamic> data) {
    return TaxCalculation(
      id: data['id'] as String? ?? '',
      paymentId: data['paymentId'] as String? ?? '',
      grossAmount: (data['grossAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (data['netAmount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxStatus: _parseTaxStatus(data['taxStatus']),
      calculatedAt: data['calculatedAt'] != null
          ? (data['calculatedAt'] is Timestamp
                ? (data['calculatedAt'] as Timestamp).toDate()
                : DateTime.parse(data['calculatedAt'].toString()))
          : DateTime.now(),
      description: data['description'] as String?,
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
    );
  }

  /// Создать из документа Firestore
  factory TaxCalculation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return TaxCalculation.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'paymentId': paymentId,
    'grossAmount': grossAmount,
    'taxAmount': taxAmount,
    'netAmount': netAmount,
    'taxRate': taxRate,
    'taxStatus': taxStatus.name,
    'calculatedAt': Timestamp.fromDate(calculatedAt),
    'description': description,
    'metadata': metadata,
  };

  /// Копировать с изменениями
  TaxCalculation copyWith({
    String? id,
    String? paymentId,
    double? grossAmount,
    double? taxAmount,
    double? netAmount,
    double? taxRate,
    TaxStatus? taxStatus,
    DateTime? calculatedAt,
    String? description,
    Map<String, dynamic>? metadata,
  }) => TaxCalculation(
    id: id ?? this.id,
    paymentId: paymentId ?? this.paymentId,
    grossAmount: grossAmount ?? this.grossAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    netAmount: netAmount ?? this.netAmount,
    taxRate: taxRate ?? this.taxRate,
    taxStatus: taxStatus ?? this.taxStatus,
    calculatedAt: calculatedAt ?? this.calculatedAt,
    description: description ?? this.description,
    metadata: metadata ?? this.metadata,
  );

  /// Парсинг статуса налогообложения из строки
  static TaxStatus _parseTaxStatus(String? status) {
    switch (status) {
      case 'none':
        return TaxStatus.none;
      case 'professionalIncome':
        return TaxStatus.professionalIncome;
      case 'simplifiedTax':
        return TaxStatus.simplifiedTax;
      case 'vat':
        return TaxStatus.vat;
      default:
        return TaxStatus.none;
    }
  }

  /// Получить отображаемое название статуса налогообложения
  String get taxStatusDisplayName {
    switch (taxStatus) {
      case TaxStatus.none:
        return 'Без налогообложения';
      case TaxStatus.professionalIncome:
        return 'НПД (самозанятые)';
      case TaxStatus.simplifiedTax:
        return 'УСН';
      case TaxStatus.vat:
        return 'НДС';
    }
  }

  /// Получить отформатированную валовую сумму
  String get formattedGrossAmount => '${grossAmount.toStringAsFixed(2)} ₽';

  /// Получить отформатированную налоговую сумму
  String get formattedTaxAmount => '${taxAmount.toStringAsFixed(2)} ₽';

  /// Получить отформатированную чистую сумму
  String get formattedNetAmount => '${netAmount.toStringAsFixed(2)} ₽';

  /// Получить отформатированную налоговую ставку
  String get formattedTaxRate => '${taxRate.toStringAsFixed(1)}%';
}

/// Расширение для TaxStatus
extension TaxStatusExtension on TaxStatus {
  String get displayName {
    switch (this) {
      case TaxStatus.none:
        return 'Без налогообложения';
      case TaxStatus.professionalIncome:
        return 'НПД (самозанятые)';
      case TaxStatus.simplifiedTax:
        return 'УСН';
      case TaxStatus.vat:
        return 'НДС';
    }
  }

  String get description {
    switch (this) {
      case TaxStatus.none:
        return 'Налог должен быть уплачен самостоятельно';
      case TaxStatus.professionalIncome:
        return 'Налог на профессиональный доход (4-6%)';
      case TaxStatus.simplifiedTax:
        return 'Упрощённая система налогообложения (6% или 15%)';
      case TaxStatus.vat:
        return 'Налог на добавленную стоимость (20%)';
    }
  }

  double get defaultRate {
    switch (this) {
      case TaxStatus.none:
        return 0.0;
      case TaxStatus.professionalIncome:
        return 4.0; // 4% для самозанятых
      case TaxStatus.simplifiedTax:
        return 6.0; // 6% УСН "доходы"
      case TaxStatus.vat:
        return 20.0; // 20% НДС
    }
  }
}
