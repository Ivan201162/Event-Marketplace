import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы налогообложения для специалистов
enum TaxType {
  individual, // Физическое лицо
  selfEmployed, // Самозанятый
  individualEntrepreneur, // ИП
  government, // Государственное учреждение
}

/// Расширение для TaxType
extension TaxTypeExtension on TaxType {
  /// Получить отображаемое название
  String get displayName {
    switch (this) {
      case TaxType.individual:
        return 'Физическое лицо';
      case TaxType.selfEmployed:
        return 'Самозанятый';
      case TaxType.individualEntrepreneur:
        return 'Индивидуальный предприниматель';
      case TaxType.government:
        return 'Государственное учреждение';
    }
  }

  /// Получить описание
  String get description {
    switch (this) {
      case TaxType.individual:
        return 'Налог должен быть уплачен самостоятельно (13% НДФЛ)';
      case TaxType.selfEmployed:
        return 'Налог на профессиональный доход (4-6%)';
      case TaxType.individualEntrepreneur:
        return 'Упрощённая система налогообложения (6% или 15%)';
      case TaxType.government:
        return 'Освобождено от налогообложения';
    }
  }

  /// Получить иконку
  String get icon {
    switch (this) {
      case TaxType.individual:
        return '👤';
      case TaxType.selfEmployed:
        return '💼';
      case TaxType.individualEntrepreneur:
        return '🏢';
      case TaxType.government:
        return '🏛️';
    }
  }

  /// Получить налоговую ставку по умолчанию
  double get defaultTaxRate {
    switch (this) {
      case TaxType.individual:
        return 0.13; // 13% НДФЛ
      case TaxType.selfEmployed:
        return 0.04; // 4% для самозанятых
      case TaxType.individualEntrepreneur:
        return 0.06; // 6% УСН "доходы"
      case TaxType.government:
        return 0; // Освобождено
    }
  }
}

/// Модель налоговой информации специалиста
class TaxInfo {
  const TaxInfo({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.taxType,
    required this.taxRate,
    required this.income,
    required this.taxAmount,
    required this.period,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.paymentMethod,
    this.notes,
    this.isPaid = false,
    this.reminderSent = false,
    this.nextReminderDate,
  });

