import 'package:cloud_firestore/cloud_firestore.dart';

import 'specialist.dart';

/// Тип рекомендации
enum RecommendationType {
  basedOnHistory, // На основе истории заказов
  popular, // Популярные специалисты
  categoryBased, // На основе категорий
  similarUsers, // На основе похожих пользователей
  trending, // Трендовые
  nearby, // Поблизости
  similarSpecialists, // Похожие специалисты
  popularInCategory, // Популярные в категории
  recentlyViewed, // Недавно просмотренные
  priceRange, // По ценовому диапазону
  availability, // По доступности
}

extension RecommendationTypeExtension on RecommendationType {
  String get info {
    switch (this) {
      case RecommendationType.basedOnHistory:
        return 'На основе вашей истории';
      case RecommendationType.popular:
        return 'Популярные специалисты';
      case RecommendationType.categoryBased:
        return 'В вашей категории';
      case RecommendationType.similarUsers:
        return 'Похожие пользователи';
      case RecommendationType.trending:
        return 'Трендовые';
      case RecommendationType.nearby:
        return 'Поблизости';
      case RecommendationType.similarSpecialists:
        return 'Похожие специалисты';
      case RecommendationType.popularInCategory:
        return 'Популярные в категории';
      case RecommendationType.recentlyViewed:
        return 'Недавно просмотренные';
      case RecommendationType.priceRange:
        return 'По ценовому диапазону';
      case RecommendationType.availability:
        return 'По доступности';
    }
  }
}

/// Модель рекомендации специалиста
class Recommendation {
  const Recommendation({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.specialist,
    required this.type,
    required this.score,
    required this.reason,
    required this.createdAt,
    this.metadata,
    this.category,
    this.location,
    this.priceRange,
    this.rating,
    this.bookingCount,
    this.isViewed = false,
    this.isClicked = false,
    this.isBooked = false,
    this.viewedAt,
    this.clickedAt,
    this.bookedAt,
  });

