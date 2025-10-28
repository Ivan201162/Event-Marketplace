import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус подписки
enum SubscriptionStatus { active, inactive, cancelled, expired, pending }

/// Тип подписки
enum SubscriptionType { free, basic, premium, enterprise }

/// Модель подписки пользователя
class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.type,
    required this.status,
    required this.createdAt, this.startDate,
    this.endDate,
    this.autoRenew = false,
    this.price,
    this.currency = 'RUB',
    this.features = const [],
    this.metadata = const {},
    this.updatedAt,
  });

  /// Создать из Map
  factory UserSubscription.fromMap(Map<String, dynamic> data) {
    return UserSubscription(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      startDate: data['startDate'] != null
          ? (data['startDate'] is Timestamp
              ? (data['startDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['startDate'].toString()))
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] is Timestamp
              ? (data['endDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['endDate'].toString()))
          : null,
      autoRenew: data['autoRenew'] as bool? ?? false,
      price: (data['price'] as num?)?.toDouble(),
      currency: data['currency'] as String? ?? 'RUB',
      features: List<String>.from(data['features'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
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
  factory UserSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return UserSubscription.fromMap({'id': doc.id, ...data});
  }

  final String id;
  final String userId;
  final String specialistId;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final double? price;
  final String currency;
  final List<String> features;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'specialistId': specialistId,
        'type': type.name,
        'status': status.name,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'autoRenew': autoRenew,
        'price': price,
        'currency': currency,
        'features': features,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  UserSubscription copyWith({
    String? id,
    String? userId,
    String? specialistId,
    SubscriptionType? type,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenew,
    double? price,
    String? currency,
    List<String>? features,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserSubscription(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        specialistId: specialistId ?? this.specialistId,
        type: type ?? this.type,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        autoRenew: autoRenew ?? this.autoRenew,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        features: features ?? this.features,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг типа из строки
  static SubscriptionType _parseType(String? type) {
    switch (type) {
      case 'free':
        return SubscriptionType.free;
      case 'basic':
        return SubscriptionType.basic;
      case 'premium':
        return SubscriptionType.premium;
      case 'enterprise':
        return SubscriptionType.enterprise;
      default:
        return SubscriptionType.free;
    }
  }

  /// Парсинг статуса из строки
  static SubscriptionStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return SubscriptionStatus.active;
      case 'inactive':
        return SubscriptionStatus.inactive;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'pending':
        return SubscriptionStatus.pending;
      default:
        return SubscriptionStatus.inactive;
    }
  }

  /// Получить отображаемое название типа
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

  /// Получить отображаемое название статуса
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
        return 'Ожидает';
    }
  }

  /// Проверить, активна ли подписка
  bool get isActive {
    return status == SubscriptionStatus.active;
  }

  /// Проверить, истекла ли подписка
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Проверить, скоро ли истекает подписка
  bool get isExpiringSoon {
    if (endDate == null) return false;
    final now = DateTime.now();
    final difference = endDate!.difference(now);
    return difference.inDays <= 7 && difference.inDays > 0;
  }

  /// Получить количество дней до истечения
  int get daysUntilExpiration {
    if (endDate == null) return -1;
    final now = DateTime.now();
    final difference = endDate!.difference(now);
    return difference.inDays;
  }

  /// Получить отформатированную цену
  String get formattedPrice {
    if (price == null) return 'Бесплатно';
    return '${price!.toStringAsFixed(2)} $currency';
  }
}

/// Модель подписки (общая)
class Subscription {
  const Subscription({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.type,
    required this.status,
    required this.createdAt, this.startDate,
    this.endDate,
    this.autoRenew = false,
    this.price,
    this.currency = 'RUB',
    this.features = const [],
    this.metadata = const {},
    this.updatedAt,
  });

  /// Создать из Map
  factory Subscription.fromMap(Map<String, dynamic> data) {
    return Subscription(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      startDate: data['startDate'] != null
          ? (data['startDate'] is Timestamp
              ? (data['startDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['startDate'].toString()))
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] is Timestamp
              ? (data['endDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['endDate'].toString()))
          : null,
      autoRenew: data['autoRenew'] as bool? ?? false,
      price: (data['price'] as num?)?.toDouble(),
      currency: data['currency'] as String? ?? 'RUB',
      features: List<String>.from(data['features'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
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
  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Subscription.fromMap({'id': doc.id, ...data});
  }

  final String id;
  final String userId;
  final String specialistId;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final double? price;
  final String currency;
  final List<String> features;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'specialistId': specialistId,
        'type': type.name,
        'status': status.name,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'autoRenew': autoRenew,
        'price': price,
        'currency': currency,
        'features': features,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  Subscription copyWith({
    String? id,
    String? userId,
    String? specialistId,
    SubscriptionType? type,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenew,
    double? price,
    String? currency,
    List<String>? features,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Subscription(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        specialistId: specialistId ?? this.specialistId,
        type: type ?? this.type,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        autoRenew: autoRenew ?? this.autoRenew,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        features: features ?? this.features,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг типа из строки
  static SubscriptionType _parseType(String? type) {
    switch (type) {
      case 'free':
        return SubscriptionType.free;
      case 'basic':
        return SubscriptionType.basic;
      case 'premium':
        return SubscriptionType.premium;
      case 'enterprise':
        return SubscriptionType.enterprise;
      default:
        return SubscriptionType.free;
    }
  }

  /// Парсинг статуса из строки
  static SubscriptionStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return SubscriptionStatus.active;
      case 'inactive':
        return SubscriptionStatus.inactive;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'pending':
        return SubscriptionStatus.pending;
      default:
        return SubscriptionStatus.inactive;
    }
  }

  /// Получить отображаемое название типа
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

  /// Получить отображаемое название статуса
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
        return 'Ожидает';
    }
  }

  /// Проверить, активна ли подписка
  bool get isActive {
    return status == SubscriptionStatus.active;
  }

  /// Проверить, истекла ли подписка
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Проверить, скоро ли истекает подписка
  bool get isExpiringSoon {
    if (endDate == null) return false;
    final now = DateTime.now();
    final difference = endDate!.difference(now);
    return difference.inDays <= 7 && difference.inDays > 0;
  }

  /// Получить количество дней до истечения
  int get daysUntilExpiration {
    if (endDate == null) return -1;
    final now = DateTime.now();
    final difference = endDate!.difference(now);
    return difference.inDays;
  }

  /// Получить отформатированную цену
  String get formattedPrice {
    if (price == null) return 'Бесплатно';
    return '${price!.toStringAsFixed(2)} $currency';
  }
}
