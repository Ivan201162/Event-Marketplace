import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип отзыва
enum ReviewType {
  event,
  specialist,
  service,
}

/// Теги отзывов
class ReviewTags {
  static const List<String> eventTags = [
    'отличная организация',
    'интересная программа',
    'хорошее место',
    'дружелюбная атмосфера',
    'полезная информация',
    'профессиональный подход',
  ];

  static const List<String> specialistTags = [
    'профессионализм',
    'вежливость',
    'пунктуальность',
    'качество работы',
    'коммуникабельность',
    'креативность',
  ];

  static const List<String> serviceTags = [
    'быстрое обслуживание',
    'качественный сервис',
    'доступные цены',
    'удобство',
    'надежность',
    'индивидуальный подход',
  ];

  static List<String> getTagsForType(ReviewType type) {
    switch (type) {
      case ReviewType.event:
        return eventTags;
      case ReviewType.specialist:
        return specialistTags;
      case ReviewType.service:
        return serviceTags;
    }
  }

  static List<String> getTagsByRating(int rating) {
    // Возвращаем теги в зависимости от рейтинга
    if (rating >= 4) {
      return [
        'отличная организация',
        'профессионализм',
        'качественный сервис',
        'вежливость',
        'пунктуальность',
      ];
    } else if (rating >= 3) {
      return [
        'хорошее место',
        'коммуникабельность',
        'быстрое обслуживание',
      ];
    } else {
      return [
        'требует улучшения',
        'медленное обслуживание',
      ];
    }
  }
}

/// Статус отзыва
enum ReviewStatus {
  pending,
  approved,
  rejected,
  hidden,
}

/// Детальный рейтинг
class DetailedRating {
  const DetailedRating({
    required this.professionalism,
    required this.communication,
    required this.punctuality,
    required this.quality,
    required this.creativity,
    required this.value,
  });

  /// Создать из Map
  factory DetailedRating.fromMap(Map<String, dynamic> data) => DetailedRating(
        professionalism: (data['professionalism'] as num? ?? 0.0).toDouble(),
        communication: (data['communication'] as num? ?? 0.0).toDouble(),
        punctuality: (data['punctuality'] as num? ?? 0.0).toDouble(),
        quality: (data['quality'] as num? ?? 0.0).toDouble(),
        creativity: (data['creativity'] as num? ?? 0.0).toDouble(),
        value: (data['value'] as num? ?? 0.0).toDouble(),
      );
  final double professionalism;
  final double communication;
  final double punctuality;
  final double quality;
  final double creativity;
  final double value;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'professionalism': professionalism,
        'communication': communication,
        'punctuality': punctuality,
        'quality': quality,
        'creativity': creativity,
        'value': value,
      };

  /// Получить средний рейтинг
  double get averageRating =>
      (professionalism +
          communication +
          punctuality +
          quality +
          creativity +
          value) /
      6;
}

