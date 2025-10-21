import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType { referral, purchase, subscription, engagement, milestone, special }

enum ChallengeType { daily, weekly, monthly, seasonal, event, custom }

enum ChallengeStatus { active, completed, expired, cancelled }

enum BadgeType { bronze, silver, gold, platinum, diamond, special }

enum NotificationType { achievement, challenge, reward, reminder, promotion, milestone }

class Achievement {
  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.condition,
    required this.reward,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.icon,
    this.category,
    this.points,
    this.badge,
    this.metadata,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    type: AchievementType.values.firstWhere(
      (e) => e.toString() == 'AchievementType.${map['type']}',
      orElse: () => AchievementType.engagement,
    ),
    condition: Map<String, dynamic>.from(map['condition'] ?? {}),
    reward: Map<String, dynamic>.from(map['reward'] ?? {}),
    isActive: map['isActive'] ?? true,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    icon: map['icon'],
    category: map['category'],
    points: map['points'],
    badge: map['badge'],
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final Map<String, dynamic> condition;
  final Map<String, dynamic> reward;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? icon;
  final String? category;
  final int? points;
  final String? badge;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.toString().split('.').last,
    'condition': condition,
    'reward': reward,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'icon': icon,
    'category': category,
    'points': points,
    'badge': badge,
    'metadata': metadata,
  };
}

class UserAchievement {
  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.achievementName,
    required this.achievementType,
    required this.earnedAt,
    required this.isClaimed,
    this.rewardClaimedAt,
    this.progress,
    this.metadata,
  });

  factory UserAchievement.fromMap(Map<String, dynamic> map) => UserAchievement(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    achievementId: map['achievementId'] ?? '',
    achievementName: map['achievementName'] ?? '',
    achievementType: AchievementType.values.firstWhere(
      (e) => e.toString() == 'AchievementType.${map['achievementType']}',
      orElse: () => AchievementType.engagement,
    ),
    earnedAt: (map['earnedAt'] as Timestamp).toDate(),
    isClaimed: map['isClaimed'] ?? false,
    rewardClaimedAt: map['rewardClaimedAt'] != null
        ? (map['rewardClaimedAt'] as Timestamp).toDate()
        : null,
    progress: Map<String, dynamic>.from(map['progress'] ?? {}),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String userId;
  final String achievementId;
  final String achievementName;
  final AchievementType achievementType;
  final DateTime earnedAt;
  final bool isClaimed;
  final DateTime? rewardClaimedAt;
  final Map<String, dynamic>? progress;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'achievementId': achievementId,
    'achievementName': achievementName,
    'achievementType': achievementType.toString().split('.').last,
    'earnedAt': Timestamp.fromDate(earnedAt),
    'isClaimed': isClaimed,
    'rewardClaimedAt': rewardClaimedAt != null ? Timestamp.fromDate(rewardClaimedAt!) : null,
    'progress': progress,
    'metadata': metadata,
  };
}

class Challenge {
  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.conditions,
    required this.rewards,
    required this.createdAt,
    required this.updatedAt,
    this.icon,
    this.category,
    this.participants = 0,
    this.completedCount = 0,
    this.metadata,
  });

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    type: ChallengeType.values.firstWhere(
      (e) => e.toString() == 'ChallengeType.${map['type']}',
      orElse: () => ChallengeType.daily,
    ),
    status: ChallengeStatus.values.firstWhere(
      (e) => e.toString() == 'ChallengeStatus.${map['status']}',
      orElse: () => ChallengeStatus.active,
    ),
    startDate: (map['startDate'] as Timestamp).toDate(),
    endDate: (map['endDate'] as Timestamp).toDate(),
    conditions: Map<String, dynamic>.from(map['conditions'] ?? {}),
    rewards: Map<String, dynamic>.from(map['rewards'] ?? {}),
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    icon: map['icon'],
    category: map['category'],
    participants: map['participants'] ?? 0,
    completedCount: map['completedCount'] ?? 0,
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String name;
  final String description;
  final ChallengeType type;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> conditions;
  final Map<String, dynamic> rewards;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? icon;
  final String? category;
  final int participants;
  final int completedCount;
  final Map<String, dynamic>? metadata;

  bool get isActive =>
      status == ChallengeStatus.active &&
      DateTime.now().isAfter(startDate) &&
      DateTime.now().isBefore(endDate);

  double get completionRate => participants > 0 ? completedCount / participants : 0.0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.toString().split('.').last,
    'status': status.toString().split('.').last,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'conditions': conditions,
    'rewards': rewards,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'icon': icon,
    'category': category,
    'participants': participants,
    'completedCount': completedCount,
    'metadata': metadata,
  };
}

class UserChallenge {
  UserChallenge({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.challengeName,
    required this.challengeType,
    required this.joinedAt,
    required this.status,
    this.completedAt,
    this.progress,
    this.rewardClaimedAt,
    this.metadata,
  });

