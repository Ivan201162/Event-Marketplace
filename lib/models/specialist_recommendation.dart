import 'package:flutter/foundation.dart';

import 'recommendation.dart';
import 'specialist.dart';

/// Модель рекомендации специалиста
@immutable
class SpecialistRecommendation {
  const SpecialistRecommendation({
    required this.id,
    required this.specialistId,
    required this.reason,
    required this.score,
    required this.timestamp,
    this.specialist, // Optional, for richer data
  });

  final String id;
  final String specialistId;
  final String reason;
  final double score;
  final DateTime timestamp;
  final Specialist? specialist; // Optional specialist object

  /// Получить объект Recommendation
  Recommendation get recommendation => Recommendation(
        id: id,
        type: RecommendationType.basedOnHistory,
        score: score,
        reason: reason,
        createdAt: timestamp,
      );

  SpecialistRecommendation copyWith({
    String? id,
    String? specialistId,
    String? reason,
    double? score,
    DateTime? timestamp,
    Specialist? specialist,
  }) =>
      SpecialistRecommendation(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        reason: reason ?? this.reason,
        score: score ?? this.score,
        timestamp: timestamp ?? this.timestamp,
        specialist: specialist ?? this.specialist,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SpecialistRecommendation &&
        other.id == id &&
        other.specialistId == specialistId &&
        other.reason == reason &&
        other.score == score &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode =>
      id.hashCode ^ specialistId.hashCode ^ reason.hashCode ^ score.hashCode ^ timestamp.hashCode;

  @override
  String toString() =>
      'SpecialistRecommendation(id: $id, specialistId: $specialistId, reason: $reason, score: $score, timestamp: $timestamp)';
}

/// Расширение для фильтрации списка рекомендаций специалистов
extension SpecialistRecommendationListExtension on List<SpecialistRecommendation> {
  List<SpecialistRecommendation> byType(RecommendationType type) =>
      where((recommendation) => recommendation.recommendation.type == type).toList();
}