  /// Создать из документа Firestore
  factory TaxInfo.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return TaxInfo(
      id: doc.id,
      userId: data['userId'] as String,
      specialistId: data['specialistId'] as String,
      taxType: TaxType.values.firstWhere(
        (e) => e.name == data['taxType'],
        orElse: () => TaxType.individual,
      ),
      taxRate: (data['taxRate'] as num).toDouble(),
      income: (data['income'] as num).toDouble(),
      taxAmount: (data['taxAmount'] as num).toDouble(),
      period: data['period'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
      paymentMethod: data['paymentMethod'] as String?,
      notes: data['notes'] as String?,
      isPaid: data['isPaid'] as bool? ?? false,
      reminderSent: data['reminderSent'] as bool? ?? false,
      nextReminderDate: data['nextReminderDate'] != null
          ? (data['nextReminderDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Создать из Map
  factory TaxInfo.fromMap(Map<String, dynamic> data) => TaxInfo(
        id: data['id'] as String,
        userId: data['userId'] as String,
        specialistId: data['specialistId'] as String,
        taxType: TaxType.values.firstWhere(
          (e) => e.name == data['taxType'],
          orElse: () => TaxType.individual,
        ),
        taxRate: (data['taxRate'] as num).toDouble(),
        income: (data['income'] as num).toDouble(),
        taxAmount: (data['taxAmount'] as num).toDouble(),
        period: data['period'] as String,
        createdAt:
            data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
        updatedAt:
            data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
        paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
        paymentMethod: data['paymentMethod'] as String?,
        notes: data['notes'] as String?,
        isPaid: data['isPaid'] as bool? ?? false,
        reminderSent: data['reminderSent'] as bool? ?? false,
        nextReminderDate: data['nextReminderDate'] != null
            ? (data['nextReminderDate'] as Timestamp).toDate()
            : null,
      );

  final String id;
  final String userId;
  final String specialistId;
  final TaxType taxType;
  final double taxRate;
  final double income;
  final double taxAmount;
  final String period; // Например: "2024-01", "2024-Q1"
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? notes;
  final bool isPaid;
  final bool reminderSent;
  final DateTime? nextReminderDate;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'specialistId': specialistId,
        'taxType': taxType.name,
        'taxRate': taxRate,
        'income': income,
        'taxAmount': taxAmount,
        'period': period,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
        'paymentMethod': paymentMethod,
        'notes': notes,
        'isPaid': isPaid,
        'reminderSent': reminderSent,
        'nextReminderDate': nextReminderDate != null ? Timestamp.fromDate(nextReminderDate!) : null,
      };

  /// Копировать с изменениями
  TaxInfo copyWith({
    String? id,
    String? userId,
    String? specialistId,
    TaxType? taxType,
    double? taxRate,
    double? income,
    double? taxAmount,
    String? period,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    String? paymentMethod,
    String? notes,
    bool? isPaid,
    bool? reminderSent,
    DateTime? nextReminderDate,
  }) =>
      TaxInfo(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        specialistId: specialistId ?? this.specialistId,
        taxType: taxType ?? this.taxType,
        taxRate: taxRate ?? this.taxRate,
        income: income ?? this.income,
        taxAmount: taxAmount ?? this.taxAmount,
        period: period ?? this.period,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        paidAt: paidAt ?? this.paidAt,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        notes: notes ?? this.notes,
        isPaid: isPaid ?? this.isPaid,
        reminderSent: reminderSent ?? this.reminderSent,
        nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      );

  /// Получить отображаемое название типа налогообложения
  String get taxTypeDisplayName => taxType.displayName;

  /// Получить описание типа налогообложения
  String get taxTypeDescription => taxType.description;

  /// Получить иконку типа налогообложения
  String get taxTypeIcon => taxType.icon;

  /// Получить отформатированную сумму дохода
  String get formattedIncome => '${income.toStringAsFixed(0)} ₽';

  /// Получить отформатированную сумму налога
  String get formattedTaxAmount => '${taxAmount.toStringAsFixed(0)} ₽';

  /// Получить отформатированную налоговую ставку
  String get formattedTaxRate => '${(taxRate * 100).toStringAsFixed(1)}%';

  /// Получить статус оплаты
  String get paymentStatus {
    if (isPaid) {
      return 'Оплачено';
    } else {
      return 'Не оплачено';
    }
  }

  /// Получить цвет статуса оплаты
  String get paymentStatusColor => isPaid ? 'green' : 'red';

  /// Проверить, просрочен ли налог
  bool get isOverdue {
    if (isPaid) return false;

    // Для месячных периодов - проверяем, прошёл ли месяц
    if (period.contains('-')) {
      final parts = period.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year != null && month != null) {
          final periodDate = DateTime(year, month);
          final now = DateTime.now();
          return now.isAfter(periodDate.add(const Duration(days: 30)));
        }
      }
    }

    return false;
  }

  /// Получить дату следующего напоминания
  DateTime get nextReminder {
    if (nextReminderDate != null) {
      return nextReminderDate!;
    }

    // По умолчанию - через 7 дней после создания
    return createdAt.add(const Duration(days: 7));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaxInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TaxInfo(id: $id, userId: $userId, taxType: $taxType, income: $income, taxAmount: $taxAmount)';
}

/// Сводка по налогам за период
class TaxSummary {
  const TaxSummary({
    required this.period,
    required this.totalIncome,
    required this.totalTaxAmount,
    required this.taxRecords,
    required this.paidAmount,
    required this.unpaidAmount,
    required this.overdueAmount,
  });

  final String period;
  final double totalIncome;
  final double totalTaxAmount;
  final List<TaxInfo> taxRecords;
  final double paidAmount;
  final double unpaidAmount;
  final double overdueAmount;

  /// Получить отформатированную общую сумму дохода
  String get formattedTotalIncome => '${totalIncome.toStringAsFixed(0)} ₽';

  /// Получить отформатированную общую сумму налога
  String get formattedTotalTaxAmount => '${totalTaxAmount.toStringAsFixed(0)} ₽';

  /// Получить отформатированную оплаченную сумму
  String get formattedPaidAmount => '${paidAmount.toStringAsFixed(0)} ₽';

  /// Получить отформатированную неоплаченную сумму
  String get formattedUnpaidAmount => '${unpaidAmount.toStringAsFixed(0)} ₽';

  /// Получить отформатированную просроченную сумму
  String get formattedOverdueAmount => '${overdueAmount.toStringAsFixed(0)} ₽';

  /// Получить процент оплаты
  double get paymentPercentage {
    if (totalTaxAmount == 0) return 100;
    return (paidAmount / totalTaxAmount) * 100;
  }

  /// Получить отформатированный процент оплаты
  String get formattedPaymentPercentage => '${paymentPercentage.toStringAsFixed(1)}%';
}
