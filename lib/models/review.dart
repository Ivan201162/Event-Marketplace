import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отзыва
class Review {
  final String id;
  final String specialistId;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final String bookingId;
  final int rating; // 1-5 звезд
  final String? title;
  final String? comment;
  final List<String> images; // Фото с мероприятия
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified; // Подтвержден ли отзыв
  final bool isPublic; // Публичный ли отзыв
  final Map<String, dynamic>? metadata; // Дополнительные данные

  Review({
    required this.id,
    required this.specialistId,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.bookingId,
    required this.rating,
    this.title,
    this.comment,
    required this.images,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isVerified = false,
    this.isPublic = true,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'customerId': customerId,
      'customerName': customerName,
      'customerAvatar': customerAvatar,
      'bookingId': bookingId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'isPublic': isPublic,
      'metadata': metadata,
    };
  }

  /// Создание из документа Firestore
  factory Review.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerAvatar: data['customerAvatar'],
      bookingId: data['bookingId'] ?? '',
      rating: data['rating'] ?? 5,
      title: data['title'],
      comment: data['comment'],
      images: List<String>.from(data['images'] ?? []),
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      isPublic: data['isPublic'] ?? true,
      metadata: data['metadata'],
    );
  }

  /// Копирование с изменениями
  Review copyWith({
    String? id,
    String? specialistId,
    String? customerId,
    String? customerName,
    String? customerAvatar,
    String? bookingId,
    int? rating,
    String? title,
    String? comment,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isPublic,
    Map<String, dynamic>? metadata,
  }) {
    return Review(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isPublic: isPublic ?? this.isPublic,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Review(id: $id, specialistId: $specialistId, customerId: $customerId, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Статистика отзывов
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // Количество отзывов по каждой оценке
  final int verifiedReviews;
  final int publicReviews;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.verifiedReviews,
    required this.publicReviews,
  });

  /// Создание из списка отзывов
  factory ReviewStats.fromReviews(List<Review> reviews) {
    if (reviews.isEmpty) {
      return ReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        verifiedReviews: 0,
        publicReviews: 0,
      );
    }

    final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / reviews.length;

    final ratingDistribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = reviews.where((review) => review.rating == i).length;
    }

    final verifiedReviews = reviews.where((review) => review.isVerified).length;
    final publicReviews = reviews.where((review) => review.isPublic).length;

    return ReviewStats(
      averageRating: averageRating,
      totalReviews: reviews.length,
      ratingDistribution: ratingDistribution,
      verifiedReviews: verifiedReviews,
      publicReviews: publicReviews,
    );
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'verifiedReviews': verifiedReviews,
      'publicReviews': publicReviews,
    };
  }

  /// Создание из документа Firestore
  factory ReviewStats.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewStats(
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {}),
      verifiedReviews: data['verifiedReviews'] ?? 0,
      publicReviews: data['publicReviews'] ?? 0,
    );
  }
}