import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отзыва
class Review {
  final String id;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final int rating; // 1-5 звезд
  final String? title;
  final String? comment;
  final List<String> tags; // Теги для категоризации
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified; // Проверен ли отзыв
  final bool isPublic; // Публичный ли отзыв
  final Map<String, dynamic>? metadata;

  const Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.rating,
    this.title,
    this.comment,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.isPublic = true,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory Review.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      rating: data['rating'] ?? 5,
      title: data['title'],
      comment: data['comment'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      isVerified: data['isVerified'] ?? false,
      isPublic: data['isPublic'] ?? true,
      metadata: data['metadata'],
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'specialistId': specialistId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerified': isVerified,
      'isPublic': isPublic,
      'metadata': metadata,
    };
  }

  /// Копировать с изменениями
  Review copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? specialistId,
    int? rating,
    String? title,
    String? comment,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isPublic,
    Map<String, dynamic>? metadata,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isPublic: isPublic ?? this.isPublic,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Проверить, валиден ли рейтинг
  bool get isValidRating => rating >= 1 && rating <= 5;

  /// Получить текстовое описание рейтинга
  String get ratingDescription {
    switch (rating) {
      case 1:
        return 'Очень плохо';
      case 2:
        return 'Плохо';
      case 3:
        return 'Удовлетворительно';
      case 4:
        return 'Хорошо';
      case 5:
        return 'Отлично';
      default:
        return 'Не оценено';
    }
  }

  /// Получить цвет рейтинга
  String get ratingColor {
    switch (rating) {
      case 1:
      case 2:
        return 'red';
      case 3:
        return 'orange';
      case 4:
      case 5:
        return 'green';
      default:
        return 'grey';
    }
  }

  /// Проверить, есть ли комментарий
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Проверить, есть ли заголовок
  bool get hasTitle => title != null && title!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Review(id: $id, rating: $rating, specialistId: $specialistId)';
  }
}

/// Статистика отзывов
class ReviewStatistics {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // Количество отзывов по рейтингам
  final List<String> commonTags;
  final double verifiedPercentage;
  final DateTime? lastReviewDate;

  const ReviewStatistics({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.commonTags,
    required this.verifiedPercentage,
    this.lastReviewDate,
  });

  factory ReviewStatistics.empty() {
    return const ReviewStatistics(
      averageRating: 0.0,
      totalReviews: 0,
      ratingDistribution: {},
      commonTags: [],
      verifiedPercentage: 0.0,
    );
  }

  /// Получить процент отзывов с определенным рейтингом
  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0.0;
    final count = ratingDistribution[rating] ?? 0;
    return (count / totalReviews) * 100;
  }

  /// Проверить, есть ли отзывы
  bool get hasReviews => totalReviews > 0;

  /// Получить текстовое описание среднего рейтинга
  String get averageRatingDescription {
    if (averageRating >= 4.5) return 'Отлично';
    if (averageRating >= 3.5) return 'Хорошо';
    if (averageRating >= 2.5) return 'Удовлетворительно';
    if (averageRating >= 1.5) return 'Плохо';
    return 'Очень плохо';
  }
}

/// Теги для отзывов
class ReviewTags {
  static const List<String> positiveTags = [
    'Профессионализм',
    'Пунктуальность',
    'Качество работы',
    'Внимательность',
    'Коммуникабельность',
    'Креативность',
    'Ответственность',
    'Дружелюбность',
  ];

  static const List<String> negativeTags = [
    'Опоздание',
    'Плохое качество',
    'Невнимательность',
    'Грубость',
    'Неопытность',
    'Неорганизованность',
    'Нарушение договоренностей',
    'Плохая коммуникация',
  ];

  static const List<String> neutralTags = [
    'Средний уровень',
    'Обычное качество',
    'Стандартный подход',
    'Без особенностей',
  ];

  /// Получить все доступные теги
  static List<String> getAllTags() {
    return [...positiveTags, ...negativeTags, ...neutralTags];
  }

  /// Получить теги по рейтингу
  static List<String> getTagsByRating(int rating) {
    if (rating >= 4) return positiveTags;
    if (rating <= 2) return negativeTags;
    return neutralTags;
  }
}

/// Критерии оценки
class RatingCriteria {
  final String name;
  final String description;
  final int weight; // Вес критерия (1-5)

  const RatingCriteria({
    required this.name,
    required this.description,
    this.weight = 1,
  });
}

/// Детальная оценка по критериям
class DetailedRating {
  final String reviewId;
  final Map<String, int> criteriaRatings; // Критерий -> рейтинг (1-5)
  final DateTime createdAt;

  const DetailedRating({
    required this.reviewId,
    required this.criteriaRatings,
    required this.createdAt,
  });

  /// Создать из документа Firestore
  factory DetailedRating.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DetailedRating(
      reviewId: data['reviewId'] ?? '',
      criteriaRatings: Map<String, int>.from(data['criteriaRatings'] ?? {}),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'criteriaRatings': criteriaRatings,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Получить средний рейтинг по критериям
  double get averageRating {
    if (criteriaRatings.isEmpty) return 0.0;
    final sum = criteriaRatings.values.reduce((a, b) => a + b);
    return sum / criteriaRatings.length;
  }
}

/// Стандартные критерии оценки
class StandardRatingCriteria {
  static const List<RatingCriteria> specialistCriteria = [
    RatingCriteria(
      name: 'Профессионализм',
      description: 'Уровень профессиональных навыков и знаний',
      weight: 3,
    ),
    RatingCriteria(
      name: 'Пунктуальность',
      description: 'Соблюдение временных рамок',
      weight: 2,
    ),
    RatingCriteria(
      name: 'Коммуникация',
      description: 'Качество общения и понимания требований',
      weight: 2,
    ),
    RatingCriteria(
      name: 'Качество работы',
      description: 'Результат выполненной работы',
      weight: 3,
    ),
    RatingCriteria(
      name: 'Отзывчивость',
      description: 'Готовность помочь и ответить на вопросы',
      weight: 1,
    ),
  ];

  static const List<RatingCriteria> customerCriteria = [
    RatingCriteria(
      name: 'Четкость требований',
      description: 'Ясность в постановке задач',
      weight: 2,
    ),
    RatingCriteria(
      name: 'Сотрудничество',
      description: 'Готовность к взаимодействию',
      weight: 2,
    ),
    RatingCriteria(
      name: 'Оплата',
      description: 'Своевременность оплаты',
      weight: 3,
    ),
    RatingCriteria(
      name: 'Взаимодействие',
      description: 'Качество общения в процессе работы',
      weight: 2,
    ),
  ];
}
