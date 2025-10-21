import 'package:cloud_firestore/cloud_firestore.dart';

enum AdTargetingType { interest, behavior, location, demographic, device, time, custom }

enum AdPlacement {
  homeFeed,
  searchResults,
  categoryList,
  profileView,
  eventDetail,
  chatScreen,
  settingsScreen,
}

enum AdRelevanceScore { low, medium, high, veryHigh }

class AdTargeting {
  AdTargeting({
    required this.id,
    required this.adId,
    required this.type,
    required this.criteria,
    required this.weight,
    this.isActive = true,
  });

  factory AdTargeting.fromMap(Map<String, dynamic> map) => AdTargeting(
    id: map['id'] ?? '',
    adId: map['adId'] ?? '',
    type: AdTargetingType.values.firstWhere(
      (e) => e.toString() == 'AdTargetingType.${map['type']}',
      orElse: () => AdTargetingType.interest,
    ),
    criteria: Map<String, dynamic>.from(map['criteria'] ?? {}),
    weight: (map['weight'] ?? 1.0).toDouble(),
    isActive: map['isActive'] ?? true,
  );

  final String id;
  final String adId;
  final AdTargetingType type;
  final Map<String, dynamic> criteria;
  final double weight;
  final bool isActive;

  Map<String, dynamic> toMap() => {
    'id': id,
    'adId': adId,
    'type': type.toString().split('.').last,
    'criteria': criteria,
    'weight': weight,
    'isActive': isActive,
  };
}

class SmartAdvertisement {
  SmartAdvertisement({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    required this.budget,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.targetUrl,
    this.region,
    this.category,
    this.targetAudience,
    this.placements = const [],
    this.targeting = const [],
    this.impressions = 0,
    this.clicks = 0,
    this.conversions = 0,
    this.spentAmount = 0.0,
    this.ctr = 0.0,
    this.cpc = 0.0,
    this.cpm = 0.0,
    this.relevanceScore = AdRelevanceScore.medium,
    this.qualityScore = 0.0,
    this.bidAmount = 0.0,
    this.maxBid = 0.0,
    this.dailyBudget = 0.0,
    this.isAutoOptimized = false,
    this.optimizationSettings,
    this.metadata,
  });