  /// Создать из документа Firestore
  factory Recommendation.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Recommendation(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      specialist:
          Specialist.fromMap(data['specialist'] as Map<String, dynamic>),
      type: RecommendationType.values.firstWhere(
        (e) => e.name == (data['type'] as String?),
        orElse: () => RecommendationType.popular,
      ),
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      reason: data['reason'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      category: data['category'] as String?,
      location: data['location'] as String?,
      priceRange: data['priceRange'] as String?,
      rating: (data['rating'] as num?)?.toDouble(),
      bookingCount: data['bookingCount'] as int?,
      isViewed: data['isViewed'] as bool? ?? false,
      isClicked: data['isClicked'] as bool? ?? false,
      isBooked: data['isBooked'] as bool? ?? false,
      viewedAt: data['viewedAt'] != null
          ? (data['viewedAt'] as Timestamp).toDate()
          : null,
      clickedAt: data['clickedAt'] != null
          ? (data['clickedAt'] as Timestamp).toDate()
          : null,
      bookedAt: data['bookedAt'] != null
          ? (data['bookedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Создать из Map
  factory Recommendation.fromMap(Map<String, dynamic> map) => Recommendation(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        specialistId: map['specialistId'] as String? ?? '',
        specialist:
            Specialist.fromMap(map['specialist'] as Map<String, dynamic>),
        type: RecommendationType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => RecommendationType.popular,
        ),
        score: (map['score'] as num?)?.toDouble() ?? 0.0,
        reason: map['reason'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        metadata: map['metadata'] as Map<String, dynamic>?,
        category: map['category'] as String?,
        location: map['location'] as String?,
        priceRange: map['priceRange'] as String?,
        rating: (map['rating'] as num?)?.toDouble(),
        bookingCount: map['bookingCount'] as int?,
        isViewed: map['isViewed'] as bool? ?? false,
        isClicked: map['isClicked'] as bool? ?? false,
        isBooked: map['isBooked'] as bool? ?? false,
        viewedAt: map['viewedAt'] != null
            ? (map['viewedAt'] as Timestamp).toDate()
            : null,
        clickedAt: map['clickedAt'] != null
            ? (map['clickedAt'] as Timestamp).toDate()
            : null,
        bookedAt: map['bookedAt'] != null
            ? (map['bookedAt'] as Timestamp).toDate()
            : null,
      );

  final String id;
  final String userId;
  final String specialistId;
  final Specialist specialist;
  final RecommendationType type;
  final double score; // Оценка релевантности (0.0 - 1.0)
  final String reason; // Причина рекомендации
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final String? category;
  final String? location;
  final String? priceRange;
  final double? rating;
  final int? bookingCount;
  final bool isViewed;
  final bool isClicked;
  final bool isBooked;
  final DateTime? viewedAt;
  final DateTime? clickedAt;
  final DateTime? bookedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'specialistId': specialistId,
        'specialist': specialist.toMap(),
        'type': type.name,
        'score': score,
        'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
        'metadata': metadata,
        'category': category,
        'location': location,
        'priceRange': priceRange,
        'rating': rating,
        'bookingCount': bookingCount,
        'isViewed': isViewed,
        'isClicked': isClicked,
        'isBooked': isBooked,
        'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
        'clickedAt': clickedAt != null ? Timestamp.fromDate(clickedAt!) : null,
        'bookedAt': bookedAt != null ? Timestamp.fromDate(bookedAt!) : null,
      };

  /// Создать копию с изменениями
  Recommendation copyWith({
    String? id,
    String? userId,
    String? specialistId,
    Specialist? specialist,
    RecommendationType? type,
    double? score,
    String? reason,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    String? category,
    String? location,
    String? priceRange,
    double? rating,
    int? bookingCount,
    bool? isViewed,
    bool? isClicked,
    bool? isBooked,
    DateTime? viewedAt,
    DateTime? clickedAt,
    DateTime? bookedAt,
  }) =>
      Recommendation(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        specialistId: specialistId ?? this.specialistId,
        specialist: specialist ?? this.specialist,
        type: type ?? this.type,
        score: score ?? this.score,
        reason: reason ?? this.reason,
        createdAt: createdAt ?? this.createdAt,
        metadata: metadata ?? this.metadata,
        category: category ?? this.category,
        location: location ?? this.location,
        priceRange: priceRange ?? this.priceRange,
        rating: rating ?? this.rating,
        bookingCount: bookingCount ?? this.bookingCount,
        isViewed: isViewed ?? this.isViewed,
        isClicked: isClicked ?? this.isClicked,
        isBooked: isBooked ?? this.isBooked,
        viewedAt: viewedAt ?? this.viewedAt,
        clickedAt: clickedAt ?? this.clickedAt,
        bookedAt: bookedAt ?? this.bookedAt,
      );

  /// Получить текст типа рекомендации
  String get typeText {
    switch (type) {
      case RecommendationType.basedOnHistory:
        return 'На основе ваших заказов';
      case RecommendationType.popular:
        return 'Популярные специалисты';
      case RecommendationType.categoryBased:
        return 'В ваших категориях';
      case RecommendationType.similarUsers:
        return 'Похожие пользователи';
      case RecommendationType.trending:
        return 'Трендовые';
      case RecommendationType.nearby:
        return 'Поблизости';
      case RecommendationType.similarSpecialists:
        return 'Похожие специалисты';
      case RecommendationType.popularInCategory:
        return 'Популярные в категории';
      case RecommendationType.recentlyViewed:
        return 'Недавно просмотренные';
      case RecommendationType.priceRange:
        return 'По ценовому диапазону';
      case RecommendationType.availability:
        return 'По доступности';
    }
  }

  /// Получить иконку типа рекомендации
  String get typeIcon {
    switch (type) {
      case RecommendationType.basedOnHistory:
        return '📋';
      case RecommendationType.popular:
        return '⭐';
      case RecommendationType.categoryBased:
        return '🏷️';
      case RecommendationType.similarUsers:
        return '👥';
      case RecommendationType.trending:
        return '📈';
      case RecommendationType.nearby:
        return '📍';
      case RecommendationType.similarSpecialists:
        return '👥';
      case RecommendationType.popularInCategory:
        return '⭐';
      case RecommendationType.recentlyViewed:
        return '👁️';
      case RecommendationType.priceRange:
        return '💰';
      case RecommendationType.availability:
        return '📅';
    }
  }

  /// Получить цвет типа рекомендации
  String get typeColor {
    switch (type) {
      case RecommendationType.basedOnHistory:
        return 'blue';
      case RecommendationType.popular:
        return 'orange';
      case RecommendationType.categoryBased:
        return 'green';
      case RecommendationType.similarUsers:
        return 'purple';
      case RecommendationType.trending:
        return 'red';
      case RecommendationType.nearby:
        return 'teal';
      case RecommendationType.similarSpecialists:
        return 'purple';
      case RecommendationType.popularInCategory:
        return 'orange';
      case RecommendationType.recentlyViewed:
        return 'blue';
      case RecommendationType.priceRange:
        return 'green';
      case RecommendationType.availability:
        return 'teal';
    }
  }

  /// Проверить, является ли рекомендация новой
  bool get isNew => !isViewed;

  /// Проверить, была ли рекомендация успешной (привела к бронированию)
  bool get isSuccessful => isBooked;

  /// Получить процент успешности
  double get successRate {
    if (!isViewed) return 0;
    return isBooked ? 1.0 : 0.0;
  }
}

/// Расширение для RecommendationType
extension RecommendationTypeExtension on RecommendationType {
  String get displayName {
    switch (this) {
      case RecommendationType.basedOnHistory:
        return 'На основе истории';
      case RecommendationType.popular:
        return 'Популярные';
      case RecommendationType.categoryBased:
        return 'По категориям';
      case RecommendationType.similarUsers:
        return 'Похожие пользователи';
      case RecommendationType.trending:
        return 'Трендовые';
      case RecommendationType.nearby:
        return 'Поблизости';
      case RecommendationType.similarSpecialists:
        return 'Похожие специалисты';
      case RecommendationType.popularInCategory:
        return 'Популярные в категории';
      case RecommendationType.recentlyViewed:
        return 'Недавно просмотренные';
      case RecommendationType.priceRange:
        return 'По ценовому диапазону';
      case RecommendationType.availability:
        return 'По доступности';
    }
  }

  String get icon {
    switch (this) {
      case RecommendationType.basedOnHistory:
        return '📋';
      case RecommendationType.popular:
        return '⭐';
      case RecommendationType.categoryBased:
        return '🏷️';
      case RecommendationType.similarUsers:
        return '👥';
      case RecommendationType.trending:
        return '📈';
      case RecommendationType.nearby:
        return '📍';
      case RecommendationType.similarSpecialists:
        return '👥';
      case RecommendationType.popularInCategory:
        return '⭐';
      case RecommendationType.recentlyViewed:
        return '👁️';
      case RecommendationType.priceRange:
        return '💰';
      case RecommendationType.availability:
        return '📅';
    }
  }

  String get description {
    switch (this) {
      case RecommendationType.basedOnHistory:
        return 'Специалисты, похожие на тех, кого вы уже заказывали';
      case RecommendationType.popular:
        return 'Самые популярные специалисты в приложении';
      case RecommendationType.categoryBased:
        return 'Специалисты из категорий, которые вас интересуют';
      case RecommendationType.similarUsers:
        return 'Специалисты, которых заказывают пользователи с похожими предпочтениями';
      case RecommendationType.trending:
        return 'Специалисты, набирающие популярность';
      case RecommendationType.nearby:
        return 'Специалисты в вашем районе';
    }
  }
}

/// Модель для группировки рекомендаций
class RecommendationGroup {
  const RecommendationGroup({
    required this.type,
    required this.title,
    required this.recommendations,
    this.description,
    this.icon,
  });

  final RecommendationType type;
  final String title;
  final List<Recommendation> recommendations;
  final String? description;
  final String? icon;

  /// Создать копию с изменениями
  RecommendationGroup copyWith({
    RecommendationType? type,
    String? title,
    List<Recommendation>? recommendations,
    String? description,
    String? icon,
  }) =>
      RecommendationGroup(
        type: type ?? this.type,
        title: title ?? this.title,
        recommendations: recommendations ?? this.recommendations,
        description: description ?? this.description,
        icon: icon ?? this.icon,
      );

  /// Проверить, пуста ли группа
  bool get isEmpty => recommendations.isEmpty;

  /// Проверить, не пуста ли группа
  bool get isNotEmpty => recommendations.isNotEmpty;

  /// Получить количество рекомендаций
  int get length => recommendations.length;
}

/// Статистика рекомендаций
class RecommendationStats {
  const RecommendationStats({
    required this.totalRecommendations,
    required this.viewedRecommendations,
    required this.clickedRecommendations,
    required this.bookedRecommendations,
    required this.viewRate,
    required this.clickRate,
    required this.conversionRate,
    required this.avgScore,
  }); // Средняя оценка релевантности

  /// Создать пустую статистику
  factory RecommendationStats.empty() => const RecommendationStats(
        totalRecommendations: 0,
        viewedRecommendations: 0,
        clickedRecommendations: 0,
        bookedRecommendations: 0,
        viewRate: 0,
        clickRate: 0,
        conversionRate: 0,
        avgScore: 0,
      );

  /// Создать из списка рекомендаций
  factory RecommendationStats.fromRecommendations(
    List<Recommendation> recommendations,
  ) {
    if (recommendations.isEmpty) return RecommendationStats.empty();

    final total = recommendations.length;
    final viewed = recommendations.where((r) => r.isViewed).length;
    final clicked = recommendations.where((r) => r.isClicked).length;
    final booked = recommendations.where((r) => r.isBooked).length;
    final avgScore = recommendations.fold(0, (sum, r) => sum + r.score) / total;

    return RecommendationStats(
      totalRecommendations: total,
      viewedRecommendations: viewed,
      clickedRecommendations: clicked,
      bookedRecommendations: booked,
      viewRate: total > 0 ? (viewed / total * 100) : 0.0,
      clickRate: viewed > 0 ? (clicked / viewed * 100) : 0.0,
      conversionRate: clicked > 0 ? (booked / clicked * 100) : 0.0,
      avgScore: avgScore,
    );
  }

  final int totalRecommendations;
  final int viewedRecommendations;
  final int clickedRecommendations;
  final int bookedRecommendations;
  final double viewRate; // Процент просмотров
  final double clickRate; // Процент кликов
  final double conversionRate; // Процент конверсии в бронирования
  final double avgScore;
}
