import 'package:cloud_firestore/cloud_firestore.dart';

class PromotedPost {
  PromotedPost({
    required this.postId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.budget,
    this.isActive = true,
    this.impressions = 0,
    this.clicks = 0,
    required this.createdAt,
  });

  factory PromotedPost.fromMap(Map<String, dynamic> map) => PromotedPost(
        postId: map['postId'] ?? '',
        userId: map['userId'] ?? '',
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        priority: map['priority'] ?? 1,
        budget: (map['budget'] ?? 0.0).toDouble(),
        isActive: map['isActive'] ?? true,
        impressions: map['impressions'] ?? 0,
        clicks: map['clicks'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );
  final String postId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final int priority;
  final double budget;
  final bool isActive;
  final int impressions;
  final int clicks;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'userId': userId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'priority': priority,
        'budget': budget,
        'isActive': isActive,
        'impressions': impressions,
        'clicks': clicks,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isExpired => DateTime.now().isAfter(endDate);

  bool get isCurrentlyActive =>
      isActive && !isExpired && DateTime.now().isAfter(startDate);

  PromotedPost copyWith({
    String? postId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? priority,
    double? budget,
    bool? isActive,
    int? impressions,
    int? clicks,
    DateTime? createdAt,
  }) =>
      PromotedPost(
        postId: postId ?? this.postId,
        userId: userId ?? this.userId,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        priority: priority ?? this.priority,
        budget: budget ?? this.budget,
        isActive: isActive ?? this.isActive,
        impressions: impressions ?? this.impressions,
        clicks: clicks ?? this.clicks,
        createdAt: createdAt ?? this.createdAt,
      );
}



