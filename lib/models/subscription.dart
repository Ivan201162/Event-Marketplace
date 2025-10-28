import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlan { standard, pro, elite }

class Subscription {
  Subscription({
    required this.userId,
    required this.plan,
    required this.startedAt,
    required this.expiresAt,
    required this.autoRenew,
    required this.monthlyPrice, this.isActive = true,
  });

  factory Subscription.fromMap(Map<String, dynamic> map) => Subscription(
        userId: map['userId'] ?? '',
        plan: SubscriptionPlan.values.firstWhere(
          (e) => e.toString() == 'SubscriptionPlan.${map['plan']}',
          orElse: () => SubscriptionPlan.standard,
        ),
        startedAt: (map['startedAt'] as Timestamp).toDate(),
        expiresAt: (map['expiresAt'] as Timestamp).toDate(),
        autoRenew: map['autoRenew'] ?? false,
        isActive: map['isActive'] ?? true,
        monthlyPrice: (map['monthlyPrice'] ?? 0.0).toDouble(),
      );
  final String userId;
  final SubscriptionPlan plan;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool autoRenew;
  final bool isActive;
  final double monthlyPrice;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'plan': plan.toString().split('.').last,
        'startedAt': Timestamp.fromDate(startedAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'autoRenew': autoRenew,
        'isActive': isActive,
        'monthlyPrice': monthlyPrice,
      };

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get daysRemaining => expiresAt.difference(DateTime.now()).inDays;

  Subscription copyWith({
    String? userId,
    SubscriptionPlan? plan,
    DateTime? startedAt,
    DateTime? expiresAt,
    bool? autoRenew,
    bool? isActive,
    double? monthlyPrice,
  }) =>
      Subscription(
        userId: userId ?? this.userId,
        plan: plan ?? this.plan,
        startedAt: startedAt ?? this.startedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        autoRenew: autoRenew ?? this.autoRenew,
        isActive: isActive ?? this.isActive,
        monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      );
}
