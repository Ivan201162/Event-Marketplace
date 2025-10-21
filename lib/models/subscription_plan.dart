import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { free, premium, pro }

// Алиас для совместимости с админ-панелью
typedef SubscriptionPlanType = SubscriptionTier;

enum SubscriptionStatus { active, expired, cancelled, pending }

class SubscriptionPlan {
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.tier,
    required this.price,
    required this.durationDays,
    required this.features,
    required this.isActive,
    this.description,
    this.originalPrice,
    this.discountPercentage,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) => SubscriptionPlan(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    tier: SubscriptionTier.values.firstWhere(
      (e) => e.toString() == 'SubscriptionTier.${map['tier']}',
      orElse: () => SubscriptionTier.free,
    ),
    price: (map['price'] ?? 0.0).toDouble(),
    durationDays: map['durationDays'] ?? 30,
    features: List<String>.from(map['features'] ?? []),
    isActive: map['isActive'] ?? true,
    description: map['description'],
    originalPrice: map['originalPrice']?.toDouble(),
    discountPercentage: map['discountPercentage']?.toDouble(),
    createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
  );

  final String id;
  final String name;
  final SubscriptionTier tier;
  final double price;
  final int durationDays;
  final List<String> features;
  final bool isActive;
  final String? description;
  final double? originalPrice;
  final double? discountPercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Геттер для совместимости с админ-панелью
  SubscriptionTier get type => tier;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'tier': tier.toString().split('.').last,
    'price': price,
    'durationDays': durationDays,
    'features': features,
    'isActive': isActive,
    'description': description,
    'originalPrice': originalPrice,
    'discountPercentage': discountPercentage,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  double get discountAmount => originalPrice != null ? originalPrice! - price : 0.0;

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    SubscriptionTier? tier,
    double? price,
    int? durationDays,
    List<String>? features,
    bool? isActive,
    String? description,
    double? originalPrice,
    double? discountPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SubscriptionPlan(
    id: id ?? this.id,
    name: name ?? this.name,
    tier: tier ?? this.tier,
    price: price ?? this.price,
    durationDays: durationDays ?? this.durationDays,
    features: features ?? this.features,
    isActive: isActive ?? this.isActive,
    description: description ?? this.description,
    originalPrice: originalPrice ?? this.originalPrice,
    discountPercentage: discountPercentage ?? this.discountPercentage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class UserSubscription {
  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.autoRenew,
    this.cancelledAt,
    this.paymentMethod,
    this.transactionId,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSubscription.fromMap(Map<String, dynamic> map) => UserSubscription(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    planId: map['planId'] ?? '',
    startDate: (map['startDate'] as Timestamp).toDate(),
    endDate: (map['endDate'] as Timestamp).toDate(),
    status: SubscriptionStatus.values.firstWhere(
      (e) => e.toString() == 'SubscriptionStatus.${map['status']}',
      orElse: () => SubscriptionStatus.pending,
    ),
    autoRenew: map['autoRenew'] ?? false,
    cancelledAt: map['cancelledAt'] != null ? (map['cancelledAt'] as Timestamp).toDate() : null,
    paymentMethod: map['paymentMethod'],
    transactionId: map['transactionId'],
    createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
  );

  final String id;
  final String userId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final bool autoRenew;
  final DateTime? cancelledAt;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'planId': planId,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status.toString().split('.').last,
    'autoRenew': autoRenew,
    'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    'paymentMethod': paymentMethod,
    'transactionId': transactionId,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  bool get isActive => status == SubscriptionStatus.active && !isExpired;
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon => DateTime.now().add(const Duration(days: 3)).isAfter(endDate);

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  double get progressPercentage {
    final totalDays = endDate.difference(startDate).inDays;
    final remainingDays = endDate.difference(DateTime.now()).inDays;
    return (totalDays - remainingDays) / totalDays;
  }

  UserSubscription copyWith({
    String? id,
    String? userId,
    String? planId,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    bool? autoRenew,
    DateTime? cancelledAt,
    String? paymentMethod,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserSubscription(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    planId: planId ?? this.planId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    status: status ?? this.status,
    autoRenew: autoRenew ?? this.autoRenew,
    cancelledAt: cancelledAt ?? this.cancelledAt,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    transactionId: transactionId ?? this.transactionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
