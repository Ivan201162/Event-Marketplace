import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип отзыва
enum ReviewType {
  specialist,
  event,
  service,
}

/// Модель отзыва с расширенным функционалом
class Review {
  const Review({
    required this.id,
    required this.specialistId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.text,
    this.serviceTags = const [],
    required this.date,
    this.photos = const [],
    this.likes = 0,
    this.responses = const [],
    this.bookingId, // Связь с заказом
    this.eventTitle, // Название события
    this.editedAt, // Дата редактирования
    this.isEdited = false, // Флаг редактирования
    this.isDeleted = false, // Флаг удаления
    this.customerAvatar, // Аватар заказчика
    this.specialistName, // Имя специалиста
    this.metadata = const {}, // Дополнительные данные
    this.reportCount = 0, // Количество жалоб
    this.isReported = false, // Флаг жалобы
    this.isVerified = false, // Верифицированный отзыв
  });

  /// Создать отзыв из Map
  factory Review.fromMap(Map<String, dynamic> data) => Review(
        id: data['id'] ?? '',
        specialistId: data['specialistId'] ?? '',
        customerId: data['customerId'] ?? '',
        customerName: data['customerName'] ?? '',
        rating: data['rating'] as double? ?? 0.0,
        text: data['text'] ?? '',
        serviceTags: List<String>.from(data['serviceTags'] ?? []),
        date: data['date'] != null
            ? (data['date'] is Timestamp
                ? (data['date'] as Timestamp).toDate()
                : DateTime.parse(data['date'].toString()))
            : DateTime.now(),
        photos: List<String>.from(data['photos'] ?? []),
        likes: data['likes'] as int? ?? 0,
        responses: (data['responses'] as List<dynamic>?)
                ?.map((response) => ReviewResponse.fromMap(response))
                .toList() ??
            [],
        bookingId: data['bookingId'] as String?,
        eventTitle: data['eventTitle'] as String?,
        editedAt: data['editedAt'] != null
            ? (data['editedAt'] is Timestamp
                ? (data['editedAt'] as Timestamp).toDate()
                : DateTime.parse(data['editedAt'].toString()))
            : null,
        isEdited: data['isEdited'] as bool? ?? false,
        isDeleted: data['isDeleted'] as bool? ?? false,
        customerAvatar: data['customerAvatar'] as String?,
        specialistName: data['specialistName'] as String?,
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        reportCount: data['reportCount'] as int? ?? 0,
        isReported: data['isReported'] as bool? ?? false,
        isVerified: data['isVerified'] as bool? ?? false,
      );