  factory UserChallenge.fromMap(Map<String, dynamic> map) => UserChallenge(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    challengeId: map['challengeId'] ?? '',
    challengeName: map['challengeName'] ?? '',
    challengeType: ChallengeType.values.firstWhere(
      (e) => e.toString() == 'ChallengeType.${map['challengeType']}',
      orElse: () => ChallengeType.daily,
    ),
    joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    status: ChallengeStatus.values.firstWhere(
      (e) => e.toString() == 'ChallengeStatus.${map['status']}',
      orElse: () => ChallengeStatus.active,
    ),
    completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
    progress: Map<String, dynamic>.from(map['progress'] ?? {}),
    rewardClaimedAt: map['rewardClaimedAt'] != null
        ? (map['rewardClaimedAt'] as Timestamp).toDate()
        : null,
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String userId;
  final String challengeId;
  final String challengeName;
  final ChallengeType challengeType;
  final DateTime joinedAt;
  final ChallengeStatus status;
  final DateTime? completedAt;
  final Map<String, dynamic>? progress;
  final DateTime? rewardClaimedAt;
  final Map<String, dynamic>? metadata;

  bool get isCompleted => status == ChallengeStatus.completed;
  bool get isActive => status == ChallengeStatus.active;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'challengeId': challengeId,
    'challengeName': challengeName,
    'challengeType': challengeType.toString().split('.').last,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'status': status.toString().split('.').last,
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'progress': progress,
    'rewardClaimedAt': rewardClaimedAt != null ? Timestamp.fromDate(rewardClaimedAt!) : null,
    'metadata': metadata,
  };
}

class Badge {
  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.createdAt,
    this.category,
    this.rarity,
    this.requirements,
    this.metadata,
  });

  factory Badge.fromMap(Map<String, dynamic> map) => Badge(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    type: BadgeType.values.firstWhere(
      (e) => e.toString() == 'BadgeType.${map['type']}',
      orElse: () => BadgeType.bronze,
    ),
    icon: map['icon'] ?? '',
    color: map['color'] ?? '#FFD700',
    isActive: map['isActive'] ?? true,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    category: map['category'],
    rarity: map['rarity'],
    requirements: Map<String, dynamic>.from(map['requirements'] ?? {}),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String name;
  final String description;
  final BadgeType type;
  final String icon;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final String? category;
  final String? rarity;
  final Map<String, dynamic>? requirements;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.toString().split('.').last,
    'icon': icon,
    'color': color,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'category': category,
    'rarity': rarity,
    'requirements': requirements,
    'metadata': metadata,
  };
}

class UserBadge {
  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.badgeName,
    required this.badgeType,
    required this.earnedAt,
    required this.isDisplayed,
    this.category,
    this.metadata,
  });

  factory UserBadge.fromMap(Map<String, dynamic> map) => UserBadge(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    badgeId: map['badgeId'] ?? '',
    badgeName: map['badgeName'] ?? '',
    badgeType: BadgeType.values.firstWhere(
      (e) => e.toString() == 'BadgeType.${map['badgeType']}',
      orElse: () => BadgeType.bronze,
    ),
    earnedAt: (map['earnedAt'] as Timestamp).toDate(),
    isDisplayed: map['isDisplayed'] ?? true,
    category: map['category'],
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String userId;
  final String badgeId;
  final String badgeName;
  final BadgeType badgeType;
  final DateTime earnedAt;
  final bool isDisplayed;
  final String? category;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'badgeId': badgeId,
    'badgeName': badgeName,
    'badgeType': badgeType.toString().split('.').last,
    'earnedAt': Timestamp.fromDate(earnedAt),
    'isDisplayed': isDisplayed,
    'category': category,
    'metadata': metadata,
  };
}

class UserLevel {
  UserLevel({
    required this.userId,
    required this.level,
    required this.experience,
    required this.totalExperience,
    required this.nextLevelExperience,
    required this.updatedAt,
    this.title,
    this.benefits,
    this.metadata,
  });

  factory UserLevel.fromMap(Map<String, dynamic> map) => UserLevel(
    userId: map['userId'] ?? '',
    level: map['level'] ?? 1,
    experience: map['experience'] ?? 0,
    totalExperience: map['totalExperience'] ?? 0,
    nextLevelExperience: map['nextLevelExperience'] ?? 1000,
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    title: map['title'],
    benefits: Map<String, dynamic>.from(map['benefits'] ?? {}),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String userId;
  final int level;
  final int experience;
  final int totalExperience;
  final int nextLevelExperience;
  final DateTime updatedAt;
  final String? title;
  final Map<String, dynamic>? benefits;
  final Map<String, dynamic>? metadata;

  double get progressToNextLevel =>
      nextLevelExperience > 0 ? experience / nextLevelExperience : 0.0;

  int get experienceToNextLevel => nextLevelExperience - experience;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'level': level,
    'experience': experience,
    'totalExperience': totalExperience,
    'nextLevelExperience': nextLevelExperience,
    'updatedAt': Timestamp.fromDate(updatedAt),
    'title': title,
    'benefits': benefits,
    'metadata': metadata,
  };
}

class GrowthNotification {
  GrowthNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.actionUrl,
    this.actionText,
    this.data,
    this.readAt,
  });

  factory GrowthNotification.fromMap(Map<String, dynamic> map) => GrowthNotification(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    type: NotificationType.values.firstWhere(
      (e) => e.toString() == 'NotificationType.${map['type']}',
      orElse: () => NotificationType.reminder,
    ),
    title: map['title'] ?? '',
    message: map['message'] ?? '',
    isRead: map['isRead'] ?? false,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    actionUrl: map['actionUrl'],
    actionText: map['actionText'],
    data: Map<String, dynamic>.from(map['data'] ?? {}),
    readAt: map['readAt'] != null ? (map['readAt'] as Timestamp).toDate() : null,
  );

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;
  final String? actionText;
  final Map<String, dynamic>? data;
  final DateTime? readAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type.toString().split('.').last,
    'title': title,
    'message': message,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
    'actionUrl': actionUrl,
    'actionText': actionText,
    'data': data,
    'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
  };
}
