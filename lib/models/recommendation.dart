import 'package:cloud_firestore/cloud_firestore.dart';
import 'specialist.dart';
// import 'user.dart';

/// Типы рекомендаций
enum RecommendationType {
  similarSpecialists,    // Похожие специалисты
  popularInCategory,     // Популярные в категории
  recentlyViewed,        // Недавно просмотренные
  basedOnHistory,        // На основе истории
  trending,              // Трендовые
  nearby,                // Рядом с вами
  priceRange,            // В ценовом диапазоне
  availability,          // Доступные сейчас
}

/// Модель рекомендации
class Recommendation {
  final String id;
  final String userId;
  final String specialistId;
  final RecommendationType type;
  final double score;
  final String reason;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Recommendation({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.type,
    required this.score,
    required this.reason,
    required this.metadata,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Создаёт рекомендацию из документа Firestore
  factory Recommendation.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Recommendation(
      id: doc.id,
      userId: data['userId'] as String,
      specialistId: data['specialistId'] as String,
      type: RecommendationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RecommendationType.similarSpecialists,
      ),
      score: (data['score'] as num).toDouble(),
      reason: data['reason'] as String,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразует рекомендацию в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'specialistId': specialistId,
      'type': type.name,
      'score': score,
      'reason': reason,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  /// Создаёт копию рекомендации с обновлёнными полями
  Recommendation copyWith({
    String? id,
    String? userId,
    String? specialistId,
    RecommendationType? type,
    double? score,
    String? reason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Recommendation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialistId: specialistId ?? this.specialistId,
      type: type ?? this.type,
      score: score ?? this.score,
      reason: reason ?? this.reason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Проверяет, действительна ли рекомендация
  bool get isValid => DateTime.now().isBefore(expiresAt);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recommendation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Recommendation(id: $id, type: $type, score: $score)';
  }
}

/// Расширение для RecommendationType
extension RecommendationTypeExtension on RecommendationType {
  /// Получает информацию о типе рекомендации
  RecommendationTypeInfo get info {
    switch (this) {
      case RecommendationType.similarSpecialists:
        return RecommendationTypeInfo(
          title: 'Похожие специалисты',
          description: 'Специалисты с похожими навыками и опытом',
          icon: '👥',
          color: '#4CAF50',
        );
      case RecommendationType.popularInCategory:
        return RecommendationTypeInfo(
          title: 'Популярные в категории',
          description: 'Самые популярные специалисты в этой категории',
          icon: '🔥',
          color: '#FF5722',
        );
      case RecommendationType.recentlyViewed:
        return RecommendationTypeInfo(
          title: 'Недавно просмотренные',
          description: 'Специалисты, которых вы недавно смотрели',
          icon: '👁️',
          color: '#2196F3',
        );
      case RecommendationType.basedOnHistory:
        return RecommendationTypeInfo(
          title: 'На основе истории',
          description: 'Рекомендации на основе ваших предпочтений',
          icon: '📊',
          color: '#9C27B0',
        );
      case RecommendationType.trending:
        return RecommendationTypeInfo(
          title: 'Трендовые',
          description: 'Специалисты, набирающие популярность',
          icon: '📈',
          color: '#FF9800',
        );
      case RecommendationType.nearby:
        return RecommendationTypeInfo(
          title: 'Рядом с вами',
          description: 'Специалисты в вашем районе',
          icon: '📍',
          color: '#00BCD4',
        );
      case RecommendationType.priceRange:
        return RecommendationTypeInfo(
          title: 'В ценовом диапазоне',
          description: 'Специалисты в вашем ценовом диапазоне',
          icon: '💰',
          color: '#4CAF50',
        );
      case RecommendationType.availability:
        return RecommendationTypeInfo(
          title: 'Доступные сейчас',
          description: 'Специалисты, доступные в ближайшее время',
          icon: '⏰',
          color: '#8BC34A',
        );
    }
  }
}

/// Информация о типе рекомендации
class RecommendationTypeInfo {
  final String title;
  final String description;
  final String icon;
  final String color;

  const RecommendationTypeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Рекомендация с данными специалиста
class SpecialistRecommendation {
  final Recommendation recommendation;
  final Specialist specialist;
  final double relevanceScore;

  const SpecialistRecommendation({
    required this.recommendation,
    required this.specialist,
    required this.relevanceScore,
  });

  /// Создаёт рекомендацию специалиста
  factory SpecialistRecommendation.create({
    required Recommendation recommendation,
    required Specialist specialist,
    double? relevanceScore,
  }) {
    return SpecialistRecommendation(
      recommendation: recommendation,
      specialist: specialist,
      relevanceScore: relevanceScore ?? recommendation.score,
    );
  }
}

/// Расширение для работы с рекомендациями
extension RecommendationListExtension on List<Recommendation> {
  /// Получает рекомендации по типу
  List<Recommendation> byType(RecommendationType type) {
    return where((rec) => rec.type == type).toList();
  }

  /// Получает действительные рекомендации
  List<Recommendation> get valid => where((rec) => rec.isValid).toList();

  /// Получает рекомендации, отсортированные по релевантности
  List<Recommendation> get sortedByScore => 
      toList()..sort((a, b) => b.score.compareTo(a.score));

  /// Группирует рекомендации по типу
  Map<RecommendationType, List<Recommendation>> get groupedByType {
    final Map<RecommendationType, List<Recommendation>> grouped = {};
    for (final recommendation in this) {
      grouped.putIfAbsent(recommendation.type, () => []).add(recommendation);
    }
    return grouped;
  }

  /// Получает топ рекомендации
  List<Recommendation> top(int count) {
    return sortedByScore.take(count).toList();
  }
}

/// Расширение для работы с рекомендациями специалистов
extension SpecialistRecommendationListExtension on List<SpecialistRecommendation> {
  /// Получает рекомендации по типу
  List<SpecialistRecommendation> byType(RecommendationType type) {
    return where((rec) => rec.recommendation.type == type).toList();
  }

  /// Получает рекомендации, отсортированные по релевантности
  List<SpecialistRecommendation> get sortedByRelevance => 
      toList()..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

  /// Получает топ рекомендации
  List<SpecialistRecommendation> top(int count) {
    return sortedByRelevance.take(count).toList();
  }

  /// Группирует рекомендации по типу
  Map<RecommendationType, List<SpecialistRecommendation>> get groupedByType {
    final Map<RecommendationType, List<SpecialistRecommendation>> grouped = {};
    for (final recommendation in this) {
      grouped.putIfAbsent(recommendation.recommendation.type, () => [])
          .add(recommendation);
    }
    return grouped;
  }
}
