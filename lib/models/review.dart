import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Review model
class Review extends Equatable {
  final String id;
  final String specialistId;
  final String specialistName;
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final int rating;
  final String text;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final List<String> likedBy;
  final String? bookingId;
  final Map<String, dynamic>? metadata;

  const Review({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    required this.clientId,
    required this.clientName,
    this.clientAvatarUrl,
    required this.rating,
    required this.text,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.likedBy,
    this.bookingId,
    this.metadata,
  });

  /// Create Review from Firestore document
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Review(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientAvatarUrl: data['clientAvatarUrl'],
      rating: data['rating'] ?? 0,
      text: data['text'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      bookingId: data['bookingId'],
      metadata: data['metadata'],
    );
  }

  /// Convert Review to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'specialistId': specialistId,
      'specialistName': specialistName,
      'clientId': clientId,
      'clientName': clientName,
      'clientAvatarUrl': clientAvatarUrl,
      'rating': rating,
      'text': text,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likesCount': likesCount,
      'likedBy': likedBy,
      'bookingId': bookingId,
      'metadata': metadata,
    };
  }

  /// Create a copy of Review with updated fields
  Review copyWith({
    String? id,
    String? specialistId,
    String? specialistName,
    String? clientId,
    String? clientName,
    String? clientAvatarUrl,
    int? rating,
    String? text,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    List<String>? likedBy,
    String? bookingId,
    Map<String, dynamic>? metadata,
  }) {
    return Review(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientAvatarUrl: clientAvatarUrl ?? this.clientAvatarUrl,
      rating: rating ?? this.rating,
      text: text ?? this.text,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      bookingId: bookingId ?? this.bookingId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks нед. назад';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months мес. назад';
    } else {
      return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
    }
  }

  /// Get rating stars
  List<bool> get ratingStars {
    return List.generate(5, (index) => index < rating);
  }

  /// Check if review is liked by user
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  /// Get rating color
  String get ratingColor {
    if (rating >= 4) return 'green';
    if (rating >= 3) return 'orange';
    return 'red';
  }

  /// Get rating text
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
        return 'Без оценки';
    }
  }

  /// Check if review has images
  bool get hasImages => images.isNotEmpty;

  /// Get first image URL
  String? get firstImageUrl => images.isNotEmpty ? images.first : null;

  @override
  List<Object?> get props => [
        id,
        specialistId,
        specialistName,
        clientId,
        clientName,
        clientAvatarUrl,
        rating,
        text,
        images,
        createdAt,
        updatedAt,
        likesCount,
        likedBy,
        bookingId,
        metadata,
      ];
}
