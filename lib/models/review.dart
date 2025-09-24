import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отзыва
class Review {
  final String id;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final double rating; // 1-5
  final String comment;
  final List<String> tags; // Теги для категоризации
  final bool isVerified; // Проверен ли отзыв
  final bool isModerated; // Прошел ли модерацию
  final String? moderatorId; // ID модератора
  final String? moderatorComment; // Комментарий модератора
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? moderatedAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.rating,
    required this.comment,
    this.tags = const [],
    this.isVerified = false,
    this.isModerated = true, // По умолчанию прошел модерацию
    this.moderatorId,
    this.moderatorComment,
    required this.createdAt,
    this.updatedAt,
    this.moderatedAt,
  });

  /// Создать из документа Firestore
  factory Review.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Review(
      id: doc.id,
      bookingId: data['bookingId'] as String,
      customerId: data['customerId'] as String,
      specialistId: data['specialistId'] as String,
      rating: (data['rating'] as num).toDouble(),
      comment: data['comment'] as String,
      tags: List<String>.from(data['tags'] ?? []),
      isVerified: data['isVerified'] as bool? ?? false,
      isModerated: data['isModerated'] as bool? ?? true,
      moderatorId: data['moderatorId'] as String?,
      moderatorComment: data['moderatorComment'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      moderatedAt: data['moderatedAt'] != null 
          ? (data['moderatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'specialistId': specialistId,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'isVerified': isVerified,
      'isModerated': isModerated,
      'moderatorId': moderatorId,
      'moderatorComment': moderatorComment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'moderatedAt': moderatedAt != null ? Timestamp.fromDate(moderatedAt!) : null,
    };
  }

  /// Создать копию с изменениями
  Review copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? specialistId,
    double? rating,
    String? comment,
    List<String>? tags,
    bool? isVerified,
    bool? isModerated,
    String? moderatorId,
    String? moderatorComment,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? moderatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      isVerified: isVerified ?? this.isVerified,
      isModerated: isModerated ?? this.isModerated,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorComment: moderatorComment ?? this.moderatorComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moderatedAt: moderatedAt ?? this.moderatedAt,
    );
  }

  /// Проверить валидность отзыва
  bool get isValid {
    return rating >= 1 && rating <= 5 && 
           comment.isNotEmpty && 
           comment.length >= 10;
  }

  /// Получить отображаемый рейтинг (звезды)
  String get ratingStars {
    return '★' * rating.round() + '☆' * (5 - rating.round());
  }
}