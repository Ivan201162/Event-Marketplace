import 'package:cloud_firestore/cloud_firestore.dart';

enum PremiumType {
  topBanner,
  highlight,
  prioritySearch,
}

class PremiumProfile {
  PremiumProfile({
    required this.userId,
    required this.activeUntil,
    required this.type,
    required this.region,
    required this.createdAt,
    this.isActive = true,
  });

  factory PremiumProfile.fromMap(Map<String, dynamic> map) => PremiumProfile(
        userId: map['userId'] ?? '',
        activeUntil: (map['activeUntil'] as Timestamp).toDate(),
        type: PremiumType.values.firstWhere(
          (e) => e.toString() == 'PremiumType.${map['type']}',
          orElse: () => PremiumType.highlight,
        ),
        region: map['region'] ?? '',
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        isActive: map['isActive'] ?? true,
      );
  final String userId;
  final DateTime activeUntil;
  final PremiumType type;
  final String region;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'activeUntil': Timestamp.fromDate(activeUntil),
        'type': type.toString().split('.').last,
        'region': region,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
      };

  bool get isExpired => DateTime.now().isAfter(activeUntil);

  PremiumProfile copyWith({
    String? userId,
    DateTime? activeUntil,
    PremiumType? type,
    String? region,
    DateTime? createdAt,
    bool? isActive,
  }) =>
      PremiumProfile(
        userId: userId ?? this.userId,
        activeUntil: activeUntil ?? this.activeUntil,
        type: type ?? this.type,
        region: region ?? this.region,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );
}
