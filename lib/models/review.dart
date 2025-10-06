import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип отзыва
enum ReviewType {
  specialist,
  event,
  service,
}

/// Модель отзыва
class Review {
  const Review({
    required this.id,
    required this.specialistId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    this.serviceTags = const [],
    required this.createdAt,
    this.bookingId, // Связь с заказом
    this.eventTitle, // Название события
    this.editedAt, // Дата редактирования
    this.isEdited = false, // Флаг редактирования
    this.isDeleted = false, // Флаг удаления
    this.customerAvatar, // Аватар заказчика
    this.specialistName, // Имя специалиста
    this.response, // Ответ специалиста на отзыв
    this.responseAt, // Дата ответа
    this.metadata = const {}, // Дополнительные данные
  });

  /// Создать отзыв из Map
  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      id: data['id'] ?? '',
      specialistId: data['specialistId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      rating: data['rating'] as int? ?? 0,
      comment: data['comment'] ?? '',
      serviceTags: List<String>.from(data['serviceTags'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
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
      response: data['response'] as String?,
      responseAt: data['responseAt'] != null
          ? (data['responseAt'] is Timestamp
              ? (data['responseAt'] as Timestamp).toDate()
              : DateTime.parse(data['responseAt'].toString()))
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

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
      rating: safeData['rating'] as int? ?? 0,
      comment: safeData['comment'] ?? '',
      serviceTags: List<String>.from(safeData['serviceTags'] ?? []),
      createdAt: safeData['createdAt'] != null
          ? (safeData['createdAt'] is Timestamp
              ? (safeData['createdAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['createdAt'].toString()))
          : DateTime.now(),
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
      response: safeData['response'] as String?,
      responseAt: safeData['responseAt'] != null
          ? (safeData['responseAt'] is Timestamp
              ? (safeData['responseAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['responseAt'].toString()))
          : null,
      metadata: Map<String, dynamic>.from(safeData['metadata'] ?? {}),
    );
  }

  final String id;
  final String specialistId;
  final String customerId;
  final String customerName;
  final int rating; // 1-5 звезд
  final String comment;
  final List<String> serviceTags;
  final DateTime createdAt;
  final String? bookingId; // Связь с заказом
  final String? eventTitle; // Название события
  final DateTime? editedAt; // Дата редактирования
  final bool isEdited; // Флаг редактирования
  final bool isDeleted; // Флаг удаления
  final String? customerAvatar; // Аватар заказчика
  final String? specialistName; // Имя специалиста
  final String? response; // Ответ специалиста на отзыв
  final DateTime? responseAt; // Дата ответа
  final Map<String, dynamic> metadata; // Дополнительные данные

  // Дополнительные методы для совместимости
  bool get hasComment => comment.isNotEmpty;
  DateTime? get updatedAt => editedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'serviceTags': serviceTags,
        'createdAt': Timestamp.fromDate(createdAt),
        'bookingId': bookingId,
        'eventTitle': eventTitle,
        'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
        'isEdited': isEdited,
        'isDeleted': isDeleted,
        'customerAvatar': customerAvatar,
        'specialistName': specialistName,
        'response': response,
        'responseAt':
            responseAt != null ? Timestamp.fromDate(responseAt!) : null,
        'metadata': metadata,
      };

  /// Копировать с изменениями
  Review copyWith({
    String? id,
    String? specialistId,
    String? customerId,
    String? customerName,
    int? rating,
    String? comment,
    List<String>? serviceTags,
    DateTime? createdAt,
    String? bookingId,
    String? eventTitle,
    DateTime? editedAt,
    bool? isEdited,
    bool? isDeleted,
    String? customerAvatar,
    String? specialistName,
    String? response,
    DateTime? responseAt,
    Map<String, dynamic>? metadata,
  }) =>
      Review(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        serviceTags: serviceTags ?? this.serviceTags,
        createdAt: createdAt ?? this.createdAt,
        bookingId: bookingId ?? this.bookingId,
        eventTitle: eventTitle ?? this.eventTitle,
        editedAt: editedAt ?? this.editedAt,
        isEdited: isEdited ?? this.isEdited,
        isDeleted: isDeleted ?? this.isDeleted,
        customerAvatar: customerAvatar ?? this.customerAvatar,
        specialistName: specialistName ?? this.specialistName,
        response: response ?? this.response,
        responseAt: responseAt ?? this.responseAt,
        metadata: metadata ?? this.metadata,
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
  bool get hasComment => comment.isNotEmpty;

  /// Проверить, верифицирован ли отзыв
  bool get isVerified => metadata['isVerified'] == true;

  /// Проверить, публичный ли отзыв
  bool get isPublic => metadata['isPublic'] != false;

  /// Проверить валидность рейтинга
  bool isValidRating(int rating) => rating >= 1 && rating <= 5;

  /// Проверить валидность комментария
  bool isValidComment(String comment) => comment.isNotEmpty && comment.length >= 10;

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
