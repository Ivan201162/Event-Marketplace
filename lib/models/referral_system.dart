import 'package:cloud_firestore/cloud_firestore.dart';

enum ReferralStatus { pending, completed, expired, cancelled }

enum ReferralBonusType { freePromotion, discount, premiumTrial, proTrial, cashback }

class ReferralCode {
  ReferralCode({
    required this.id,
    required this.userId,
    required this.code,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.usageCount = 0,
    this.maxUsage = 100,
  });

  factory ReferralCode.fromMap(Map<String, dynamic> map) => ReferralCode(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    code: map['code'] ?? '',
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    expiresAt: map['expiresAt'] != null ? (map['expiresAt'] as Timestamp).toDate() : null,
    isActive: map['isActive'] ?? true,
    usageCount: map['usageCount'] ?? 0,
    maxUsage: map['maxUsage'] ?? 100,
  );

  final String id;
  final String userId;
  final String code;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final int usageCount;
  final int maxUsage;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get canBeUsed => isActive && !isExpired && usageCount < maxUsage;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'code': code,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'isActive': isActive,
    'usageCount': usageCount,
    'maxUsage': maxUsage,
  };

  ReferralCode copyWith({
    String? id,
    String? userId,
    String? code,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    int? usageCount,
    int? maxUsage,
  }) => ReferralCode(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    code: code ?? this.code,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    isActive: isActive ?? this.isActive,
    usageCount: usageCount ?? this.usageCount,
    maxUsage: maxUsage ?? this.maxUsage,
  );
}

class Referral {
  Referral({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.referralCode,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.bonusApplied = false,
    this.bonusType,
    this.bonusValue,
    this.bonusDescription,
  });

  factory Referral.fromMap(Map<String, dynamic> map) => Referral(
    id: map['id'] ?? '',
    referrerId: map['referrerId'] ?? '',
    referredId: map['referredId'] ?? '',
    referralCode: map['referralCode'] ?? '',
    status: ReferralStatus.values.firstWhere(
      (e) => e.toString() == 'ReferralStatus.${map['status']}',
      orElse: () => ReferralStatus.pending,
    ),
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
    bonusApplied: map['bonusApplied'] ?? false,
    bonusType: map['bonusType'] != null
        ? ReferralBonusType.values.firstWhere(
            (e) => e.toString() == 'ReferralBonusType.${map['bonusType']}',
            orElse: () => ReferralBonusType.freePromotion,
          )
        : null,
    bonusValue: map['bonusValue']?.toDouble(),
    bonusDescription: map['bonusDescription'],
  );

  final String id;
  final String referrerId;
  final String referredId;
  final String referralCode;
  final ReferralStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool bonusApplied;
  final ReferralBonusType? bonusType;
  final double? bonusValue;
  final String? bonusDescription;

  bool get isCompleted => status == ReferralStatus.completed;
  bool get isPending => status == ReferralStatus.pending;

  Map<String, dynamic> toMap() => {
    'id': id,
    'referrerId': referrerId,
    'referredId': referredId,
    'referralCode': referralCode,
    'status': status.toString().split('.').last,
    'createdAt': Timestamp.fromDate(createdAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'bonusApplied': bonusApplied,
    'bonusType': bonusType?.toString().split('.').last,
    'bonusValue': bonusValue,
    'bonusDescription': bonusDescription,
  };

  Referral copyWith({
    String? id,
    String? referrerId,
    String? referredId,
    String? referralCode,
    ReferralStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? bonusApplied,
    ReferralBonusType? bonusType,
    double? bonusValue,
    String? bonusDescription,
  }) => Referral(
    id: id ?? this.id,
    referrerId: referrerId ?? this.referrerId,
    referredId: referredId ?? this.referredId,
    referralCode: referralCode ?? this.referralCode,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt ?? this.completedAt,
    bonusApplied: bonusApplied ?? this.bonusApplied,
    bonusType: bonusType ?? this.bonusType,
    bonusValue: bonusValue ?? this.bonusValue,
    bonusDescription: bonusDescription ?? this.bonusDescription,
  );
}

class ReferralReward {
  ReferralReward({
    required this.id,
    required this.userId,
    required this.referralId,
    required this.type,
    required this.value,
    required this.description,
    required this.createdAt,
    this.expiresAt,
    this.isUsed = false,
    this.usedAt,
  });

  factory ReferralReward.fromMap(Map<String, dynamic> map) => ReferralReward(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    referralId: map['referralId'] ?? '',
    type: ReferralBonusType.values.firstWhere(
      (e) => e.toString() == 'ReferralBonusType.${map['type']}',
      orElse: () => ReferralBonusType.freePromotion,
    ),
    value: (map['value'] ?? 0.0).toDouble(),
    description: map['description'] ?? '',
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    expiresAt: map['expiresAt'] != null ? (map['expiresAt'] as Timestamp).toDate() : null,
    isUsed: map['isUsed'] ?? false,
    usedAt: map['usedAt'] != null ? (map['usedAt'] as Timestamp).toDate() : null,
  );

  final String id;
  final String userId;
  final String referralId;
  final ReferralBonusType type;
  final double value;
  final String description;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isUsed;
  final DateTime? usedAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get canBeUsed => !isUsed && !isExpired;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'referralId': referralId,
    'type': type.toString().split('.').last,
    'value': value,
    'description': description,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'isUsed': isUsed,
    'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
  };

  ReferralReward copyWith({
    String? id,
    String? userId,
    String? referralId,
    ReferralBonusType? type,
    double? value,
    String? description,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isUsed,
    DateTime? usedAt,
  }) => ReferralReward(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    referralId: referralId ?? this.referralId,
    type: type ?? this.type,
    value: value ?? this.value,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    isUsed: isUsed ?? this.isUsed,
    usedAt: usedAt ?? this.usedAt,
  );
}

class ReferralStats {
  ReferralStats({
    required this.userId,
    required this.totalReferrals,
    required this.completedReferrals,
    required this.pendingReferrals,
    required this.totalBonusesEarned,
    required this.activeRewards,
    required this.usedRewards,
    this.lastReferralAt,
  });

  factory ReferralStats.fromMap(Map<String, dynamic> map) => ReferralStats(
    userId: map['userId'] ?? '',
    totalReferrals: map['totalReferrals'] ?? 0,
    completedReferrals: map['completedReferrals'] ?? 0,
    pendingReferrals: map['pendingReferrals'] ?? 0,
    totalBonusesEarned: (map['totalBonusesEarned'] ?? 0.0).toDouble(),
    activeRewards: map['activeRewards'] ?? 0,
    usedRewards: map['usedRewards'] ?? 0,
    lastReferralAt: map['lastReferralAt'] != null
        ? (map['lastReferralAt'] as Timestamp).toDate()
        : null,
  );

  final String userId;
  final int totalReferrals;
  final int completedReferrals;
  final int pendingReferrals;
  final double totalBonusesEarned;
  final int activeRewards;
  final int usedRewards;
  final DateTime? lastReferralAt;

  double get completionRate => totalReferrals > 0 ? completedReferrals / totalReferrals : 0.0;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'totalReferrals': totalReferrals,
    'completedReferrals': completedReferrals,
    'pendingReferrals': pendingReferrals,
    'totalBonusesEarned': totalBonusesEarned,
    'activeRewards': activeRewards,
    'usedRewards': usedRewards,
    'lastReferralAt': lastReferralAt != null ? Timestamp.fromDate(lastReferralAt!) : null,
  };
}