/// Модель отзыва
class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.targetId,
    required this.type,
    required this.rating,
    required this.title,
    required this.content,
    this.images = const [],
    this.tags = const [],
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.reportCount = 0,
    this.isHelpful = false,
    this.helpfulCount = 0,
    this.isReported = false,
    this.notHelpfulCount = 0,
    this.helpfulVotes = const {},
    this.response,
    this.responseAuthorId,
    this.responseDate,
    this.metadata,
    this.eventId,
    this.specialistId,
    this.detailedRating,
  });

  /// Создать отзыв из документа Firestore
  factory Review.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Review(
      id: doc.id,
      reviewerId: data['reviewerId'] as String? ?? '',
      reviewerName: data['reviewerName'] as String? ?? '',
      reviewerAvatar: data['reviewerAvatar'] as String?,
      targetId: data['targetId'] as String? ?? '',
      bookingId: data['bookingId'] as String? ?? '',
      type: ReviewType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ReviewType.event,
      ),
      rating: data['rating'] ?? 5,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      status: ReviewStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReviewStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] ?? false,
      isHelpful: data['isHelpful'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
      notHelpfulCount: data['notHelpfulCount'] ?? 0,
      helpfulVotes: Map<String, bool>.from(data['helpfulVotes'] ?? {}),
      response: data['response'],
      responseAuthorId: data['responseAuthorId'],
      responseDate: data['responseDate'] != null
          ? (data['responseDate'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'],
      eventId: data['eventId'],
      specialistId: data['specialistId'],
      detailedRating: data['detailedRating'] != null
          ? DetailedRating.fromMap(data['detailedRating'])
          : null,
    );
  }

  /// Создать объект из Map
  factory Review.fromMap(Map<String, dynamic> map) => Review(
        id: map['id'] ?? '',
        bookingId: map['bookingId'] ?? '',
        reviewerId: map['customerId'] ?? map['reviewerId'] ?? '',
        reviewerName: map['customerName'] ?? map['reviewerName'] ?? '',
        targetId: map['targetId'] ?? map['specialistId'] ?? '',
        type: ReviewType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => ReviewType.service,
        ),
        rating: (map['rating'] ?? 0).toDouble(),
        title: map['title'] ?? '',
        content: map['content'] ?? '',
        tags: (map['tags'] as List<dynamic>?)
                ?.map((tag) => tag.toString())
                .toList() ??
            [],
        status: ReviewStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ReviewStatus.pending,
        ),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
        isVerified: map['isVerified'] ?? false,
        response: map['response'],
        responseDate: map['responseDate'] != null
            ? (map['responseDate'] as Timestamp).toDate()
            : null,
        helpfulCount: map['helpfulCount'] ?? 0,
        reportCount: map['reportCount'] ?? 0,
        isReported: map['isReported'] ?? false,
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
  final String id;
  final String bookingId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerAvatar;
  final String targetId; // ID события, специалиста или сервиса
  final ReviewType type;
  final int rating; // 1-5 звезд
  final String title;
  final String content;
  final List<String> images; // URL изображений
  final List<String> tags; // Теги отзыва
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified; // Проверенный отзыв
  final int reportCount; // Количество жалоб
  final bool isHelpful; // Полезный отзыв
  final int helpfulCount; // Количество "полезно"
  final bool isReported; // Отмечен как жалоба
  final int notHelpfulCount; // Количество "не полезно"
  final Map<String, bool> helpfulVotes; // Кто проголосовал
  final String? response; // Ответ на отзыв
  final String? responseAuthorId; // ID автора ответа
  final DateTime? responseDate; // Дата ответа
  final Map<String, dynamic>? metadata; // Дополнительные данные
  final String? eventId;
  final String? specialistId;
  final DetailedRating? detailedRating;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'reviewerAvatar': reviewerAvatar,
        'targetId': targetId,
        'type': type.name,
        'rating': rating,
        'title': title,
        'content': content,
        'images': images,
        'tags': tags,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'isVerified': isVerified,
        'isHelpful': isHelpful,
        'helpfulCount': helpfulCount,
        'notHelpfulCount': notHelpfulCount,
        'helpfulVotes': helpfulVotes,
        'response': response,
        'responseAuthorId': responseAuthorId,
        'responseDate':
            responseDate != null ? Timestamp.fromDate(responseDate!) : null,
        'metadata': metadata,
        'eventId': eventId,
        'specialistId': specialistId,
        'detailedRating': detailedRating?.toMap(),
      };

  /// Создать копию с изменениями
  Review copyWith({
    String? id,
    String? reviewerId,
    String? reviewerName,
    String? reviewerAvatar,
    String? targetId,
    ReviewType? type,
    int? rating,
    String? title,
    String? content,
    List<String>? images,
    List<String>? tags,
    ReviewStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isHelpful,
    int? helpfulCount,
    int? notHelpfulCount,
    Map<String, bool>? helpfulVotes,
    String? response,
    String? responseAuthorId,
    DateTime? responseDate,
    Map<String, dynamic>? metadata,
    String? eventId,
    String? specialistId,
    DetailedRating? detailedRating,
  }) =>
      Review(
        id: id ?? this.id,
        bookingId: bookingId ?? bookingId,
        reviewerId: reviewerId ?? this.reviewerId,
        reviewerName: reviewerName ?? this.reviewerName,
        reviewerAvatar: reviewerAvatar ?? this.reviewerAvatar,
        targetId: targetId ?? this.targetId,
        type: type ?? this.type,
        rating: rating ?? this.rating,
        title: title ?? this.title,
        content: content ?? this.content,
        images: images ?? this.images,
        tags: tags ?? this.tags,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isVerified: isVerified ?? this.isVerified,
        isHelpful: isHelpful ?? this.isHelpful,
        helpfulCount: helpfulCount ?? this.helpfulCount,
        notHelpfulCount: notHelpfulCount ?? this.notHelpfulCount,
        helpfulVotes: helpfulVotes ?? this.helpfulVotes,
        response: response ?? this.response,
        responseAuthorId: responseAuthorId ?? this.responseAuthorId,
        responseDate: responseDate ?? this.responseDate,
        metadata: metadata ?? this.metadata,
        eventId: eventId ?? this.eventId,
        specialistId: specialistId ?? this.specialistId,
        detailedRating: detailedRating ?? this.detailedRating,
      );

  /// Проверить, может ли пользователь голосовать за полезность
  bool canVoteHelpful(String userId) =>
      !helpfulVotes.containsKey(userId) && reviewerId != userId;

  /// Проверить, проголосовал ли пользователь
  bool? getUserVote(String userId) => helpfulVotes[userId];

  /// Получить процент полезности
  double get helpfulPercentage {
    final total = helpfulCount + notHelpfulCount;
    if (total == 0) return 0;
    return (helpfulCount / total) * 100;
  }

  /// Проверить, есть ли ответ
  bool get hasResponse => response != null && response!.isNotEmpty;

  /// Проверить, является ли отзыв проверенным
  bool get isVerifiedReview => isVerified;

  /// Получить название типа отзыва
  String get typeDisplayName {
    switch (type) {
      case ReviewType.event:
        return 'Событие';
      case ReviewType.specialist:
        return 'Специалист';
      case ReviewType.service:
        return 'Сервис';
    }
  }

  /// Получить имя пользователя (для совместимости)
  String get userName => reviewerName;

  /// Получить URL фото пользователя (для совместимости)
  String? get userPhotoUrl => reviewerAvatar;

  /// Получить ID клиента (для совместимости)
  String get customerId => reviewerId;

  /// Получить текст рейтинга
  String get ratingText {
    switch (rating) {
      case 1:
        return 'Ужасно';
      case 2:
        return 'Плохо';
      case 3:
        return 'Нормально';
      case 4:
        return 'Хорошо';
      case 5:
        return 'Отлично';
      default:
        return '';
    }
  }

  /// Получить комментарий (для совместимости)
  String? get comment => content;

  /// Получить название статуса
  String get statusDisplayName {
    switch (status) {
      case ReviewStatus.pending:
        return 'На рассмотрении';
      case ReviewStatus.approved:
        return 'Одобрен';
      case ReviewStatus.rejected:
        return 'Отклонен';
      case ReviewStatus.hidden:
        return 'Скрыт';
    }
  }

  /// Получить цвет статуса
  String get statusColor {
    switch (status) {
      case ReviewStatus.pending:
        return 'orange';
      case ReviewStatus.approved:
        return 'green';
      case ReviewStatus.rejected:
        return 'red';
      case ReviewStatus.hidden:
        return 'grey';
    }
  }

  /// Геттеры для совместимости с виджетами
  bool get hasComment => content.isNotEmpty;
  bool get isPublic => status == ReviewStatus.approved;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Review(id: $id, type: $type, rating: $rating, title: $title)';
}

