import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отзыва
class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.specialistId,
    required this.customerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.reply,
    this.repliedAt,
    this.isVerified = false,
    this.isHelpful = 0,
    this.isReported = false,
    this.tags = const [],
  });

  final String id;
  final String bookingId;
  final String specialistId;
  final String customerId;
  final double rating; // 1.0 - 5.0
  final String comment;
  final DateTime createdAt;
  final String? reply; // Ответ специалиста
  final DateTime? repliedAt;
  final bool isVerified; // Проверенный отзыв
  final int isHelpful; // Количество лайков
  final bool isReported; // Жалоба на отзыв
  final List<String> tags; // Теги (качество, пунктуальность, цена)

  /// Создает отзыв из документа Firestore
  factory Review.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    
    return Review(
      id: doc.id,
      bookingId: data['bookingId'] as String,
      specialistId: data['specialistId'] as String,
      customerId: data['customerId'] as String,
      rating: (data['rating'] as num).toDouble(),
      comment: data['comment'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reply: data['reply'] as String?,
      repliedAt: data['repliedAt'] != null
          ? (data['repliedAt'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] as bool? ?? false,
      isHelpful: data['isHelpful'] as int? ?? 0,
      isReported: data['isReported'] as bool? ?? false,
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
    );
  }

  /// Преобразует отзыв в Map для Firestore
  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'specialistId': specialistId,
        'customerId': customerId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
        'reply': reply,
        'repliedAt': repliedAt != null ? Timestamp.fromDate(repliedAt!) : null,
        'isVerified': isVerified,
        'isHelpful': isHelpful,
        'isReported': isReported,
        'tags': tags,
      };

  /// Создает копию с измененными полями
  Review copyWith({
    String? id,
    String? bookingId,
    String? specialistId,
    String? customerId,
    double? rating,
    String? comment,
    DateTime? createdAt,
    String? reply,
    DateTime? repliedAt,
    bool? isVerified,
    int? isHelpful,
    bool? isReported,
    List<String>? tags,
  }) =>
      Review(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        specialistId: specialistId ?? this.specialistId,
        customerId: customerId ?? this.customerId,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        createdAt: createdAt ?? this.createdAt,
        reply: reply ?? this.reply,
        repliedAt: repliedAt ?? this.repliedAt,
        isVerified: isVerified ?? this.isVerified,
        isHelpful: isHelpful ?? this.isHelpful,
        isReported: isReported ?? this.isReported,
        tags: tags ?? this.tags,
      );

  @override
  String toString() => 'Review(id: $id, rating: $rating, comment: $comment)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Теги для отзывов
enum ReviewTag {
  quality('Качество'),
  punctuality('Пунктуальность'),
  price('Цена'),
  communication('Общение'),
  professionalism('Профессионализм'),
  creativity('Креативность'),
  reliability('Надежность'),
  service('Сервис');

  const ReviewTag(this.displayName);
  final String displayName;
}