/// Модель PRO подписки
class ProSubscription {
  const ProSubscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.price = 0.0,
    this.currency = 'RUB',
    this.paymentMethod,
    this.autoRenew = true,
    this.trialEndDate,
    this.cancelledAt,
    this.cancellationReason,
    this.features = const {},
    this.metadata = const {},
  });

  /// Создать из Map
  factory ProSubscription.fromMap(Map<String, dynamic> map) => ProSubscription(
        id: map['id'] as String,
        userId: map['userId'] as String,
        plan: SubscriptionPlan.fromString(map['plan'] as String),
        status: SubscriptionStatus.fromString(map['status'] as String),
        startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
        endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int),
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String? ?? 'RUB',
        paymentMethod: map['paymentMethod'] as String?,
        autoRenew: (map['autoRenew'] as bool?) ?? true,
        trialEndDate: map['trialEndDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['trialEndDate'] as int)
            : null,
        cancelledAt: map['cancelledAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['cancelledAt'] as int)
            : null,
        cancellationReason: map['cancellationReason'] as String?,
        features: Map<String, bool>.from((map['features'] as Map?) ?? {}),
        metadata: Map<String, dynamic>.from((map['metadata'] as Map?) ?? {}),
      );

  /// Уникальный идентификатор
  final String id;

  /// ID пользователя
  final String userId;

  /// План подписки
  final SubscriptionPlan plan;

  /// Статус подписки
  final SubscriptionStatus status;

  /// Дата начала
  final DateTime startDate;

  /// Дата окончания
  final DateTime endDate;

  /// Цена
  final double price;

  /// Валюта
  final String currency;

  /// Способ оплаты
  final String? paymentMethod;

  /// Автопродление
  final bool autoRenew;

  /// Дата окончания пробного периода
  final DateTime? trialEndDate;

  /// Дата отмены
  final DateTime? cancelledAt;

  /// Причина отмены
  final String? cancellationReason;

  /// Доступные функции
  final Map<String, bool> features;

  /// Дополнительные данные
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'plan': plan.value,
        'status': status.value,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'price': price,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'autoRenew': autoRenew,
        'trialEndDate': trialEndDate?.millisecondsSinceEpoch,
        'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
        'cancellationReason': cancellationReason,
        'features': features,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  ProSubscription copyWith({
    String? id,
    String? userId,
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? currency,
    String? paymentMethod,
    bool? autoRenew,
    DateTime? trialEndDate,
    DateTime? cancelledAt,
    String? cancellationReason,
    Map<String, bool>? features,
    Map<String, dynamic>? metadata,
  }) =>
      ProSubscription(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        plan: plan ?? this.plan,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        autoRenew: autoRenew ?? this.autoRenew,
        trialEndDate: trialEndDate ?? this.trialEndDate,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        features: features ?? this.features,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, активна ли подписка
  bool get isActive =>
      status == SubscriptionStatus.active && DateTime.now().isBefore(endDate);

  /// Проверить, истекла ли подписка
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Проверить, в пробном периоде ли подписка
  bool get isTrial =>
      trialEndDate != null && DateTime.now().isBefore(trialEndDate!);

  /// Получить оставшиеся дни
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Проверить доступность функции
  bool hasFeature(String feature) => features[feature] ?? false;
}

/// План подписки
enum SubscriptionPlan {
  basic('basic'),
  pro('pro'),
  premium('premium');

  const SubscriptionPlan(this.value);
  final String value;

  static SubscriptionPlan fromString(String value) {
    switch (value) {
      case 'basic':
        return SubscriptionPlan.basic;
      case 'pro':
        return SubscriptionPlan.pro;
      case 'premium':
        return SubscriptionPlan.premium;
      default:
        return SubscriptionPlan.basic;
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionPlan.basic:
        return 'Базовый';
      case SubscriptionPlan.pro:
        return 'PRO';
      case SubscriptionPlan.premium:
        return 'Премиум';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionPlan.basic:
        return 'Базовые возможности для специалистов';
      case SubscriptionPlan.pro:
        return 'Расширенные возможности и приоритет';
      case SubscriptionPlan.premium:
        return 'Максимальные возможности и эксклюзив';
    }
  }

  double get monthlyPrice {
    switch (this) {
      case SubscriptionPlan.basic:
        return 0;
      case SubscriptionPlan.pro:
        return 999;
      case SubscriptionPlan.premium:
        return 1999;
    }
  }

  double get yearlyPrice {
    switch (this) {
      case SubscriptionPlan.basic:
        return 0;
      case SubscriptionPlan.pro:
        return 9999; // 2 месяца бесплатно
      case SubscriptionPlan.premium:
        return 19999; // 2 месяца бесплатно
    }
  }

  List<String> get features {
    switch (this) {
      case SubscriptionPlan.basic:
        return [
          'Базовый профиль',
          'До 5 портфолио',
          'Стандартная поддержка',
        ];
      case SubscriptionPlan.pro:
        return [
          'Все функции базового плана',
          'Неограниченное портфолио',
          'Приоритет в поиске',
          'Расширенная аналитика',
          'Приоритетная поддержка',
          'Без рекламы',
        ];
      case SubscriptionPlan.premium:
        return [
          'Все функции PRO плана',
          'Эксклюзивные функции',
          'Персональный менеджер',
          'Кастомный дизайн профиля',
          'API доступ',
          'Белый лейбл',
        ];
    }
  }

  String get icon {
    switch (this) {
      case SubscriptionPlan.basic:
        return '🆓';
      case SubscriptionPlan.pro:
        return '⭐';
      case SubscriptionPlan.premium:
        return '👑';
    }
  }
}

/// Статус подписки
enum SubscriptionStatus {
  active('active'),
  cancelled('cancelled'),
  expired('expired'),
  pending('pending'),
  trial('trial');

  const SubscriptionStatus(this.value);
  final String value;

  static SubscriptionStatus fromString(String value) {
    switch (value) {
      case 'active':
        return SubscriptionStatus.active;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'pending':
        return SubscriptionStatus.pending;
      case 'trial':
        return SubscriptionStatus.trial;
      default:
        return SubscriptionStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Активна';
      case SubscriptionStatus.cancelled:
        return 'Отменена';
      case SubscriptionStatus.expired:
        return 'Истекла';
      case SubscriptionStatus.pending:
        return 'Ожидает';
      case SubscriptionStatus.trial:
        return 'Пробный период';
    }
  }

  String get color {
    switch (this) {
      case SubscriptionStatus.active:
        return 'green';
      case SubscriptionStatus.cancelled:
        return 'red';
      case SubscriptionStatus.expired:
        return 'orange';
      case SubscriptionStatus.pending:
        return 'blue';
      case SubscriptionStatus.trial:
        return 'purple';
    }
  }
}

/// Платеж
class Payment {
  const Payment({
    required this.id,
    required this.subscriptionId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.paymentMethod,
    this.transactionId,
    this.receiptUrl,
    this.metadata = const {},
  });

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] as String,
        subscriptionId: map['subscriptionId'] as String,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        status: PaymentStatus.fromString(map['status'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        paymentMethod: map['paymentMethod'] as String?,
        transactionId: map['transactionId'] as String?,
        receiptUrl: map['receiptUrl'] as String?,
        metadata: Map<String, dynamic>.from((map['metadata'] as Map?) ?? {}),
      );

  final String id;
  final String subscriptionId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? paymentMethod;
  final String? transactionId;
  final String? receiptUrl;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'subscriptionId': subscriptionId,
        'amount': amount,
        'currency': currency,
        'status': status.value,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'receiptUrl': receiptUrl,
        'metadata': metadata,
      };
}

/// Статус платежа
enum PaymentStatus {
  pending('pending'),
  completed('completed'),
  failed('failed'),
  refunded('refunded');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.completed:
        return 'Завершен';
      case PaymentStatus.failed:
        return 'Неудачный';
      case PaymentStatus.refunded:
        return 'Возвращен';
    }
  }
}