/// Статистика отзывов
class ReviewStats {
  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.verifiedReviews,
    required this.helpfulReviews,
    required this.helpfulPercentage,
    required this.lastUpdated,
  });

  /// Создать статистику из документа Firestore
  factory ReviewStats.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return ReviewStats(
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {}),
      verifiedReviews: data['verifiedReviews'] ?? 0,
      helpfulReviews: data['helpfulReviews'] ?? 0,
      helpfulPercentage: (data['helpfulPercentage'] ?? 0.0).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // рейтинг -> количество
  final int verifiedReviews;
  final int helpfulReviews;
  final double helpfulPercentage;
  final DateTime lastUpdated;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'ratingDistribution': ratingDistribution,
        'verifiedReviews': verifiedReviews,
        'helpfulReviews': helpfulReviews,
        'helpfulPercentage': helpfulPercentage,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  /// Получить процент для конкретного рейтинга
  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0;
    final count = ratingDistribution[rating] ?? 0;
    return (count / totalReviews) * 100;
  }

  /// Проверить, есть ли отзывы
  bool get hasReviews => totalReviews > 0;

  /// Получить округленный средний рейтинг
  double get roundedAverageRating => (averageRating * 10).round() / 10;

  @override
  String toString() =>
      'ReviewStats(average: $averageRating, total: $totalReviews)';
}

