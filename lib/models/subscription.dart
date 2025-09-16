import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип подписки
enum SubscriptionType {
  free,
  basic,
  premium,
  enterprise,
}

/// Статус подписки
enum SubscriptionStatus {
  active,
  inactive,
  cancelled,
  expired,
  pending,
}

/// Период подписки
enum SubscriptionPeriod {
  monthly,
  quarterly,
  yearly,
  lifetime,
}

/// Модель подписки
class Subscription {
  final String id;
  final String userId;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final SubscriptionPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String currency;
  final String? paymentId;
  final String? paymentMethod;
  final Map<String, dynamic> features; // Доступные функции
  final Map<String, dynamic> limits; // Лимиты использования
  final bool autoRenew;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Subscription({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.currency,
    this.paymentId,
    this.paymentMethod,
    required this.features,
    required this.limits,
    this.autoRenew = true,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Создать подписку из документа Firestore
  factory Subscription.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Subscription(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SubscriptionType.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SubscriptionStatus.inactive,
      ),
      period: SubscriptionPeriod.values.firstWhere(
        (e) => e.name == data['period'],
        orElse: () => SubscriptionPeriod.monthly,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      paymentId: data['paymentId'],
      paymentMethod: data['paymentMethod'],
      features: Map<String, dynamic>.from(data['features'] ?? {}),
      limits: Map<String, dynamic>.from(data['limits'] ?? {}),
      autoRenew: data['autoRenew'] ?? true,
      cancelledAt: data['cancelledAt'] != null 
          ? (data['cancelledAt'] as Timestamp).toDate() 
          : null,
      cancellationReason: data['cancellationReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'period': period.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'currency': currency,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'features': features,
      'limits': limits,
      'autoRenew': autoRenew,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Создать копию с изменениями
  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionType? type,
    SubscriptionStatus? status,
    SubscriptionPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? currency,
    String? paymentId,
    String? paymentMethod,
    Map<String, dynamic>? features,
    Map<String, dynamic>? limits,
    bool? autoRenew,
    DateTime? cancelledAt,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      features: features ?? this.features,
      limits: limits ?? this.limits,
      autoRenew: autoRenew ?? this.autoRenew,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Проверить, активна ли подписка
  bool get isActive => status == SubscriptionStatus.active && endDate.isAfter(DateTime.now());

  /// Проверить, истекает ли подписка скоро
  bool get isExpiringSoon {
    final daysUntilExpiry = endDate.difference(DateTime.now()).inDays;
    return isActive && daysUntilExpiry <= 7;
  }

  /// Проверить, истекла ли подписка
  bool get isExpired => endDate.isBefore(DateTime.now());

  /// Получить количество дней до истечения
  int get daysUntilExpiry {
    final difference = endDate.difference(DateTime.now()).inDays;
    return difference > 0 ? difference : 0;
  }

  /// Проверить, есть ли доступ к функции
  bool hasFeature(String feature) {
    return features[feature] == true;
  }

  /// Получить лимит для функции
  int getLimit(String limit) {
    return limits[limit] ?? 0;
  }

  /// Проверить, превышен ли лимит
  bool isLimitExceeded(String limit, int currentUsage) {
    final limitValue = getLimit(limit);
    return limitValue > 0 && currentUsage >= limitValue;
  }

  /// Получить название типа подписки
  String get typeDisplayName {
    switch (type) {
      case SubscriptionType.free:
        return 'Бесплатная';
      case SubscriptionType.basic:
        return 'Базовая';
      case SubscriptionType.premium:
        return 'Премиум';
      case SubscriptionType.enterprise:
        return 'Корпоративная';
    }
  }

  /// Получить описание типа подписки
  String get typeDescription {
    switch (type) {
      case SubscriptionType.free:
        return 'Базовые возможности для начала работы';
      case SubscriptionType.basic:
        return 'Расширенные функции для активных пользователей';
      case SubscriptionType.premium:
        return 'Полный доступ ко всем возможностям';
      case SubscriptionType.enterprise:
        return 'Корпоративные решения с приоритетной поддержкой';
    }
  }

  /// Получить название периода
  String get periodDisplayName {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return 'Месячная';
      case SubscriptionPeriod.quarterly:
        return 'Квартальная';
      case SubscriptionPeriod.yearly:
        return 'Годовая';
      case SubscriptionPeriod.lifetime:
        return 'Пожизненная';
    }
  }

  /// Получить название статуса
  String get statusDisplayName {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Активна';
      case SubscriptionStatus.inactive:
        return 'Неактивна';
      case SubscriptionStatus.cancelled:
        return 'Отменена';
      case SubscriptionStatus.expired:
        return 'Истекла';
      case SubscriptionStatus.pending:
        return 'Ожидает активации';
    }
  }

  /// Получить цвет статуса
  String get statusColor {
    switch (status) {
      case SubscriptionStatus.active:
        return 'green';
      case SubscriptionStatus.inactive:
        return 'grey';
      case SubscriptionStatus.cancelled:
        return 'red';
      case SubscriptionStatus.expired:
        return 'orange';
      case SubscriptionStatus.pending:
        return 'blue';
    }
  }

  /// Получить отформатированную цену
  String get formattedPrice {
    if (price == 0) return 'Бесплатно';
    return '${price.toStringAsFixed(2)} $currency';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Subscription(id: $id, type: $type, status: $status, period: $period)';
  }
}

/// План подписки
class SubscriptionPlan {
  final SubscriptionType type;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final String currency;
  final List<String> features;
  final Map<String, int> limits;
  final bool isPopular;
  final String? badge;

  const SubscriptionPlan({
    required this.type,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.currency,
    required this.features,
    required this.limits,
    this.isPopular = false,
    this.badge,
  });

  /// Получить цену для периода
  double getPriceForPeriod(SubscriptionPeriod period) {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return monthlyPrice;
      case SubscriptionPeriod.quarterly:
        return monthlyPrice * 3 * 0.9; // 10% скидка
      case SubscriptionPeriod.yearly:
        return yearlyPrice;
      case SubscriptionPeriod.lifetime:
        return yearlyPrice * 5; // 5 лет
    }
  }

  /// Получить экономию для периода
  double getSavingsForPeriod(SubscriptionPeriod period) {
    final monthlyTotal = monthlyPrice * _getMonthsInPeriod(period);
    final periodPrice = getPriceForPeriod(period);
    return monthlyTotal - periodPrice;
  }

  /// Получить процент экономии
  double getSavingsPercentage(SubscriptionPeriod period) {
    final monthlyTotal = monthlyPrice * _getMonthsInPeriod(period);
    final periodPrice = getPriceForPeriod(period);
    return ((monthlyTotal - periodPrice) / monthlyTotal) * 100;
  }

  int _getMonthsInPeriod(SubscriptionPeriod period) {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return 1;
      case SubscriptionPeriod.quarterly:
        return 3;
      case SubscriptionPeriod.yearly:
        return 12;
      case SubscriptionPeriod.lifetime:
        return 60; // 5 лет
    }
  }

