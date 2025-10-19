import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отзыва
class Review {
  final String id;
  final String customerId;
  final String specialistId;
  final String bookingId;
  final int rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Review({
    required this.id,
    required this.customerId,
    required this.specialistId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'specialistId': specialistId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Review copyWith({
    String? id,
    String? customerId,
    String? specialistId,
    String? bookingId,
    int? rating,
    String? comment,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