/// Фильтр для отзывов
class ReviewFilter {
  const ReviewFilter({
    this.minRating,
    this.maxRating,
    this.tags,
    this.verifiedOnly,
    this.withImages,
    this.withResponse,
    this.fromDate,
    this.toDate,
    this.searchQuery,
  });

  /// Создать пустой фильтр
  factory ReviewFilter.empty() => const ReviewFilter();

  /// Создать фильтр по рейтингу
  factory ReviewFilter.byRating(int rating) =>
      ReviewFilter(minRating: rating, maxRating: rating);

  /// Создать фильтр по диапазону рейтингов
  factory ReviewFilter.byRatingRange(int minRating, int maxRating) =>
      ReviewFilter(minRating: minRating, maxRating: maxRating);

  /// Создать фильтр по тегам
  factory ReviewFilter.byTags(List<String> tags) => ReviewFilter(tags: tags);

  /// Создать фильтр по дате
  factory ReviewFilter.byDateRange(DateTime fromDate, DateTime toDate) =>
      ReviewFilter(fromDate: fromDate, toDate: toDate);
  final int? minRating;
  final int? maxRating;
  final List<String>? tags;
  final bool? verifiedOnly;
  final bool? withImages;
  final bool? withResponse;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? searchQuery;

  /// Проверить, есть ли активные фильтры
  bool get hasActiveFilters =>
      minRating != null ||
      maxRating != null ||
      (tags != null && tags!.isNotEmpty) ||
      (verifiedOnly ?? false) ||
      (withImages ?? false) ||
      (withResponse ?? false) ||
      fromDate != null ||
      toDate != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  /// Сбросить все фильтры
  ReviewFilter clear() => const ReviewFilter();

  /// Применить фильтр по рейтингу
  ReviewFilter withRating(int? minRating, int? maxRating) => ReviewFilter(
        minRating: minRating ?? this.minRating,
        maxRating: maxRating ?? this.maxRating,
        tags: tags,
        verifiedOnly: verifiedOnly,
        withImages: withImages,
        withResponse: withResponse,
        fromDate: fromDate,
        toDate: toDate,
        searchQuery: searchQuery,
      );

  /// Применить фильтр по тегам
  ReviewFilter withTags(List<String>? tags) => ReviewFilter(
        minRating: minRating,
        maxRating: maxRating,
        tags: tags,
        verifiedOnly: verifiedOnly,
        withImages: withImages,
        withResponse: withResponse,
        fromDate: fromDate,
        toDate: toDate,
        searchQuery: searchQuery,
      );

  /// Применить поисковый запрос
  ReviewFilter withSearch(String? query) => ReviewFilter(
        minRating: minRating,
        maxRating: maxRating,
        tags: tags,
        verifiedOnly: verifiedOnly,
        withImages: withImages,
        withResponse: withResponse,
        fromDate: fromDate,
        toDate: toDate,
        searchQuery: query,
      );

  @override
  String toString() =>
      'ReviewFilter(minRating: $minRating, maxRating: $maxRating, tags: $tags, verifiedOnly: $verifiedOnly, withImages: $withImages, withResponse: $withResponse, fromDate: $fromDate, toDate: $toDate, searchQuery: $searchQuery)';
}
