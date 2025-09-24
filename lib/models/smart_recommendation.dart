import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип рекомендации
enum RecommendationType {
  topWeekly, // Топ специалисты недели
  trending, // Трендовые специалисты
  nearby, // Рядом с вами
  similar, // Похожие на выбранного
  category, // По категории
  price, // По цене
  rating, // По рейтингу
  availability, // Доступные сейчас
}

/// Модель умной рекомендации
class SmartRecommendation {
  final String id;
  final String specialistId;
  final String specialistName;
  final String specialistCategory;
  final String? specialistPhoto;
  final double rating;
  final int reviewCount;
  final double price;
  final String? location;
  final double distance; // Расстояние в км
  final RecommendationType type;
  final double score; // Оценка алгоритма (0-100)
  final List<String> reasons; // Причины рекомендации
  final bool isAvailable; // Доступен ли сейчас
  final DateTime? nextAvailableDate;
  final Map<String, dynamic> metadata; // Дополнительные данные
  final DateTime createdAt;
  final DateTime expiresAt; // Когда рекомендация устаревает

  const SmartRecommendation({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    required this.specialistCategory,
    this.specialistPhoto,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.location,
    required this.distance,
    required this.type,
    required this.score,
    required this.reasons,
    required this.isAvailable,
    this.nextAvailableDate,
    this.metadata = const {},
    required this.createdAt,
    required this.expiresAt,
  });

  /// Создать из документа Firestore
  factory SmartRecommendation.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SmartRecommendation(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      specialistName: data['specialistName'] as String,
      specialistCategory: data['specialistCategory'] as String,
      specialistPhoto: data['specialistPhoto'] as String?,
      rating: (data['rating'] as num).toDouble(),
      reviewCount: data['reviewCount'] as int,
      price: (data['price'] as num).toDouble(),
      location: data['location'] as String?,
      distance: (data['distance'] as num).toDouble(),
      type: RecommendationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RecommendationType.category,
      ),
      score: (data['score'] as num).toDouble(),
      reasons: List<String>.from(data['reasons'] ?? []),
      isAvailable: data['isAvailable'] as bool,
      nextAvailableDate: data['nextAvailableDate'] != null 
          ? (data['nextAvailableDate'] as Timestamp).toDate() 
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'specialistName': specialistName,
      'specialistCategory': specialistCategory,
      'specialistPhoto': specialistPhoto,
      'rating': rating,
      'reviewCount': reviewCount,
      'price': price,
      'location': location,
      'distance': distance,
      'type': type.name,
      'score': score,
      'reasons': reasons,
      'isAvailable': isAvailable,
      'nextAvailableDate': nextAvailableDate != null 
          ? Timestamp.fromDate(nextAvailableDate!) 
          : null,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  /// Создать копию с изменениями
  SmartRecommendation copyWith({
    String? id,
    String? specialistId,
    String? specialistName,
    String? specialistCategory,
    String? specialistPhoto,
    double? rating,
    int? reviewCount,
    double? price,
    String? location,
    double? distance,
    RecommendationType? type,
    double? score,
    List<String>? reasons,
    bool? isAvailable,
    DateTime? nextAvailableDate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return SmartRecommendation(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistCategory: specialistCategory ?? this.specialistCategory,
      specialistPhoto: specialistPhoto ?? this.specialistPhoto,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      price: price ?? this.price,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      type: type ?? this.type,
      score: score ?? this.score,
      reasons: reasons ?? this.reasons,
      isAvailable: isAvailable ?? this.isAvailable,
      nextAvailableDate: nextAvailableDate ?? this.nextAvailableDate,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Получить отображаемое название типа
  String get typeDisplayName {
    switch (type) {
      case RecommendationType.topWeekly:
        return 'Топ недели';
      case RecommendationType.trending:
        return 'В тренде';
      case RecommendationType.nearby:
        return 'Рядом с вами';
      case RecommendationType.similar:
        return 'Похожие';
      case RecommendationType.category:
        return 'По категории';
      case RecommendationType.price:
        return 'По цене';
      case RecommendationType.rating:
        return 'По рейтингу';
      case RecommendationType.availability:
        return 'Доступные';
    }
  }

  /// Получить иконку типа
  String get typeIcon {
    switch (type) {
      case RecommendationType.topWeekly:
        return '🏆';
      case RecommendationType.trending:
        return '📈';
      case RecommendationType.nearby:
        return '📍';
      case RecommendationType.similar:
        return '👥';
      case RecommendationType.category:
        return '📂';
      case RecommendationType.price:
        return '💰';
      case RecommendationType.rating:
        return '⭐';
      case RecommendationType.availability:
        return '✅';
    }
  }

  /// Проверить, актуальна ли рекомендация
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Получить отображаемый рейтинг
  String get ratingStars {
    return '★' * rating.round() + '☆' * (5 - rating.round());
  }
}

/// Расширение для получения названий типов рекомендаций
extension RecommendationTypeExtension on RecommendationType {
  String get displayName {
    switch (this) {
      case RecommendationType.topWeekly:
        return 'Топ недели';
      case RecommendationType.trending:
        return 'В тренде';
      case RecommendationType.nearby:
        return 'Рядом с вами';
      case RecommendationType.similar:
        return 'Похожие';
      case RecommendationType.category:
        return 'По категории';
      case RecommendationType.price:
        return 'По цене';
      case RecommendationType.rating:
        return 'По рейтингу';
      case RecommendationType.availability:
        return 'Доступные';
    }
  }
}
