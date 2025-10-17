import 'package:flutter/foundation.dart';

/// Тип взаимодействия с рекомендацией
enum RecommendationInteractionType {
  viewed,
  clicked,
  saved,
  dismissed,
}

/// Модель взаимодействия с рекомендацией
@immutable
class RecommendationInteraction {
  const RecommendationInteraction({
    required this.id,
    required this.userId,
    required this.recommendationId,
    required this.specialistId,
    required this.type,
    required this.timestamp,
  });

  factory RecommendationInteraction.fromMap(Map<String, dynamic> map) => RecommendationInteraction(
        id: map['id'] as String,
        userId: map['userId'] as String,
        recommendationId: map['recommendationId'] as String,
        specialistId: map['specialistId'] as String,
        type: RecommendationInteractionType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => RecommendationInteractionType.viewed,
        ),
        timestamp: DateTime.parse(map['timestamp'] as String),
      );

  final String id;
  final String userId;
  final String recommendationId;
  final String specialistId;
  final RecommendationInteractionType type;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'recommendationId': recommendationId,
        'specialistId': specialistId,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecommendationInteraction &&
        other.recommendationId == recommendationId &&
        other.specialistId == specialistId &&
        other.type == type &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode =>
      recommendationId.hashCode ^ specialistId.hashCode ^ type.hashCode ^ timestamp.hashCode;

  @override
  String toString() =>
      'RecommendationInteraction(recommendationId: $recommendationId, specialistId: $specialistId, type: $type, timestamp: $timestamp)';
}
