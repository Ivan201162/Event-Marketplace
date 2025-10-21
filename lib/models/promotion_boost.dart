import 'package:cloud_firestore/cloud_firestore.dart';

enum PromotionType { profileBoost, postBoost, categoryBoost, searchBoost }

enum PromotionStatus { active, expired, cancelled, pending, paused }

enum PromotionPriority { low, medium, high, premium }

class PromotionBoost {
  PromotionBoost({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.priorityLevel,
    required this.price,
    this.targetId, // postId, categoryId, etc.
    this.region,
    this.city,
    this.category,
    this.impressions = 0,
    this.clicks = 0,
    this.ctr = 0.0,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory PromotionBoost.fromMap(Map<String, dynamic> map) => PromotionBoost(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    type: PromotionType.values.firstWhere(
      (e) => e.toString() == 'PromotionType.${map['type']}',
      orElse: () => PromotionType.profileBoost,
    ),
    startDate: (map['startDate'] as Timestamp).toDate(),
    endDate: (map['endDate'] as Timestamp).toDate(),
    status: PromotionStatus.values.firstWhere(
      (e) => e.toString() == 'PromotionStatus.${map['status']}',
      orElse: () => PromotionStatus.pending,
    ),
    priorityLevel: PromotionPriority.values.firstWhere(
      (e) => e.toString() == 'PromotionPriority.${map['priorityLevel']}',
      orElse: () => PromotionPriority.medium,
    ),
    price: (map['price'] ?? 0.0).toDouble(),
    targetId: map['targetId'],
    region: map['region'],
    city: map['city'],
    category: map['category'],
    impressions: map['impressions'] ?? 0,
    clicks: map['clicks'] ?? 0,
    ctr: (map['ctr'] ?? 0.0).toDouble(),
    createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    metadata: map['metadata'],
  );

  final String id;
  final String userId;
  final PromotionType type;
  final DateTime startDate;
  final DateTime endDate;
  final PromotionStatus status;
  final PromotionPriority priorityLevel;
  final double price;
  final String? targetId;
  final String? region;
  final String? city;
  final String? category;
  final int impressions;
  final int clicks;
  final double ctr;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type.toString().split('.').last,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status.toString().split('.').last,
    'priorityLevel': priorityLevel.toString().split('.').last,
    'price': price,
    'targetId': targetId,
    'region': region,
    'city': city,
    'category': category,
    'impressions': impressions,
    'clicks': clicks,
    'ctr': ctr,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'metadata': metadata,
  };

  bool get isActive => status == PromotionStatus.active && !isExpired;
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon => DateTime.now().add(const Duration(days: 1)).isAfter(endDate);

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  double get progressPercentage {
    final totalDays = endDate.difference(startDate).inDays;
    final remainingDays = endDate.difference(DateTime.now()).inDays;
    return (totalDays - remainingDays) / totalDays;
  }

  // Вычисляем эффективность продвижения
  double get effectiveness {
    if (impressions == 0) return 0.0;
    return (clicks / impressions) * 100;
  }

  PromotionBoost copyWith({
    String? id,
    String? userId,
    PromotionType? type,
    DateTime? startDate,
    DateTime? endDate,
    PromotionStatus? status,
    PromotionPriority? priorityLevel,
    double? price,
    String? targetId,
    String? region,
    String? city,
    String? category,
    int? impressions,
    int? clicks,
    double? ctr,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) => PromotionBoost(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    status: status ?? this.status,
    priorityLevel: priorityLevel ?? this.priorityLevel,
    price: price ?? this.price,
    targetId: targetId ?? this.targetId,
    region: region ?? this.region,
    city: city ?? this.city,
    category: category ?? this.category,
    impressions: impressions ?? this.impressions,
    clicks: clicks ?? this.clicks,
    ctr: ctr ?? this.ctr,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    metadata: metadata ?? this.metadata,
  );
}

class PromotionPackage {
  PromotionPackage({
    required this.id,
    required this.name,
    required this.type,
    required this.durationDays,
    required this.price,
    required this.priorityLevel,
    required this.isActive,
    this.description,
    this.features,
    this.originalPrice,
    this.discountPercentage,
    this.createdAt,
    this.updatedAt,
  });

  factory PromotionPackage.fromMap(Map<String, dynamic> map) => PromotionPackage(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    type: PromotionType.values.firstWhere(
      (e) => e.toString() == 'PromotionType.${map['type']}',
      orElse: () => PromotionType.profileBoost,
    ),
    durationDays: map['durationDays'] ?? 7,
    price: (map['price'] ?? 0.0).toDouble(),
    priorityLevel: PromotionPriority.values.firstWhere(
      (e) => e.toString() == 'PromotionPriority.${map['priorityLevel']}',
      orElse: () => PromotionPriority.medium,
    ),
    isActive: map['isActive'] ?? true,
    description: map['description'],
    features: List<String>.from(map['features'] ?? []),
    originalPrice: map['originalPrice']?.toDouble(),
    discountPercentage: map['discountPercentage']?.toDouble(),
    createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
  );

  final String id;
  final String name;
  final PromotionType type;
  final int durationDays;
  final double price;
  final PromotionPriority priorityLevel;
  final bool isActive;
  final String? description;
  final List<String>? features;
  final double? originalPrice;
  final double? discountPercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.toString().split('.').last,
    'durationDays': durationDays,
    'price': price,
    'priorityLevel': priorityLevel.toString().split('.').last,
    'isActive': isActive,
    'description': description,
    'features': features,
    'originalPrice': originalPrice,
    'discountPercentage': discountPercentage,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  double get discountAmount => originalPrice != null ? originalPrice! - price : 0.0;

  PromotionPackage copyWith({
    String? id,
    String? name,
    PromotionType? type,
    int? durationDays,
    double? price,
    PromotionPriority? priorityLevel,
    bool? isActive,
    String? description,
    List<String>? features,
    double? originalPrice,
    double? discountPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PromotionPackage(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    durationDays: durationDays ?? this.durationDays,
    price: price ?? this.price,
    priorityLevel: priorityLevel ?? this.priorityLevel,
    isActive: isActive ?? this.isActive,
    description: description ?? this.description,
    features: features ?? this.features,
    originalPrice: originalPrice ?? this.originalPrice,
    discountPercentage: discountPercentage ?? this.discountPercentage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