  /// Проверить, есть ли функция
  bool hasFeature(String feature) {
    return features.contains(feature);
  }

  /// Получить лимит
  int getLimit(String limit) {
    return limits[limit] ?? 0;
  }

  @override
  String toString() {
    return 'SubscriptionPlan(type: $type, name: $name, monthlyPrice: $monthlyPrice)';
  }
}

/// Предопределенные планы подписки
class SubscriptionPlans {
  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      type: SubscriptionType.free,
      name: 'Бесплатная',
      description: 'Идеально для начала работы',
      monthlyPrice: 0,
      yearlyPrice: 0,
      currency: 'USD',
      features: [
        'До 5 событий в месяц',
        'Базовые уведомления',
        'Стандартная поддержка',
        'Ограниченная аналитика',
      ],
      limits: {
        'events_per_month': 5,
        'notifications_per_day': 10,
        'storage_mb': 100,
        'team_members': 1,
      },
    ),
    SubscriptionPlan(
      type: SubscriptionType.basic,
      name: 'Базовая',
      description: 'Для активных организаторов',
      monthlyPrice: 9.99,
      yearlyPrice: 99.99,
      currency: 'USD',
      features: [
        'До 50 событий в месяц',
        'Расширенные уведомления',
        'Приоритетная поддержка',
        'Детальная аналитика',
        'Кастомные брендинг',
        'Экспорт данных',
      ],
      limits: {
        'events_per_month': 50,
        'notifications_per_day': 100,
        'storage_mb': 1000,
        'team_members': 3,
      ],
    ),
    SubscriptionPlan(
      type: SubscriptionType.premium,
      name: 'Премиум',
      description: 'Полный доступ ко всем функциям',
      monthlyPrice: 19.99,
      yearlyPrice: 199.99,
      currency: 'USD',
      features: [
        'Неограниченные события',
        'Все типы уведомлений',
        'VIP поддержка 24/7',
        'Продвинутая аналитика',
        'Полный кастомный брендинг',
        'API доступ',
        'Интеграции с внешними сервисами',
        'Автоматизация процессов',
      ],
      limits: {
        'events_per_month': -1, // Неограниченно
        'notifications_per_day': -1,
        'storage_mb': 10000,
        'team_members': 10,
      },
      isPopular: true,
      badge: 'Популярно',
    ),
    SubscriptionPlan(
      type: SubscriptionType.enterprise,
      name: 'Корпоративная',
      description: 'Решения для крупных организаций',
      monthlyPrice: 49.99,
      yearlyPrice: 499.99,
      currency: 'USD',
      features: [
        'Все функции Премиум',
        'Персональный менеджер',
        'Кастомные интеграции',
        'SLA гарантии',
        'Обучение команды',
        'Приоритетные обновления',
        'Белый лейбл',
        'Мультитенантность',
      ],
      limits: {
        'events_per_month': -1,
        'notifications_per_day': -1,
        'storage_mb': -1,
        'team_members': -1,
      },
    ),
  ];

  /// Получить план по типу
  static SubscriptionPlan? getPlanByType(SubscriptionType type) {
    try {
      return plans.firstWhere((plan) => plan.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Получить все планы кроме бесплатного
  static List<SubscriptionPlan> getPaidPlans() {
    return plans.where((plan) => plan.type != SubscriptionType.free).toList();
  }

  /// Получить рекомендуемый план
  static SubscriptionPlan getRecommendedPlan() {
    return plans.firstWhere((plan) => plan.isPopular);
  }
}
