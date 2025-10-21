import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Review model
class Review extends Equatable {
  final String id;
  final String specialistId;
  final String clientId;
  final String clientName;
  final String specialistName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;
  final List<String> likedBy;
  final int likesCount;
  final String? title;
  final bool hasComment;
  final List<String> tags;
  final bool isVerified;
  final bool isPublic;
  final List<String> serviceTags;
  final List<String> photos;
  final List<Map<String, dynamic>> responses;

  const Review({
    required this.id,
    required this.specialistId,
    required this.clientId,
    required this.clientName,
    required this.specialistName,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.likedBy = const [],
    this.likesCount = 0,
    this.title,
    this.hasComment = false,
    this.tags = const [],
    this.isVerified = false,
    this.isPublic = true,
    this.serviceTags = const [],
    this.photos = const [],
    this.responses = const [],
  });

  /// Create Review from Firestore document
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      specialistName: data['specialistName'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      title: data['title'],
      hasComment: data['hasComment'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      isVerified: data['isVerified'] ?? false,
      isPublic: data['isPublic'] ?? true,
      serviceTags: List<String>.from(data['serviceTags'] ?? []),
      photos: List<String>.from(data['photos'] ?? []),
      responses: List<Map<String, dynamic>>.from(data['responses'] ?? []),
    );
  }

  /// Convert Review to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'specialistId': specialistId,
      'clientId': clientId,
      'clientName': clientName,
      'specialistName': specialistName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'images': images,
      'likedBy': likedBy,
      'likesCount': likesCount,
      'title': title,
      'hasComment': hasComment,
      'tags': tags,
      'isVerified': isVerified,
      'isPublic': isPublic,
      'serviceTags': serviceTags,
      'photos': photos,
      'responses': responses,
    };
  }

  /// Create a copy with updated fields
  Review copyWith({
    String? id,
    String? specialistId,
    String? clientId,
    String? clientName,
    String? specialistName,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? images,
    List<String>? likedBy,
    int? likesCount,
    String? title,
    bool? hasComment,
    List<String>? tags,
    bool? isVerified,
    bool? isPublic,
    List<String>? serviceTags,
    List<String>? photos,
    List<Map<String, dynamic>>? responses,
  }) {
    return Review(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      specialistName: specialistName ?? this.specialistName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      likedBy: likedBy ?? this.likedBy,
      likesCount: likesCount ?? this.likesCount,
      title: title ?? this.title,
      hasComment: hasComment ?? this.hasComment,
      tags: tags ?? this.tags,
      isVerified: isVerified ?? this.isVerified,
      isPublic: isPublic ?? this.isPublic,
      serviceTags: serviceTags ?? this.serviceTags,
      photos: photos ?? this.photos,
      responses: responses ?? this.responses,
    );
  }

  /// Get rating stars string
  String get ratingStars => '⭐' * rating;

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }

  /// Check if review has images
  bool get hasImages => images.isNotEmpty || photos.isNotEmpty;

  /// Get first image
  String? get firstImage {
    if (images.isNotEmpty) return images.first;
    if (photos.isNotEmpty) return photos.first;
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        specialistId,
        clientId,
        clientName,
        specialistName,
        rating,
        comment,
        createdAt,
        updatedAt,
        images,
        likedBy,
        likesCount,
        title,
        hasComment,
        tags,
        isVerified,
        isPublic,
        serviceTags,
        photos,
        responses,
      ];

  @override
  String toString() {
    return 'Review(id: $id, specialistId: $specialistId, clientId: $clientId, rating: $rating)';
  }
}

/// Review stats model
class ReviewStats extends Equatable {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final int verifiedReviews;
  final int recentReviews;

  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.verifiedReviews,
    required this.recentReviews,
  });

  /// Get rating percentage for specific rating
  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[rating] ?? 0) / totalReviews * 100;
  }

  /// Get formatted average rating
  String get formattedAverageRating => averageRating.toStringAsFixed(1);

  @override
  List<Object?> get props => [
        averageRating,
        totalReviews,
        ratingDistribution,
        verifiedReviews,
        recentReviews,
      ];

  @override
  String toString() {
    return 'ReviewStats(averageRating: $averageRating, totalReviews: $totalReviews)';
  }
}

/// Specialist review stats model
class SpecialistReviewStats extends Equatable {
  final String specialistId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final List<String> topTags;
  final Map<String, int> serviceRatings;

  const SpecialistReviewStats({
    required this.specialistId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.topTags,
    required this.serviceRatings,
  });

  /// Get rating percentage for specific rating
  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[rating] ?? 0) / totalReviews * 100;
  }

  /// Get formatted average rating
  String get formattedAverageRating => averageRating.toStringAsFixed(1);

  @override
  List<Object?> get props => [
        specialistId,
        averageRating,
        totalReviews,
        ratingDistribution,
        topTags,
        serviceRatings,
      ];

  @override
  String toString() {
    return 'SpecialistReviewStats(specialistId: $specialistId, averageRating: $averageRating, totalReviews: $totalReviews)';
  }
}