  factory SmartAdvertisement.fromMap(Map<String, dynamic> map) => SmartAdvertisement(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    title: map['title'] ?? '',
    content: map['content'] ?? '',
    type: map['type'] ?? 'banner',
    budget: (map['budget'] ?? 0.0).toDouble(),
    startDate: (map['startDate'] as Timestamp).toDate(),
    endDate: (map['endDate'] as Timestamp).toDate(),
    status: map['status'] ?? 'pending',
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    description: map['description'],
    imageUrl: map['imageUrl'],
    videoUrl: map['videoUrl'],
    targetUrl: map['targetUrl'],
    region: map['region'],
    category: map['category'],
    targetAudience: Map<String, dynamic>.from(map['targetAudience'] ?? {}),
    placements: List<String>.from(map['placements'] ?? []),
    targeting:
        (map['targeting'] as List<dynamic>?)
            ?.map((t) => AdTargeting.fromMap(t as Map<String, dynamic>))
            .toList() ??
        [],
    impressions: map['impressions'] ?? 0,
    clicks: map['clicks'] ?? 0,
    conversions: map['conversions'] ?? 0,
    spentAmount: (map['spentAmount'] ?? 0.0).toDouble(),
    ctr: (map['ctr'] ?? 0.0).toDouble(),
    cpc: (map['cpc'] ?? 0.0).toDouble(),
    cpm: (map['cpm'] ?? 0.0).toDouble(),
    relevanceScore: AdRelevanceScore.values.firstWhere(
      (e) => e.toString() == 'AdRelevanceScore.${map['relevanceScore']}',
      orElse: () => AdRelevanceScore.medium,
    ),
    qualityScore: (map['qualityScore'] ?? 0.0).toDouble(),
    bidAmount: (map['bidAmount'] ?? 0.0).toDouble(),
    maxBid: (map['maxBid'] ?? 0.0).toDouble(),
    dailyBudget: (map['dailyBudget'] ?? 0.0).toDouble(),
    isAutoOptimized: map['isAutoOptimized'] ?? false,
    optimizationSettings: Map<String, dynamic>.from(map['optimizationSettings'] ?? {}),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String userId;
  final String title;
  final String content;
  final String type;
  final double budget;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final String? targetUrl;
  final String? region;
  final String? category;
  final Map<String, dynamic>? targetAudience;
  final List<String> placements;
  final List<AdTargeting> targeting;
  final int impressions;
  final int clicks;
  final int conversions;
  final double spentAmount;
  final double ctr;
  final double cpc;
  final double cpm;
  final AdRelevanceScore relevanceScore;
  final double qualityScore;
  final double bidAmount;
  final double maxBid;
  final double dailyBudget;
  final bool isAutoOptimized;
  final Map<String, dynamic>? optimizationSettings;
  final Map<String, dynamic>? metadata;

  bool get isActive => status == 'active' && DateTime.now().isBetween(startDate, endDate);
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isPending => status == 'pending';
  bool get isPaused => status == 'paused';

  /// Расчет релевантности для пользователя
  double calculateRelevanceForUser({
    required String userId,
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> userBehavior,
  }) {
    double relevance = 0.0;
    double totalWeight = 0.0;

    for (final target in targeting) {
      if (!target.isActive) continue;

      final double matchScore = _calculateMatchScore(
        target: target,
        userProfile: userProfile,
        userBehavior: userBehavior,
      );

      relevance += matchScore * target.weight;
      totalWeight += target.weight;
    }

    return totalWeight > 0 ? relevance / totalWeight : 0.0;
  }

  /// Расчет соответствия таргетингу
  double _calculateMatchScore({
    required AdTargeting target,
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> userBehavior,
  }) {
    switch (target.type) {
      case AdTargetingType.interest:
        return _calculateInterestMatch(target.criteria, userProfile);
      case AdTargetingType.behavior:
        return _calculateBehaviorMatch(target.criteria, userBehavior);
      case AdTargetingType.location:
        return _calculateLocationMatch(target.criteria, userProfile);
      case AdTargetingType.demographic:
        return _calculateDemographicMatch(target.criteria, userProfile);
      case AdTargetingType.device:
        return _calculateDeviceMatch(target.criteria, userProfile);
      case AdTargetingType.time:
        return _calculateTimeMatch(target.criteria);
      case AdTargetingType.custom:
        return _calculateCustomMatch(target.criteria, userProfile, userBehavior);
    }
  }

  double _calculateInterestMatch(Map<String, dynamic> criteria, Map<String, dynamic> userProfile) {
    final List<String> adInterests = List<String>.from(criteria['interests'] ?? []);
    final List<String> userInterests = List<String>.from(userProfile['interests'] ?? []);

    if (adInterests.isEmpty || userInterests.isEmpty) return 0.0;

    final int matches = adInterests.where((interest) => userInterests.contains(interest)).length;
    return matches / adInterests.length;
  }

  double _calculateBehaviorMatch(Map<String, dynamic> criteria, Map<String, dynamic> userBehavior) {
    final List<String> adBehaviors = List<String>.from(criteria['behaviors'] ?? []);
    final List<String> userBehaviors = List<String>.from(userBehavior['recent_actions'] ?? []);

    if (adBehaviors.isEmpty || userBehaviors.isEmpty) return 0.0;

    final int matches = adBehaviors.where((behavior) => userBehaviors.contains(behavior)).length;
    return matches / adBehaviors.length;
  }

  double _calculateLocationMatch(Map<String, dynamic> criteria, Map<String, dynamic> userProfile) {
    final String adRegion = criteria['region'] ?? '';
    final String userRegion = userProfile['region'] ?? '';

    if (adRegion.isEmpty || userRegion.isEmpty) return 0.0;

    return adRegion.toLowerCase() == userRegion.toLowerCase() ? 1.0 : 0.0;
  }

  double _calculateDemographicMatch(
    Map<String, dynamic> criteria,
    Map<String, dynamic> userProfile,
  ) {
    double score = 0.0;
    int factors = 0;

    if (criteria['age_min'] != null && criteria['age_max'] != null) {
      final int userAge = userProfile['age'] ?? 0;
      final int minAge = criteria['age_min'];
      final int maxAge = criteria['age_max'];

      if (userAge >= minAge && userAge <= maxAge) {
        score += 1.0;
      }
      factors++;
    }

    if (criteria['gender'] != null) {
      final String adGender = criteria['gender'];
      final String userGender = userProfile['gender'] ?? '';

      if (adGender.toLowerCase() == userGender.toLowerCase()) {
        score += 1.0;
      }
      factors++;
    }

    return factors > 0 ? score / factors : 0.0;
  }

  double _calculateDeviceMatch(Map<String, dynamic> criteria, Map<String, dynamic> userProfile) {
    final String adDevice = criteria['device'] ?? '';
    final String userDevice = userProfile['device_type'] ?? '';

    if (adDevice.isEmpty || userDevice.isEmpty) return 0.0;

    return adDevice.toLowerCase() == userDevice.toLowerCase() ? 1.0 : 0.0;
  }

  double _calculateTimeMatch(Map<String, dynamic> criteria) {
    final DateTime now = DateTime.now();
    final int currentHour = now.hour;
    final int currentDay = now.weekday;

    final List<int> targetHours = List<int>.from(criteria['hours'] ?? []);
    final List<int> targetDays = List<int>.from(criteria['days'] ?? []);

    double score = 0.0;
    int factors = 0;

    if (targetHours.isNotEmpty) {
      if (targetHours.contains(currentHour)) {
        score += 1.0;
      }
      factors++;
    }

    if (targetDays.isNotEmpty) {
      if (targetDays.contains(currentDay)) {
        score += 1.0;
      }
      factors++;
    }

    return factors > 0 ? score / factors : 1.0;
  }

  double _calculateCustomMatch(
    Map<String, dynamic> criteria,
    Map<String, dynamic> userProfile,
    Map<String, dynamic> userBehavior,
  ) {
    // Кастомная логика для специфических случаев
    return 0.5; // Базовое значение
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'content': content,
    'type': type,
    'budget': budget,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'description': description,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'targetUrl': targetUrl,
    'region': region,
    'category': category,
    'targetAudience': targetAudience,
    'placements': placements,
    'targeting': targeting.map((t) => t.toMap()).toList(),
    'impressions': impressions,
    'clicks': clicks,
    'conversions': conversions,
    'spentAmount': spentAmount,
    'ctr': ctr,
    'cpc': cpc,
    'cpm': cpm,
    'relevanceScore': relevanceScore.toString().split('.').last,
    'qualityScore': qualityScore,
    'bidAmount': bidAmount,
    'maxBid': maxBid,
    'dailyBudget': dailyBudget,
    'isAutoOptimized': isAutoOptimized,
    'optimizationSettings': optimizationSettings,
    'metadata': metadata,
  };
}

class AdImpression {
  AdImpression({
    required this.id,
    required this.adId,
    required this.userId,
    required this.placement,
    required this.timestamp,
    this.isClicked = false,
    this.isConverted = false,
    this.relevanceScore = 0.0,
    this.userContext,
  });

