import 'package:cloud_firestore/cloud_firestore.dart';

enum AdType {
  banner,
  inline,
  profileBoost,
  sponsoredPost,
  categoryAd,
  searchAd
}

// Алиасы для совместимости с админ-панелью
typedef AdvertisementType = AdType;
typedef AdvertisementStatus = AdStatus;

enum AdStatus { active, paused, expired, rejected, pending, draft }

enum AdPlacement {
  topBanner,
  bottomBanner,
  betweenPosts,
  profileHeader,
  searchResults,
  categoryList,
  homeFeed,
}

class Advertisement {
  Advertisement({
    required this.id,
    required this.userId,
    required this.type,
    required this.placement,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.price,
    this.title,
    this.description,
    this.contentUrl,
    this.imageUrl,
    this.videoUrl,
    this.targetUrl,
    this.region,
    this.city,
    this.category,
    this.targetAudience,
    this.budget,
    this.spentAmount = 0.0,
    this.impressions = 0,
    this.clicks = 0,
    this.ctr = 0.0,
    this.cpc = 0.0,
    this.cpm = 0.0,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory Advertisement.fromMap(Map<String, dynamic> map) => Advertisement(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        type: AdType.values.firstWhere(
          (e) => e.toString() == 'AdType.${map['type']}',
          orElse: () => AdType.banner,
        ),
        placement: AdPlacement.values.firstWhere(
          (e) => e.toString() == 'AdPlacement.${map['placement']}',
          orElse: () => AdPlacement.topBanner,
        ),
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        status: AdStatus.values.firstWhere(
          (e) => e.toString() == 'AdStatus.${map['status']}',
          orElse: () => AdStatus.pending,
        ),
        price: (map['price'] ?? 0.0).toDouble(),
        title: map['title'],
        description: map['description'],
        contentUrl: map['contentUrl'],
        imageUrl: map['imageUrl'],
        videoUrl: map['videoUrl'],
        targetUrl: map['targetUrl'],
        region: map['region'],
        city: map['city'],
        category: map['category'],
        targetAudience: map['targetAudience'],
        budget: map['budget']?.toDouble(),
        spentAmount: (map['spentAmount'] ?? 0.0).toDouble(),
        impressions: map['impressions'] ?? 0,
        clicks: map['clicks'] ?? 0,
        ctr: (map['ctr'] ?? 0.0).toDouble(),
        cpc: (map['cpc'] ?? 0.0).toDouble(),
        cpm: (map['cpm'] ?? 0.0).toDouble(),
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        metadata: map['metadata'],
      );

  final String id;
  final String userId;
  final AdType type;
  final AdPlacement placement;
  final DateTime startDate;
  final DateTime endDate;
  final AdStatus status;
  final double price;
  final String? title;
  final String? description;
  final String? contentUrl;
  final String? imageUrl;
  final String? videoUrl;
  final String? targetUrl;
  final String? region;
  final String? city;
  final String? category;
  final String? targetAudience;
  final double? budget;
  final double spentAmount;
  final int impressions;
  final int clicks;
  final double ctr;
  final double cpc;
  final double cpm;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.toString().split('.').last,
        'placement': placement.toString().split('.').last,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': status.toString().split('.').last,
        'price': price,
        'title': title,
        'description': description,
        'contentUrl': contentUrl,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'targetUrl': targetUrl,
        'region': region,
        'city': city,
        'category': category,
        'targetAudience': targetAudience,
        'budget': budget,
        'spentAmount': spentAmount,
        'impressions': impressions,
        'clicks': clicks,
        'ctr': ctr,
        'cpc': cpc,
        'cpm': cpm,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'metadata': metadata,
      };

  bool get isActive => status == AdStatus.active && !isExpired;
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon =>
      DateTime.now().add(const Duration(days: 1)).isAfter(endDate);

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  double get progressPercentage {
    final totalDays = endDate.difference(startDate).inDays;
    final remainingDays = endDate.difference(DateTime.now()).inDays;
    return (totalDays - remainingDays) / totalDays;
  }

  // Вычисляем эффективность рекламы
  double get effectiveness {
    if (impressions == 0) return 0.0;
    return (clicks / impressions) * 100;
  }

  // Проверяем, превышен ли бюджет
  bool get isBudgetExceeded {
    if (budget == null) return false;
    return spentAmount >= budget!;
  }

  // Остаток бюджета
  double get remainingBudget {
    if (budget == null) return 0.0;
    return budget! - spentAmount;
  }

  Advertisement copyWith({
    String? id,
    String? userId,
    AdType? type,
    AdPlacement? placement,
    DateTime? startDate,
    DateTime? endDate,
    AdStatus? status,
    double? price,
    String? title,
    String? description,
    String? contentUrl,
    String? imageUrl,
    String? videoUrl,
    String? targetUrl,
    String? region,
    String? city,
    String? category,
    String? targetAudience,
    double? budget,
    double? spentAmount,
    int? impressions,
    int? clicks,
    double? ctr,
    double? cpc,
    double? cpm,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      Advertisement(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        placement: placement ?? this.placement,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        price: price ?? this.price,
        title: title ?? this.title,
        description: description ?? this.description,
        contentUrl: contentUrl ?? this.contentUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        targetUrl: targetUrl ?? this.targetUrl,
        region: region ?? this.region,
        city: city ?? this.city,
        category: category ?? this.category,
        targetAudience: targetAudience ?? this.targetAudience,
        budget: budget ?? this.budget,
        spentAmount: spentAmount ?? this.spentAmount,
        impressions: impressions ?? this.impressions,
        clicks: clicks ?? this.clicks,
        ctr: ctr ?? this.ctr,
        cpc: cpc ?? this.cpc,
        cpm: cpm ?? this.cpm,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );
}

class AdCampaign {
  AdCampaign({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.isActive,
    this.description,
    this.targetAudience,
    this.region,
    this.city,
    this.category,
    this.spentAmount = 0.0,
    this.impressions = 0,
    this.clicks = 0,
    this.ctr = 0.0,
    this.createdAt,
    this.updatedAt,
    this.ads = const [],
  });

  factory AdCampaign.fromMap(Map<String, dynamic> map) => AdCampaign(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        budget: (map['budget'] ?? 0.0).toDouble(),
        isActive: map['isActive'] ?? true,
        description: map['description'],
        targetAudience: map['targetAudience'],
        region: map['region'],
        city: map['city'],
        category: map['category'],
        spentAmount: (map['spentAmount'] ?? 0.0).toDouble(),
        impressions: map['impressions'] ?? 0,
        clicks: map['clicks'] ?? 0,
        ctr: (map['ctr'] ?? 0.0).toDouble(),
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        ads: (map['ads'] as List<dynamic>?)
                ?.map((ad) => Advertisement.fromMap(ad))
                .toList() ??
            [],
      );

  final String id;
  final String userId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final bool isActive;
  final String? description;
  final String? targetAudience;
  final String? region;
  final String? city;
  final String? category;
  final double spentAmount;
  final int impressions;
  final int clicks;
  final double ctr;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Advertisement> ads;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'budget': budget,
        'isActive': isActive,
        'description': description,
        'targetAudience': targetAudience,
        'region': region,
        'city': city,
        'category': category,
        'spentAmount': spentAmount,
        'impressions': impressions,
        'clicks': clicks,
        'ctr': ctr,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'ads': ads.map((ad) => ad.toMap()).toList(),
      };

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon =>
      DateTime.now().add(const Duration(days: 3)).isAfter(endDate);

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  double get remainingBudget => budget - spentAmount;

  bool get isBudgetExceeded => spentAmount >= budget;

  AdCampaign copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    bool? isActive,
    String? description,
    String? targetAudience,
    String? region,
    String? city,
    String? category,
    double? spentAmount,
    int? impressions,
    int? clicks,
    double? ctr,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Advertisement>? ads,
  }) =>
      AdCampaign(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        budget: budget ?? this.budget,
        isActive: isActive ?? this.isActive,
        description: description ?? this.description,
        targetAudience: targetAudience ?? this.targetAudience,
        region: region ?? this.region,
        city: city ?? this.city,
        category: category ?? this.category,
        spentAmount: spentAmount ?? this.spentAmount,
        impressions: impressions ?? this.impressions,
        clicks: clicks ?? this.clicks,
        ctr: ctr ?? this.ctr,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        ads: ads ?? this.ads,
      );
}
