import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отзыва заказчика
class CustomerReview {
  final String id;
  final String customerId;
  final String specialistId;
  final String orderId;
  final double rating;
  final String text;
  final List<String>? images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final Map<String, dynamic>? metadata;
  final String? response; // Ответ специалиста
  final DateTime? responseDate;

  const CustomerReview({
    required this.id,
    required this.customerId,
    required this.specialistId,
    required this.orderId,
    required this.rating,
    required this.text,
    this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.isVerified,
    this.metadata,
    this.response,
    this.responseDate,
  });

  factory CustomerReview.fromMap(Map<String, dynamic> map) {
    return CustomerReview(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      specialistId: map['specialistId'] as String,
      orderId: map['orderId'] as String,
      rating: (map['rating'] as num).toDouble(),
      text: map['text'] as String,
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      isVerified: map['isVerified'] as bool? ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
      response: map['response'] as String?,
      responseDate: map['responseDate'] != null 
          ? _parseTimestamp(map['responseDate']) 
          : null,
    );
  }

  factory CustomerReview.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerReview.fromMap({...data, 'id': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'specialistId': specialistId,
      'orderId': orderId,
      'rating': rating,
      'text': text,
      if (images != null) 'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      if (metadata != null) 'metadata': metadata,
      if (response != null) 'response': response,
      if (responseDate != null) 'responseDate': Timestamp.fromDate(responseDate!),
    };
  }

  CustomerReview copyWith({
    String? id,
    String? customerId,
    String? specialistId,
    String? orderId,
    double? rating,
    String? text,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    Map<String, dynamic>? metadata,
    String? response,
    DateTime? responseDate,
  }) {
    return CustomerReview(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      orderId: orderId ?? this.orderId,
      rating: rating ?? this.rating,
      text: text ?? this.text,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      metadata: metadata ?? this.metadata,
      response: response ?? this.response,
      responseDate: responseDate ?? this.responseDate,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    return DateTime.now();
  }

  @override
  String toString() {
    return 'CustomerReview(id: $id, rating: $rating, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerReview && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Статистика отзывов
class CustomerReviewStats {
  final String specialistId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // рейтинг -> количество
  final int verifiedReviews;
  final int reviewsWithImages;
  final int reviewsWithResponse;
  final DateTime lastUpdated;

  const CustomerReviewStats({
    required this.specialistId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.verifiedReviews,
    required this.reviewsWithImages,
    required this.reviewsWithResponse,
    required this.lastUpdated,
  });

  factory CustomerReviewStats.fromMap(Map<String, dynamic> map) {
    return CustomerReviewStats(
      specialistId: map['specialistId'] as String,
      averageRating: (map['averageRating'] as num).toDouble(),
      totalReviews: map['totalReviews'] as int,
      ratingDistribution: Map<int, int>.from(map['ratingDistribution'] ?? {}),
      verifiedReviews: map['verifiedReviews'] as int,
      reviewsWithImages: map['reviewsWithImages'] as int,
      reviewsWithResponse: map['reviewsWithResponse'] as int,
      lastUpdated: _parseTimestamp(map['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'verifiedReviews': verifiedReviews,
      'reviewsWithImages': reviewsWithImages,
      'reviewsWithResponse': reviewsWithResponse,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    return DateTime.now();
  }

  /// Получить процент отзывов с определенным рейтингом
  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[rating] ?? 0) / totalReviews * 100;
  }

  /// Получить процент верифицированных отзывов
  double getVerifiedPercentage() {
    if (totalReviews == 0) return 0.0;
    return verifiedReviews / totalReviews * 100;
  }

  /// Получить процент отзывов с изображениями
  double getImagesPercentage() {
    if (totalReviews == 0) return 0.0;
    return reviewsWithImages / totalReviews * 100;
  }

  /// Получить процент отзывов с ответами
  double getResponsePercentage() {
    if (totalReviews == 0) return 0.0;
    return reviewsWithResponse / totalReviews * 100;
  }
}

/// Критерии оценки
enum ReviewCriteria {
  quality('Качество работы'),
  communication('Общение'),
  punctuality('Пунктуальность'),
  professionalism('Профессионализм'),
  value('Соотношение цена/качество'),
  creativity('Креативность'),
  reliability('Надежность'),
  flexibility('Гибкость');

  const ReviewCriteria(this.displayName);
  final String displayName;
}

/// Детальная оценка по критериям
class DetailedRating {
  final String reviewId;
  final Map<ReviewCriteria, double> criteriaRatings;
  final DateTime createdAt;

  const DetailedRating({
    required this.reviewId,
    required this.criteriaRatings,
    required this.createdAt,
  });

  factory DetailedRating.fromMap(Map<String, dynamic> map) {
    final criteriaMap = <ReviewCriteria, double>{};
    final criteriaData = map['criteriaRatings'] as Map<String, dynamic>? ?? {};
    
    for (final entry in criteriaData.entries) {
      final criteria = ReviewCriteria.values.firstWhere(
        (c) => c.name == entry.key,
        orElse: () => ReviewCriteria.quality,
      );
      criteriaMap[criteria] = (entry.value as num).toDouble();
    }

    return DetailedRating(
      reviewId: map['reviewId'] as String,
      criteriaRatings: criteriaMap,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final criteriaData = <String, double>{};
    for (final entry in criteriaRatings.entries) {
      criteriaData[entry.key.name] = entry.value;
    }

    return {
      'reviewId': reviewId,
      'criteriaRatings': criteriaData,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    return DateTime.now();
  }

  /// Получить средний рейтинг по всем критериям
  double get averageRating {
    if (criteriaRatings.isEmpty) return 0.0;
    return criteriaRatings.values.reduce((a, b) => a + b) / criteriaRatings.length;
  }
}

