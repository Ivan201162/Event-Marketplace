import 'package:cloud_firestore/cloud_firestore.dart';

/// Расширенная модель отзыва с поддержкой медиа и лайков
class ReviewExtended {
  const ReviewExtended({
    required this.id,
    required this.specialistId,
    required this.customerId,
    required this.customerName,
    required this.customerPhotoUrl,
    required this.bookingId,
    required this.rating,
    required this.comment,
    this.media = const [],
    this.likes = const [],
    this.tags = const [],
    required this.stats,
    this.isVerified = false,
    this.isModerated = false,
    this.isApproved = true,
    this.moderationComment,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory ReviewExtended.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return ReviewExtended(
      id: doc.id,
      specialistId: data['specialistId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhotoUrl: data['customerPhotoUrl'] as String? ?? '',
      bookingId: data['bookingId'] as String? ?? '',
      rating: data['rating'] as int? ?? 0,
      comment: data['comment'] as String? ?? '',
      media: (data['media'] as List<dynamic>?)
              ?.map((e) => ReviewMedia.fromMap(e))
              .toList() ??
          [],
      likes: (data['likes'] as List<dynamic>?)
              ?.map((e) => ReviewLike.fromMap(e))
              .toList() ??
          [],
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      stats: ReviewStats.fromMap(data['stats'] as Map<String, dynamic>? ?? {}),
      isVerified: data['isVerified'] as bool? ?? false,
      isModerated: data['isModerated'] as bool? ?? false,
      isApproved: data['isApproved'] as bool? ?? true,
      moderationComment: data['moderationComment'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String specialistId;
  final String customerId;
  final String customerName;
  final String customerPhotoUrl;
  final String bookingId;
  final int rating;
  final String comment;
  final List<ReviewMedia> media;
  final List<ReviewLike> likes;
  final List<String> tags;
  final ReviewStats stats;
  final bool isVerified;
  final bool isModerated;
  final bool isApproved;
  final String? moderationComment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'specialistId': specialistId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhotoUrl': customerPhotoUrl,
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
        'media': media.map((e) => e.toMap()).toList(),
        'likes': likes.map((e) => e.toMap()).toList(),
        'tags': tags,
        'stats': stats.toMap(),
        'isVerified': isVerified,
        'isModerated': isModerated,
        'isApproved': isApproved,
        'moderationComment': moderationComment,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'metadata': metadata,
      };

  ReviewExtended copyWith({
    String? id,
    String? specialistId,
    String? customerId,
    String? customerName,
    String? customerPhotoUrl,
    String? bookingId,
    int? rating,
    String? comment,
    List<ReviewMedia>? media,
    List<ReviewLike>? likes,
    List<String>? tags,
    ReviewStats? stats,
    bool? isVerified,
    bool? isModerated,
    bool? isApproved,
    String? moderationComment,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      ReviewExtended(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
        bookingId: bookingId ?? this.bookingId,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        media: media ?? this.media,
        likes: likes ?? this.likes,
        tags: tags ?? this.tags,
        stats: stats ?? this.stats,
        isVerified: isVerified ?? this.isVerified,
        isModerated: isModerated ?? this.isModerated,
        isApproved: isApproved ?? this.isApproved,
        moderationComment: moderationComment ?? this.moderationComment,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );

  /// Получить количество лайков
  int get likesCount => likes.length;

  /// Проверить, лайкнул ли пользователь отзыв
  bool isLikedBy(String userId) => likes.any((like) => like.userId == userId);

  /// Получить количество медиа файлов
  int get mediaCount => media.length;

  /// Получить фото
  List<ReviewMedia> get photos =>
      media.where((m) => m.type == MediaType.photo).toList();

  /// Получить видео
  List<ReviewMedia> get videos =>
      media.where((m) => m.type == MediaType.video).toList();
}

/// Медиа файл в отзыве
class ReviewMedia {
  const ReviewMedia({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.type,
    required this.fileName,
    required this.fileSize,
    this.duration,
    this.metadata = const {},
  });

  factory ReviewMedia.fromMap(Map<String, dynamic> map) => ReviewMedia(
        id: map['id'] ?? '',
        url: map['url'] ?? '',
        thumbnailUrl: map['thumbnailUrl'] ?? '',
        type: MediaType.values.firstWhere((t) => t.name == map['type'],
            orElse: () => MediaType.photo),
        fileName: map['fileName'] ?? '',
        fileSize: map['fileSize'] ?? 0,
        duration: map['duration'] != null
            ? Duration(milliseconds: map['duration'])
            : null,
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );
  final String id;
  final String url;
  final String thumbnailUrl;
  final MediaType type;
  final String fileName;
  final int fileSize;
  final Duration? duration;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'type': type.name,
        'fileName': fileName,
        'fileSize': fileSize,
        'duration': duration?.inMilliseconds,
        'metadata': metadata,
      };

  ReviewMedia copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    MediaType? type,
    String? fileName,
    int? fileSize,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) =>
      ReviewMedia(
        id: id ?? this.id,
        url: url ?? this.url,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        type: type ?? this.type,
        fileName: fileName ?? this.fileName,
        fileSize: fileSize ?? this.fileSize,
        duration: duration ?? this.duration,
        metadata: metadata ?? this.metadata,
      );
}

/// Тип медиа файла
enum MediaType { photo, video }

/// Лайк отзыва
class ReviewLike {
  const ReviewLike({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.createdAt,
  });

  factory ReviewLike.fromMap(Map<String, dynamic> map) => ReviewLike(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        userPhotoUrl: map['userPhotoUrl'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  ReviewLike copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    DateTime? createdAt,
  }) =>
      ReviewLike(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
        createdAt: createdAt ?? this.createdAt,
      );
}

/// Статистика отзыва
class ReviewStats {
  const ReviewStats({
    this.likesCount = 0,
    this.viewsCount = 0,
    this.sharesCount = 0,
    this.reportsCount = 0,
    this.helpfulnessScore = 0.0,
    this.ratingCounts = const {},
    this.tags = const [],
    this.quality = 0.0,
    this.communication = 0.0,
    this.punctuality = 0.0,
    this.value = 0.0,
  });

  factory ReviewStats.fromMap(Map<String, dynamic> map) => ReviewStats(
        likesCount: map['likesCount'] ?? 0,
        viewsCount: map['viewsCount'] ?? 0,
        sharesCount: map['sharesCount'] ?? 0,
        reportsCount: map['reportsCount'] ?? 0,
        helpfulnessScore: (map['helpfulnessScore'] ?? 0.0).toDouble(),
        ratingCounts: Map<String, int>.from(map['ratingCounts'] ?? {}),
        tags: List<String>.from(map['tags'] ?? []),
        quality: (map['quality'] ?? 0.0).toDouble(),
        communication: (map['communication'] ?? 0.0).toDouble(),
        punctuality: (map['punctuality'] ?? 0.0).toDouble(),
        value: (map['value'] ?? 0.0).toDouble(),
      );
  final int likesCount;
  final int viewsCount;
  final int sharesCount;
  final int reportsCount;
  final double helpfulnessScore;
  final Map<String, int> ratingCounts;
  final List<String> tags;
  final double quality;
  final double communication;
  final double punctuality;
  final double value;

  Map<String, dynamic> toMap() => {
        'likesCount': likesCount,
        'viewsCount': viewsCount,
        'sharesCount': sharesCount,
        'reportsCount': reportsCount,
        'helpfulnessScore': helpfulnessScore,
        'ratingCounts': ratingCounts,
        'tags': tags,
        'quality': quality,
        'communication': communication,
        'punctuality': punctuality,
        'value': value,
      };

  ReviewStats copyWith({
    int? likesCount,
    int? viewsCount,
    int? sharesCount,
    int? reportsCount,
    double? helpfulnessScore,
    Map<String, int>? ratingCounts,
    List<String>? tags,
    double? quality,
    double? communication,
    double? punctuality,
    double? value,
  }) =>
      ReviewStats(
        likesCount: likesCount ?? this.likesCount,
        viewsCount: viewsCount ?? this.viewsCount,
        sharesCount: sharesCount ?? this.sharesCount,
        reportsCount: reportsCount ?? this.reportsCount,
        helpfulnessScore: helpfulnessScore ?? this.helpfulnessScore,
        ratingCounts: ratingCounts ?? this.ratingCounts,
        tags: tags ?? this.tags,
        quality: quality ?? this.quality,
        communication: communication ?? this.communication,
        punctuality: punctuality ?? this.punctuality,
        value: value ?? this.value,
      );
}

/// Фильтр для отзывов
class ReviewFilter {
  const ReviewFilter({
    this.minRating,
    this.maxRating,
    this.hasMedia,
    this.isVerified,
    this.tags,
    this.startDate,
    this.endDate,
    this.sortBy = ReviewSortBy.date,
    this.sortAscending = false,
  });
  final int? minRating;
  final int? maxRating;
  final bool? hasMedia;
  final bool? isVerified;
  final List<String>? tags;
  final DateTime? startDate;
  final DateTime? endDate;
  final ReviewSortBy sortBy;
  final bool sortAscending;

  ReviewFilter copyWith({
    int? minRating,
    int? maxRating,
    bool? hasMedia,
    bool? isVerified,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    ReviewSortBy? sortBy,
    bool? sortAscending,
  }) =>
      ReviewFilter(
        minRating: minRating ?? this.minRating,
        maxRating: maxRating ?? this.maxRating,
        hasMedia: hasMedia ?? this.hasMedia,
        isVerified: isVerified ?? this.isVerified,
        tags: tags ?? this.tags,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        sortBy: sortBy ?? this.sortBy,
        sortAscending: sortAscending ?? this.sortAscending,
      );
}

/// Сортировка отзывов
enum ReviewSortBy { date, rating, likes, helpfulness }

/// Статистика отзывов специалиста
class SpecialistReviewStats {
  const SpecialistReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.totalLikes,
    required this.totalViews,
    required this.averageHelpfulness,
    required this.topTags,
    required this.categoryRatings,
  });

  factory SpecialistReviewStats.empty() => const SpecialistReviewStats(
        averageRating: 0,
        totalReviews: 0,
        ratingDistribution: {},
        totalLikes: 0,
        totalViews: 0,
        averageHelpfulness: 0,
        topTags: [],
        categoryRatings: {},
      );

  factory SpecialistReviewStats.fromMap(Map<String, dynamic> map) =>
      SpecialistReviewStats(
        averageRating: (map['averageRating'] ?? 0.0).toDouble(),
        totalReviews: map['totalReviews'] ?? 0,
        ratingDistribution: Map<int, int>.from(map['ratingDistribution'] ?? {}),
        totalLikes: map['totalLikes'] ?? 0,
        totalViews: map['totalViews'] ?? 0,
        averageHelpfulness: (map['averageHelpfulness'] ?? 0.0).toDouble(),
        topTags: List<String>.from(map['topTags'] ?? []),
        categoryRatings: Map<String, double>.from(map['categoryRatings'] ?? {}),
      );
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final int totalLikes;
  final int totalViews;
  final double averageHelpfulness;
  final List<String> topTags;
  final Map<String, double> categoryRatings;

  Map<String, dynamic> toMap() => {
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'ratingDistribution': ratingDistribution,
        'totalLikes': totalLikes,
        'totalViews': totalViews,
        'averageHelpfulness': averageHelpfulness,
        'topTags': topTags,
        'categoryRatings': categoryRatings,
      };
}
