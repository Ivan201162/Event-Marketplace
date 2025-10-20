import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус отзыва
enum ReviewStatus {
  pending,
  approved,
  rejected,
  hidden,
}

/// Модель отзыва
class Review {
  const Review({
    required this.id,
    required this.reviewerId,
    required this.specialistId,
    required this.rating,
    this.comment,
    this.title,
    this.images = const [],
    this.videos = const [],
    this.tags = const [],
    this.status = ReviewStatus.pending,
    this.isVerified = false,
    this.isHelpful = 0,
    this.isNotHelpful = 0,
    this.reported = false,
    this.reportReason,
    this.response,
    this.responseDate,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String reviewerId;
  final String specialistId;
  final double rating;
  final String? comment;
  final String? title;
  final List<String> images;
  final List<String> videos;
  final List<String> tags;
  final ReviewStatus status;
  final bool isVerified;
  final int isHelpful;
  final int isNotHelpful;
  final bool reported;
  final String? reportReason;
  final String? response;
  final DateTime? responseDate;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Создать из Map
  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      id: data['id'] as String? ?? '',
      reviewerId: data['reviewerId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      title: data['title'] as String?,
      images: List<String>.from(data['images'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      status: _parseStatus(data['status']),
      isVerified: data['isVerified'] as bool? ?? false,
      isHelpful: data['isHelpful'] as int? ?? 0,
      isNotHelpful: data['isNotHelpful'] as int? ?? 0,
      reported: data['reported'] as bool? ?? false,
      reportReason: data['reportReason'] as String?,
      response: data['response'] as String?,
      responseDate: data['responseDate'] != null
          ? (data['responseDate'] is Timestamp
              ? (data['responseDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['responseDate'].toString()))
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Review.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'reviewerId': reviewerId,
        'specialistId': specialistId,
        'rating': rating,
        'comment': comment,
        'title': title,
        'images': images,
        'videos': videos,
        'tags': tags,
        'status': status.name,
        'isVerified': isVerified,
        'isHelpful': isHelpful,
        'isNotHelpful': isNotHelpful,
        'reported': reported,
        'reportReason': reportReason,
        'response': response,
        'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  Review copyWith({
    String? id,
    String? reviewerId,
    String? specialistId,
    double? rating,
    String? comment,
    String? title,
    List<String>? images,
    List<String>? videos,
    List<String>? tags,
    ReviewStatus? status,
    bool? isVerified,
    int? isHelpful,
    int? isNotHelpful,
    bool? reported,
    String? reportReason,
    String? response,
    DateTime? responseDate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Review(
        id: id ?? this.id,
        reviewerId: reviewerId ?? this.reviewerId,
        specialistId: specialistId ?? this.specialistId,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        title: title ?? this.title,
        images: images ?? this.images,
        videos: videos ?? this.videos,
        tags: tags ?? this.tags,
        status: status ?? this.status,
        isVerified: isVerified ?? this.isVerified,
        isHelpful: isHelpful ?? this.isHelpful,
        isNotHelpful: isNotHelpful ?? this.isNotHelpful,
        reported: reported ?? this.reported,
        reportReason: reportReason ?? this.reportReason,
        response: response ?? this.response,
        responseDate: responseDate ?? this.responseDate,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг статуса из строки
  static ReviewStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return ReviewStatus.pending;
      case 'approved':
        return ReviewStatus.approved;
      case 'rejected':
        return ReviewStatus.rejected;
      case 'hidden':
        return ReviewStatus.hidden;
      default:
        return ReviewStatus.pending;
    }
  }

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case ReviewStatus.pending:
        return 'Ожидает';
      case ReviewStatus.approved:
        return 'Одобрен';
      case ReviewStatus.rejected:
        return 'Отклонен';
      case ReviewStatus.hidden:
        return 'Скрыт';
    }
  }

  /// Проверить, одобрен ли отзыв
  bool get isApproved => status == ReviewStatus.approved;

  /// Проверить, ожидает ли отзыв
  bool get isPending => status == ReviewStatus.pending;

  /// Проверить, отклонен ли отзыв
  bool get isRejected => status == ReviewStatus.rejected;

  /// Проверить, скрыт ли отзыв
  bool get isHidden => status == ReviewStatus.hidden;

  /// Проверить, есть ли комментарий
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Проверить, есть ли заголовок
  bool get hasTitle => title != null && title!.isNotEmpty;

  /// Проверить, есть ли изображения
  bool get hasImages => images.isNotEmpty;

  /// Проверить, есть ли видео
  bool get hasVideos => videos.isNotEmpty;

  /// Проверить, есть ли теги
  bool get hasTags => tags.isNotEmpty;

  /// Проверить, есть ли ответ
  bool get hasResponse => response != null && response!.isNotEmpty;

  /// Проверить, есть ли жалоба
  bool get hasReport => reported;

  /// Получить общее количество оценок полезности
  int get totalHelpfulness => isHelpful + isNotHelpful;

  /// Получить процент полезности
  double get helpfulnessPercentage {
    if (totalHelpfulness == 0) return 0.0;
    return (isHelpful / totalHelpfulness) * 100;
  }

  /// Получить отформатированную оценку
  String get formattedRating {
    return '${rating.toStringAsFixed(1)}/5.0';
  }

  /// Получить отформатированный процент полезности
  String get formattedHelpfulness {
    return '${helpfulnessPercentage.toStringAsFixed(0)}%';
  }

  /// Получить звезды для отображения
  List<bool> get stars {
    final stars = <bool>[];
    for (int i = 1; i <= 5; i++) {
      stars.add(i <= rating);
    }
    return stars;
  }
}

/// Модель статистики отзывов
class ReviewStats {
  const ReviewStats({
    required this.specialistId,
    this.totalReviews = 0,
    this.averageRating = 0.0,
    this.ratingDistribution = const {},
    this.verifiedReviews = 0,
    this.recentReviews = 0,
    this.helpfulReviews = 0,
    this.reportedReviews = 0,
    this.responseRate = 0.0,
    this.period,
    this.metadata = const {},
  });

  final String specialistId;
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution;
  final int verifiedReviews;
  final int recentReviews;
  final int helpfulReviews;
  final int reportedReviews;
  final double responseRate;
  final String? period;
  final Map<String, dynamic> metadata;

  /// Создать из Map
  factory ReviewStats.fromMap(Map<String, dynamic> data) {
    return ReviewStats(
      specialistId: data['specialistId'] as String? ?? '',
      totalReviews: data['totalReviews'] as int? ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {}),
      verifiedReviews: data['verifiedReviews'] as int? ?? 0,
      recentReviews: data['recentReviews'] as int? ?? 0,
      helpfulReviews: data['helpfulReviews'] as int? ?? 0,
      reportedReviews: data['reportedReviews'] as int? ?? 0,
      responseRate: (data['responseRate'] as num?)?.toDouble() ?? 0.0,
      period: data['period'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
        'verifiedReviews': verifiedReviews,
        'recentReviews': recentReviews,
        'helpfulReviews': helpfulReviews,
        'reportedReviews': reportedReviews,
        'responseRate': responseRate,
        'period': period,
        'metadata': metadata,
      };

  /// Копировать с изменениями
  ReviewStats copyWith({
    String? specialistId,
    int? totalReviews,
    double? averageRating,
    Map<int, int>? ratingDistribution,
    int? verifiedReviews,
    int? recentReviews,
    int? helpfulReviews,
    int? reportedReviews,
    double? responseRate,
    String? period,
    Map<String, dynamic>? metadata,
  }) =>
      ReviewStats(
        specialistId: specialistId ?? this.specialistId,
        totalReviews: totalReviews ?? this.totalReviews,
        averageRating: averageRating ?? this.averageRating,
        ratingDistribution: ratingDistribution ?? this.ratingDistribution,
        verifiedReviews: verifiedReviews ?? this.verifiedReviews,
        recentReviews: recentReviews ?? this.recentReviews,
        helpfulReviews: helpfulReviews ?? this.helpfulReviews,
        reportedReviews: reportedReviews ?? this.reportedReviews,
        responseRate: responseRate ?? this.responseRate,
        period: period ?? this.period,
        metadata: metadata ?? this.metadata,
      );

  /// Получить процент верифицированных отзывов
  double get verifiedPercentage {
    if (totalReviews == 0) return 0.0;
    return (verifiedReviews / totalReviews) * 100;
  }

  /// Получить процент недавних отзывов
  double get recentPercentage {
    if (totalReviews == 0) return 0.0;
    return (recentReviews / totalReviews) * 100;
  }

  /// Получить процент полезных отзывов
  double get helpfulPercentage {
    if (totalReviews == 0) return 0.0;
    return (helpfulReviews / totalReviews) * 100;
  }

  /// Получить процент жалоб
  double get reportedPercentage {
    if (totalReviews == 0) return 0.0;
    return (reportedReviews / totalReviews) * 100;
  }

  /// Получить отформатированную среднюю оценку
  String get formattedAverageRating {
    return '${averageRating.toStringAsFixed(1)}/5.0';
  }

  /// Получить отформатированный процент ответов
  String get formattedResponseRate {
    return '${responseRate.toStringAsFixed(0)}%';
  }

  /// Получить отформатированный процент верификации
  String get formattedVerifiedPercentage {
    return '${verifiedPercentage.toStringAsFixed(0)}%';
  }

  /// Получить отформатированный процент полезности
  String get formattedHelpfulPercentage {
    return '${helpfulPercentage.toStringAsFixed(0)}%';
  }

  /// Получить распределение оценок в процентах
  Map<int, double> get ratingDistributionPercentage {
    final distribution = <int, double>{};
    for (final int rating in ratingDistribution.keys) {
      distribution[rating] = (ratingDistribution[rating]! / totalReviews) * 100;
    }
    return distribution;
  }

  /// Получить отформатированное распределение оценок
  Map<int, String> get formattedRatingDistribution {
    final distribution = <int, String>{};
    for (final int rating in ratingDistribution.keys) {
      distribution[rating] = '${ratingDistribution[rating]} (${((ratingDistribution[rating]! / totalReviews) * 100).toStringAsFixed(0)}%)';
    }
    return distribution;
  }
}