  factory AdImpression.fromMap(Map<String, dynamic> map) => AdImpression(
    id: map['id'] ?? '',
    adId: map['adId'] ?? '',
    userId: map['userId'] ?? '',
    placement: map['placement'] ?? '',
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    isClicked: map['isClicked'] ?? false,
    isConverted: map['isConverted'] ?? false,
    relevanceScore: (map['relevanceScore'] ?? 0.0).toDouble(),
    userContext: Map<String, dynamic>.from(map['userContext'] ?? {}),
  );

  final String id;
  final String adId;
  final String userId;
  final String placement;
  final DateTime timestamp;
  final bool isClicked;
  final bool isConverted;
  final double relevanceScore;
  final Map<String, dynamic>? userContext;

  Map<String, dynamic> toMap() => {
    'id': id,
    'adId': adId,
    'userId': userId,
    'placement': placement,
    'timestamp': Timestamp.fromDate(timestamp),
    'isClicked': isClicked,
    'isConverted': isConverted,
    'relevanceScore': relevanceScore,
    'userContext': userContext,
  };
}

class AdOptimization {
  AdOptimization({
    required this.id,
    required this.adId,
    required this.optimizationType,
    required this.parameters,
    required this.results,
    required this.timestamp,
    this.isActive = true,
  });

  factory AdOptimization.fromMap(Map<String, dynamic> map) => AdOptimization(
    id: map['id'] ?? '',
    adId: map['adId'] ?? '',
    optimizationType: map['optimizationType'] ?? '',
    parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
    results: Map<String, dynamic>.from(map['results'] ?? {}),
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    isActive: map['isActive'] ?? true,
  );

  final String id;
  final String adId;
  final String optimizationType;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> results;
  final DateTime timestamp;
  final bool isActive;

  Map<String, dynamic> toMap() => {
    'id': id,
    'adId': adId,
    'optimizationType': optimizationType,
    'parameters': parameters,
    'results': results,
    'timestamp': Timestamp.fromDate(timestamp),
    'isActive': isActive,
  };
}

extension DateTimeExtension on DateTime {
  bool isBetween(DateTime from, DateTime to) {
    return isAfter(from) && isBefore(to);
  }
}
