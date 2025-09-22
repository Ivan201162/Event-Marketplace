import 'package:flutter/foundation.dart';

/// Тип рекомендации
enum RecommendationType {
  similarSpecialists,
  popularInCategory,
  recentlyViewed,
  basedOnHistory,
  trending,
  nearby,
  priceRange,
  availability,
}

/// Информация о типе рекомендации
class RecommendationTypeInfo {
  const RecommendationTypeInfo({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final String icon;
  final String color;
}

/// Расширение для RecommendationType
extension RecommendationTypeExtension on RecommendationType {
  RecommendationTypeInfo get info {
    switch (this) {
      case RecommendationType.similarSpecialists:
        return const RecommendationTypeInfo(
          title: 'Похожие специалисты',
          icon: '👥',
          color: '#2196F3',
        );
      case RecommendationType.popularInCategory:
        return const RecommendationTypeInfo(
          title: 'Популярные в категории',
          icon: '🔥',
          color: '#FF9800',
        );
      case RecommendationType.recentlyViewed:
        return const RecommendationTypeInfo(
          title: 'Недавно просмотренные',
          icon: '👁️',
          color: '#9C27B0',
        );
      case RecommendationType.basedOnHistory:
        return const RecommendationTypeInfo(
          title: 'На основе истории',
          icon: '📊',
          color: '#4CAF50',
        );
      case RecommendationType.trending:
        return const RecommendationTypeInfo(
          title: 'Трендовые',
          icon: '📈',
          color: '#F44336',
        );
      case RecommendationType.nearby:
        return const RecommendationTypeInfo(
          title: 'Рядом с вами',
          icon: '📍',
          color: '#00BCD4',
        );
      case RecommendationType.priceRange:
        return const RecommendationTypeInfo(
          title: 'В вашем ценовом диапазоне',
          icon: '💰',
          color: '#8BC34A',
        );
      case RecommendationType.availability:
        return const RecommendationTypeInfo(
          title: 'Доступные сейчас',
          icon: '✅',
          color: '#4CAF50',
        );
    }
  }
}

/// Модель рекомендации
@immutable
class Recommendation {
  const Recommendation({
    required this.id,
    required this.type,
    required this.score,
    required this.reason,
    required this.createdAt,
    this.title = '',
    this.description = '',
    this.imageUrl,
    this.metadata = const {},
  });

  factory Recommendation.fromMap(Map<String, dynamic> map) => Recommendation(
        id: map['id'] as String,
        type: RecommendationType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => RecommendationType.basedOnHistory,
        ),
        score: (map['score'] as num).toDouble(),
        reason: map['reason'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );

  final String id;
  final RecommendationType type;
  final double score;
  final String reason;
  final DateTime createdAt;
  final String title;
  final String description;
  final String? imageUrl;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'score': score,
        'reason': reason,
        'createdAt': createdAt.toIso8601String(),
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'metadata': metadata,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Recommendation &&
        other.id == id &&
        other.type == type &&
        other.score == score &&
        other.reason == reason &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      score.hashCode ^
      reason.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'Recommendation(id: $id, type: $type, score: $score, reason: $reason, createdAt: $createdAt)';
}

/// Расширение для фильтрации списка рекомендаций
extension RecommendationListExtension on List<Recommendation> {
  List<Recommendation> byType(RecommendationType type) =>
      where((recommendation) => recommendation.type == type).toList();
}