  /// Создать отзыв из документа Firestore
  factory Review.fromDocument(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    // Безопасное преобразование данных
    Map<String, dynamic> safeData;
    if (data is Map<String, dynamic>) {
      safeData = data;
    } else if (data is Map<dynamic, dynamic>) {
      safeData = data.map((key, value) => MapEntry(key.toString(), value));
    } else {
      throw Exception('Document data is not a Map: ${data.runtimeType}');
    }

    return Review(
      id: doc.id,
      specialistId: safeData['specialistId'] ?? '',
      customerId: safeData['customerId'] ?? '',
      customerName: safeData['customerName'] ?? '',
      rating: safeData['rating'] as double? ?? 0.0,
      text: safeData['text'] ?? '',
      serviceTags: List<String>.from(safeData['serviceTags'] ?? []),
      date: safeData['date'] != null
          ? (safeData['date'] is Timestamp
              ? (safeData['date'] as Timestamp).toDate()
              : DateTime.parse(safeData['date'].toString()))
          : DateTime.now(),
      photos: List<String>.from(safeData['photos'] ?? []),
      likes: safeData['likes'] as int? ?? 0,
      responses: (safeData['responses'] as List<dynamic>?)
              ?.map((response) => ReviewResponse.fromMap(response))
              .toList() ??
          [],
      bookingId: safeData['bookingId'] as String?,
      eventTitle: safeData['eventTitle'] as String?,
      editedAt: safeData['editedAt'] != null
          ? (safeData['editedAt'] is Timestamp
              ? (safeData['editedAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['editedAt'].toString()))
          : null,
      isEdited: safeData['isEdited'] as bool? ?? false,
      isDeleted: safeData['isDeleted'] as bool? ?? false,
      customerAvatar: safeData['customerAvatar'] as String?,
      specialistName: safeData['specialistName'] as String?,
      metadata: Map<String, dynamic>.from(safeData['metadata'] ?? {}),
      reportCount: safeData['reportCount'] as int? ?? 0,
      isReported: safeData['isReported'] as bool? ?? false,
      isVerified: safeData['isVerified'] as bool? ?? false,
    );
  }

  final String id;
  final String specialistId;
  final String customerId;
  final String customerName;
  final double rating; // 1-5 звезд
  final String text;
  final List<String> serviceTags;
  final DateTime date;
  final List<String> photos;
  final int likes;
  final List<ReviewResponse> responses;
  final String? bookingId; // Связь с заказом
  final String? eventTitle; // Название события
  final DateTime? editedAt; // Дата редактирования
  final bool isEdited; // Флаг редактирования
  final bool isDeleted; // Флаг удаления
  final String? customerAvatar; // Аватар заказчика
  final String? specialistName; // Имя специалиста
  final Map<String, dynamic> metadata; // Дополнительные данные
  final int reportCount; // Количество жалоб
  final bool isReported; // Флаг жалобы
  final bool isVerified; // Верифицированный отзыв

  // Дополнительные методы для совместимости
  bool get hasComment => text.isNotEmpty;
  DateTime? get updatedAt => editedAt;
  DateTime get createdAt => date;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'text': text,
        'serviceTags': serviceTags,
        'date': Timestamp.fromDate(date),
        'photos': photos,
        'likes': likes,
        'responses': responses.map((response) => response.toMap()).toList(),
        'bookingId': bookingId,
        'eventTitle': eventTitle,
        'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
        'isEdited': isEdited,
        'isDeleted': isDeleted,
        'customerAvatar': customerAvatar,
        'specialistName': specialistName,
        'metadata': metadata,
        'reportCount': reportCount,
        'isReported': isReported,
        'isVerified': isVerified,
      };

  /// Копировать с изменениями
  Review copyWith({
    String? id,
    String? specialistId,
    String? customerId,
    String? customerName,
    double? rating,
    String? text,
    List<String>? serviceTags,
    DateTime? date,
    List<String>? photos,
    int? likes,
    List<ReviewResponse>? responses,
    String? bookingId,
    String? eventTitle,
    DateTime? editedAt,
    bool? isEdited,
    bool? isDeleted,
    String? customerAvatar,
    String? specialistName,
    Map<String, dynamic>? metadata,
    int? reportCount,
    bool? isReported,
    bool? isVerified,
  }) =>
      Review(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        rating: rating ?? this.rating,
        text: text ?? this.text,
        serviceTags: serviceTags ?? this.serviceTags,
        date: date ?? this.date,
        photos: photos ?? this.photos,
        likes: likes ?? this.likes,
        responses: responses ?? this.responses,
        bookingId: bookingId ?? this.bookingId,
        eventTitle: eventTitle ?? this.eventTitle,
        editedAt: editedAt ?? this.editedAt,
        isEdited: isEdited ?? this.isEdited,
        isDeleted: isDeleted ?? this.isDeleted,
        customerAvatar: customerAvatar ?? this.customerAvatar,
        specialistName: specialistName ?? this.specialistName,
        metadata: metadata ?? this.metadata,
        reportCount: reportCount ?? this.reportCount,
        isReported: isReported ?? this.isReported,
        isVerified: isVerified ?? this.isVerified,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Получить заголовок отзыва
  String get title => eventTitle ?? 'Отзыв';

  /// Получить теги сервиса
  List<String> get tags => serviceTags;

  @override
  String toString() =>
      'Review(id: $id, specialistId: $specialistId, rating: $rating)';

  /// Проверить, можно ли редактировать отзыв (в течение 24 часов)
  bool get canEdit {
    if (isDeleted) return false;
    final now = DateTime.now();
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < 24;
  }

  /// Проверить, можно ли удалить отзыв (в течение 24 часов)
  bool get canDelete {
    if (isDeleted) return false;
    final now = DateTime.now();
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < 24;
  }

  /// Проверить, есть ли ответ специалиста
  bool get hasResponse => response != null && response!.isNotEmpty;

  /// Получить отформатированную дату создания
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  /// Получить отформатированную дату редактирования
  String? get formattedEditedAt {
    if (editedAt == null) return null;
    final now = DateTime.now();
    final difference = now.difference(editedAt!);

    if (difference.inDays > 0) {
      return 'отредактировано ${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return 'отредактировано ${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return 'отредактировано ${difference.inMinutes} мин. назад';
    } else {
      return 'отредактировано только что';
    }
  }

  /// Получить звезды рейтинга как строку
  String get ratingStars => '★' * rating + '☆' * (5 - rating);

  /// Получить цвет рейтинга
  String get ratingColor {
    if (rating >= 4) return 'green';
    if (rating >= 3) return 'orange';
    return 'red';
  }

  /// Проверить, есть ли комментарий
  bool get hasComment => text.isNotEmpty;

  /// Проверить, верифицирован ли отзыв (из метаданных)
  bool get isVerifiedFromMetadata => metadata['isVerified'] == true;

  /// Проверить, публичный ли отзыв
  bool get isPublic => metadata['isPublic'] != false;

  /// Проверить валидность рейтинга
  bool isValidRating(int rating) => rating >= 1 && rating <= 5;

  /// Проверить валидность комментария
  bool isValidComment(String comment) =>
      comment.isNotEmpty && comment.length >= 10;

  /// Проверить, можно ли пожаловаться на отзыв
  bool canReport() => !isDeleted && !metadata['reported'] == true;
}

/// Статистика отзывов специалиста
class ReviewStats {
  const ReviewStats({
    required this.specialistId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.lastUpdated,
    this.tags = const [],
  });

  factory ReviewStats.fromMap(Map<String, dynamic> map) => ReviewStats(
        specialistId: map['specialistId'] ?? '',
        averageRating: (map['averageRating'] ?? 0.0).toDouble(),
        totalReviews: map['totalReviews'] ?? 0,
        ratingDistribution:
            Map<String, int>.from(map['ratingDistribution'] ?? {}),
        lastUpdated: map['lastUpdated'] != null
            ? (map['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
        tags: List<String>.from(map['tags'] ?? []),
      );

  final String specialistId;
  final double averageRating;
  final int totalReviews;
  final Map<String, int> ratingDistribution;
  final DateTime lastUpdated;
  final List<String> tags;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'ratingDistribution': ratingDistribution,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
        'tags': tags,
      };

  /// Получить процент рейтинга
  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0;
    final count = ratingDistribution[rating.toString()] ?? 0;
    return (count / totalReviews) * 100;
  }
}

/// Модель ответа на отзыв
class ReviewResponse {
  const ReviewResponse({
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.date,
  });

  factory ReviewResponse.fromMap(Map<String, dynamic> data) => ReviewResponse(
        authorId: data['authorId'] ?? '',
        authorName: data['authorName'] ?? '',
        text: data['text'] ?? '',
        date: data['date'] != null
            ? (data['date'] is Timestamp
                ? (data['date'] as Timestamp).toDate()
                : DateTime.parse(data['date'].toString()))
            : DateTime.now(),
      );
  final String authorId;
  final String authorName;
  final String text;
  final DateTime date;

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'text': text,
        'date': Timestamp.fromDate(date),
      };
}

/// Модель лайка отзыва
class ReviewLike {
  const ReviewLike({
    required this.userId,
    required this.userName,
    required this.date,
  });

  factory ReviewLike.fromMap(Map<String, dynamic> data) => ReviewLike(
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? '',
        date: data['date'] != null
            ? (data['date'] is Timestamp
                ? (data['date'] as Timestamp).toDate()
                : DateTime.parse(data['date'].toString()))
            : DateTime.now(),
      );
  final String userId;
  final String userName;
  final DateTime date;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'date': Timestamp.fromDate(date),
      };
}

/// Модель жалобы на отзыв
class ReviewReport {
  const ReviewReport({
    required this.id,
    required this.reviewId,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    this.description,
    required this.date,
    this.isResolved = false,
    this.moderatorNote,
  });

  factory ReviewReport.fromMap(Map<String, dynamic> data) => ReviewReport(
        id: data['id'] ?? '',
        reviewId: data['reviewId'] ?? '',
        reporterId: data['reporterId'] ?? '',
        reporterName: data['reporterName'] ?? '',
        reason: data['reason'] ?? '',
        description: data['description'] as String?,
        date: data['date'] != null
            ? (data['date'] is Timestamp
                ? (data['date'] as Timestamp).toDate()
                : DateTime.parse(data['date'].toString()))
            : DateTime.now(),
        isResolved: data['isResolved'] as bool? ?? false,
        moderatorNote: data['moderatorNote'] as String?,
      );
  final String id;
  final String reviewId;
  final String reporterId;
  final String reporterName;
  final String reason;
  final String? description;
  final DateTime date;
  final bool isResolved;
  final String? moderatorNote;

  Map<String, dynamic> toMap() => {
        'id': id,
        'reviewId': reviewId,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reason': reason,
        'description': description,
        'date': Timestamp.fromDate(date),
        'isResolved': isResolved,
        'moderatorNote': moderatorNote,
      };
}

/// Причины жалоб на отзывы
enum ReviewReportReason {
  spam('spam', 'Спам'),
  inappropriate('inappropriate', 'Неподходящий контент'),
  fake('fake', 'Поддельный отзыв'),
  harassment('harassment', 'Оскорбления'),
  other('other', 'Другое');

  const ReviewReportReason(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// Модель статистики репутации специалиста
class SpecialistReputation {
  const SpecialistReputation({
    required this.specialistId,
    required this.ratingAverage,
    required this.reviewsCount,
    required this.positiveReviews,
    required this.negativeReviews,
    required this.reputationScore,
    required this.status,
    required this.lastUpdated,
  });

  factory SpecialistReputation.fromMap(Map<String, dynamic> data) =>
      SpecialistReputation(
        specialistId: data['specialistId'] ?? '',
        ratingAverage: data['ratingAverage'] as double? ?? 0.0,
        reviewsCount: data['reviewsCount'] as int? ?? 0,
        positiveReviews: data['positiveReviews'] as int? ?? 0,
        negativeReviews: data['negativeReviews'] as int? ?? 0,
        reputationScore: data['reputationScore'] as double? ?? 0.0,
        status: ReputationStatus.values.firstWhere(
          (status) => status.value == data['status'],
          orElse: () => ReputationStatus.needsExperience,
        ),
        lastUpdated: data['lastUpdated'] != null
            ? (data['lastUpdated'] is Timestamp
                ? (data['lastUpdated'] as Timestamp).toDate()
                : DateTime.parse(data['lastUpdated'].toString()))
            : DateTime.now(),
      );
  final String specialistId;
  final double ratingAverage;
  final int reviewsCount;
  final int positiveReviews;
  final int negativeReviews;
  final double reputationScore;
  final ReputationStatus status;
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'ratingAverage': ratingAverage,
        'reviewsCount': reviewsCount,
        'positiveReviews': positiveReviews,
        'negativeReviews': negativeReviews,
        'reputationScore': reputationScore,
        'status': status.value,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  /// Рассчитать репутационный балл
  static double calculateReputationScore(int positive, int negative) {
    final total = positive + negative;
    if (total == 0) return 0;
    return (positive / total) * 100;
  }

  /// Определить статус репутации
  static ReputationStatus getReputationStatus(double score) {
    if (score >= 90) return ReputationStatus.verifiedExpert;
    if (score >= 75) return ReputationStatus.reliable;
    if (score >= 50) return ReputationStatus.needsExperience;
    return ReputationStatus.underObservation;
  }
}

/// Статусы репутации специалиста
enum ReputationStatus {
  verifiedExpert('verified_expert', 'Проверенный эксперт', '🏆'),
  reliable('reliable', 'Надёжный', '⭐'),
  needsExperience('needs_experience', 'Нуждается в опыте', '⚙️'),
  underObservation('under_observation', 'Под наблюдением', '⚠️');

  const ReputationStatus(this.value, this.displayName, this.emoji);
  final String value;
  final String displayName;
  final String emoji;
}
