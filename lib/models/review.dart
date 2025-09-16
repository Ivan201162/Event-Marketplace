import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отзыва
class Review {
  final String id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int rating; // 1-5 звезд
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool
      isVerified; // Подтвержден ли отзыв (участник действительно был на мероприятии)

  const Review({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
  });

  /// Создать из документа Firestore
  factory Review.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      rating: data['rating'] ?? 5,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
    };
  }

  /// Создать копию с изменениями
  Review copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
  }) {
    return Review(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  /// Получить цвет рейтинга
  String get ratingColor {
    if (rating >= 4) return 'green';
    if (rating >= 3) return 'orange';
    return 'red';
  }

  /// Получить текст рейтинга
  String get ratingText {
    switch (rating) {
      case 5:
        return 'Отлично';
      case 4:
        return 'Хорошо';
      case 3:
        return 'Удовлетворительно';
      case 2:
        return 'Плохо';
      case 1:
        return 'Очень плохо';
      default:
        return 'Не оценено';
    }
  }

  /// Проверить, можно ли редактировать отзыв
  bool canEdit(DateTime eventDate) {
    // Можно редактировать в течение 7 дней после мероприятия
    final daysSinceEvent = DateTime.now().difference(eventDate).inDays;
    return daysSinceEvent <= 7;
  }
}
