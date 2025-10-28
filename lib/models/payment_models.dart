import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус платежа
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded
}

/// Тип платежного метода
enum PaymentMethodType { card, bankTransfer, digitalWallet, cash, other }

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get icon {
    switch (this) {
      case PaymentMethodType.card:
        return 'credit_card';
      case PaymentMethodType.bankTransfer:
        return 'account_balance';
      case PaymentMethodType.digitalWallet:
        return 'account_balance_wallet';
      case PaymentMethodType.cash:
        return 'money';
      case PaymentMethodType.other:
        return 'payment';
    }
  }
}

/// Информация о платежном методе
class PaymentMethodInfo {
  const PaymentMethodInfo({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.createdAt, this.cardLast4,
    this.cardBrand,
    this.isDefault = false,
    this.isActive = true,
    this.updatedAt,
  });

  /// Создать из Map
  factory PaymentMethodInfo.fromMap(Map<String, dynamic> data) {
    return PaymentMethodInfo(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: _parseType(data['type']),
      name: data['name'] as String? ?? '',
      cardLast4: data['cardLast4'] as String?,
      cardBrand: data['cardBrand'] as String?,
      isDefault: data['isDefault'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Get icon for payment method
  String get icon => type.icon;

  /// Get display name for payment method
  String get displayName {
    switch (type) {
      case PaymentMethodType.card:
        return 'Банковская карта';
      case PaymentMethodType.bankTransfer:
        return 'Банковский перевод';
      case PaymentMethodType.digitalWallet:
        return 'Цифровой кошелек';
      case PaymentMethodType.cash:
        return 'Наличные';
      case PaymentMethodType.other:
        return 'Другое';
    }
  }

  final String id;
  final String userId;
  final PaymentMethodType type;
  final String name;
  final String? cardLast4;
  final String? cardBrand;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'name': name,
        'cardLast4': cardLast4,
        'cardBrand': cardBrand,
        'isDefault': isDefault,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  PaymentMethodInfo copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? name,
    String? cardLast4,
    String? cardBrand,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PaymentMethodInfo(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        name: name ?? this.name,
        cardLast4: cardLast4 ?? this.cardLast4,
        cardBrand: cardBrand ?? this.cardBrand,
        isDefault: isDefault ?? this.isDefault,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг типа из строки
  static PaymentMethodType _parseType(String? type) {
    switch (type) {
      case 'card':
        return PaymentMethodType.card;
      case 'bankTransfer':
        return PaymentMethodType.bankTransfer;
      case 'digitalWallet':
        return PaymentMethodType.digitalWallet;
      case 'cash':
        return PaymentMethodType.cash;
      case 'other':
        return PaymentMethodType.other;
      default:
        return PaymentMethodType.other;
    }
  }

  /// Получить отображаемое название типа
  String get typeDisplayName {
    switch (type) {
      case PaymentMethodType.card:
        return 'Банковская карта';
      case PaymentMethodType.bankTransfer:
        return 'Банковский перевод';
      case PaymentMethodType.digitalWallet:
        return 'Электронный кошелек';
      case PaymentMethodType.cash:
        return 'Наличные';
      case PaymentMethodType.other:
        return 'Другое';
    }
  }

  /// Получить маскированный номер карты
  String get maskedCardNumber {
    if (cardLast4 == null) return name;
    return '**** **** **** $cardLast4';
  }
}

/// Модель платежного метода
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.createdAt, this.cardLast4,
    this.cardBrand,
    this.isDefault = false,
    this.isActive = true,
    this.updatedAt,
  });

  /// Создать из Map
  factory PaymentMethod.fromMap(Map<String, dynamic> data) {
    return PaymentMethod(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: _parseType(data['type']),
      name: data['name'] as String? ?? '',
      cardLast4: data['cardLast4'] as String?,
      cardBrand: data['cardBrand'] as String?,
      isDefault: data['isDefault'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return PaymentMethod.fromMap({'id': doc.id, ...data});
  }

  /// Get icon for payment method
  String get icon => type.icon;

  /// Get display name for payment method
  String get displayName {
    switch (type) {
      case PaymentMethodType.card:
        return 'Банковская карта';
      case PaymentMethodType.bankTransfer:
        return 'Банковский перевод';
      case PaymentMethodType.digitalWallet:
        return 'Цифровой кошелек';
      case PaymentMethodType.cash:
        return 'Наличные';
      case PaymentMethodType.other:
        return 'Другое';
    }
  }

  final String id;
  final String userId;
  final PaymentMethodType type;
  final String name;
  final String? cardLast4;
  final String? cardBrand;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'name': name,
        'cardLast4': cardLast4,
        'cardBrand': cardBrand,
        'isDefault': isDefault,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? name,
    String? cardLast4,
    String? cardBrand,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PaymentMethod(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        name: name ?? this.name,
        cardLast4: cardLast4 ?? this.cardLast4,
        cardBrand: cardBrand ?? this.cardBrand,
        isDefault: isDefault ?? this.isDefault,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг типа из строки
  static PaymentMethodType _parseType(String? type) {
    switch (type) {
      case 'card':
        return PaymentMethodType.card;
      case 'bankTransfer':
        return PaymentMethodType.bankTransfer;
      case 'digitalWallet':
        return PaymentMethodType.digitalWallet;
      case 'cash':
        return PaymentMethodType.cash;
      case 'other':
        return PaymentMethodType.other;
      default:
        return PaymentMethodType.other;
    }
  }

  /// Получить отображаемое название типа
  String get typeDisplayName {
    switch (type) {
      case PaymentMethodType.card:
        return 'Банковская карта';
      case PaymentMethodType.bankTransfer:
        return 'Банковский перевод';
      case PaymentMethodType.digitalWallet:
        return 'Электронный кошелек';
      case PaymentMethodType.cash:
        return 'Наличные';
      case PaymentMethodType.other:
        return 'Другое';
    }
  }

  /// Получить маскированный номер карты
  String get maskedCardNumber {
    if (cardLast4 == null) return name;
    return '**** **** **** $cardLast4';
  }
}

/// Модель платежа
class Payment {
  const Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt, this.paymentMethodId,
    this.paymentMethod,
    this.externalTransactionId,
    this.provider,
    this.description,
    this.metadata = const {},
    this.failureReason,
    this.processedAt,
    this.updatedAt,
  });

  /// Создать из Map
  factory Payment.fromMap(Map<String, dynamic> data) {
    return Payment(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'RUB',
      status: _parseStatus(data['status']),
      paymentMethodId: data['paymentMethodId'] as String?,
      paymentMethod: data['paymentMethod'] != null
          ? PaymentMethod.fromMap(
              Map<String, dynamic>.from(data['paymentMethod']),)
          : null,
      externalTransactionId: data['externalTransactionId'] as String?,
      provider: data['provider'] as String?,
      description: data['description'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      failureReason: data['failureReason'] as String?,
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] is Timestamp
              ? (data['processedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['processedAt'].toString()))
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Payment.fromMap({'id': doc.id, ...data});
  }

  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? paymentMethodId;
  final PaymentMethod? paymentMethod;
  final String? externalTransactionId;
  final String? provider;
  final String? description;
  final Map<String, dynamic> metadata;
  final String? failureReason;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'status': status.name,
        'paymentMethodId': paymentMethodId,
        'paymentMethod': paymentMethod?.toMap(),
        'externalTransactionId': externalTransactionId,
        'provider': provider,
        'description': description,
        'metadata': metadata,
        'failureReason': failureReason,
        'processedAt':
            processedAt != null ? Timestamp.fromDate(processedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  Payment copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? paymentMethodId,
    PaymentMethod? paymentMethod,
    String? externalTransactionId,
    String? provider,
    String? description,
    Map<String, dynamic>? metadata,
    String? failureReason,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Payment(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        status: status ?? this.status,
        paymentMethodId: paymentMethodId ?? this.paymentMethodId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        externalTransactionId:
            externalTransactionId ?? this.externalTransactionId,
        provider: provider ?? this.provider,
        description: description ?? this.description,
        metadata: metadata ?? this.metadata,
        failureReason: failureReason ?? this.failureReason,
        processedAt: processedAt ?? this.processedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг статуса из строки
  static PaymentStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
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
      default:
        return PaymentStatus.pending;
    }
  }

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает';
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

  /// Проверить, завершен ли платеж
  bool get isCompleted => status == PaymentStatus.completed;

  /// Проверить, неудачен ли платеж
  bool get isFailed => status == PaymentStatus.failed;

  /// Проверить, ожидает ли платеж
  bool get isPending => status == PaymentStatus.pending;

  /// Получить отформатированную сумму
  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} $currency';
  }
}

/// Модель статистики платежей
class PaymentStats {
  const PaymentStats({
    required this.userId,
    this.totalAmount = 0.0,
    this.totalTransactions = 0,
    this.successfulTransactions = 0,
    this.failedTransactions = 0,
    this.pendingTransactions = 0,
    this.averageTransactionAmount = 0.0,
    this.lastTransactionAt,
    this.period,
  });

  /// Создать из Map
  factory PaymentStats.fromMap(Map<String, dynamic> data) {
    return PaymentStats(
      userId: data['userId'] as String? ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: data['totalTransactions'] as int? ?? 0,
      successfulTransactions: data['successfulTransactions'] as int? ?? 0,
      failedTransactions: data['failedTransactions'] as int? ?? 0,
      pendingTransactions: data['pendingTransactions'] as int? ?? 0,
      averageTransactionAmount:
          (data['averageTransactionAmount'] as num?)?.toDouble() ?? 0.0,
      lastTransactionAt: data['lastTransactionAt'] != null
          ? (data['lastTransactionAt'] is Timestamp
              ? (data['lastTransactionAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['lastTransactionAt'].toString()))
          : null,
      period: data['period'] as String?,
    );
  }

  final String userId;
  final double totalAmount;
  final int totalTransactions;
  final int successfulTransactions;
  final int failedTransactions;
  final int pendingTransactions;
  final double averageTransactionAmount;
  final DateTime? lastTransactionAt;
  final String? period;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'totalAmount': totalAmount,
        'totalTransactions': totalTransactions,
        'successfulTransactions': successfulTransactions,
        'failedTransactions': failedTransactions,
        'pendingTransactions': pendingTransactions,
        'averageTransactionAmount': averageTransactionAmount,
        'lastTransactionAt': lastTransactionAt != null
            ? Timestamp.fromDate(lastTransactionAt!)
            : null,
        'period': period,
      };

  /// Копировать с изменениями
  PaymentStats copyWith({
    String? userId,
    double? totalAmount,
    int? totalTransactions,
    int? successfulTransactions,
    int? failedTransactions,
    int? pendingTransactions,
    double? averageTransactionAmount,
    DateTime? lastTransactionAt,
    String? period,
  }) =>
      PaymentStats(
        userId: userId ?? this.userId,
        totalAmount: totalAmount ?? this.totalAmount,
        totalTransactions: totalTransactions ?? this.totalTransactions,
        successfulTransactions:
            successfulTransactions ?? this.successfulTransactions,
        failedTransactions: failedTransactions ?? this.failedTransactions,
        pendingTransactions: pendingTransactions ?? this.pendingTransactions,
        averageTransactionAmount:
            averageTransactionAmount ?? this.averageTransactionAmount,
        lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
        period: period ?? this.period,
      );

  /// Получить процент успешных транзакций
  double get successRate {
    if (totalTransactions == 0) return 0;
    return (successfulTransactions / totalTransactions) * 100;
  }

  /// Получить процент неудачных транзакций
  double get failureRate {
    if (totalTransactions == 0) return 0;
    return (failedTransactions / totalTransactions) * 100;
  }

  /// Получить отформатированную общую сумму
  String get formattedTotalAmount {
    return '${totalAmount.toStringAsFixed(2)} RUB';
  }
}
