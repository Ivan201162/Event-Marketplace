import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель активности пользователя для рекомендаций
class UserActivity {
  const UserActivity({
    required this.id,
    required this.userId,
    required this.category,
    required this.activityType, required this.timestamp, this.specialistId,
    this.city,
    this.price,
    this.metadata,
  });

  /// Создание из Firestore документа
  factory UserActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserActivity(
      id: doc.id,
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      specialistId: data['specialistId'],
      city: data['city'],
      price: data['price']?.toDouble(),
      activityType: data['activityType'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }
  final String id;
  final String userId;
  final String category;
  final String? specialistId;
  final String? city;
  final double? price;
  final String activityType;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'category': category,
        'specialistId': specialistId,
        'city': city,
        'price': price,
        'activityType': activityType,
        'timestamp': Timestamp.fromDate(timestamp),
        'metadata': metadata,
      };

  /// Копирование с изменениями
  UserActivity copyWith({
    String? id,
    String? userId,
    String? category,
    String? specialistId,
    String? city,
    double? price,
    String? activityType,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      UserActivity(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        category: category ?? this.category,
        specialistId: specialistId ?? this.specialistId,
        city: city ?? this.city,
        price: price ?? this.price,
        activityType: activityType ?? this.activityType,
        timestamp: timestamp ?? this.timestamp,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserActivity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserActivity(id: $id, userId: $userId, category: $category, type: $activityType)';
}

/// Типы активности пользователя
enum ActivityType {
  search('search', 'Поиск'),
  view('view', 'Просмотр'),
  booking('booking', 'Бронирование'),
  favorite('favorite', 'Избранное'),
  review('review', 'Отзыв'),
  share('share', 'Поделиться');

  const ActivityType(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// Модель рекомендации
class Recommendation {
  const Recommendation({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.specialistName,
    required this.category,
    required this.city,
    required this.price,
    required this.rating,
    required this.reason, required this.confidence, required this.createdAt, this.photoUrl,
  });

  /// Создание из Firestore документа
  factory Recommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Recommendation(
      id: doc.id,
      userId: data['userId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      category: data['category'] ?? '',
      city: data['city'] ?? '',
      price: data['price']?.toDouble() ?? 0.0,
      rating: data['rating']?.toDouble() ?? 0.0,
      photoUrl: data['photoUrl'],
      reason: data['reason'] ?? '',
      confidence: data['confidence']?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String userId;
  final String specialistId;
  final String specialistName;
  final String category;
  final String city;
  final double price;
  final double rating;
  final String? photoUrl;
  final String reason;
  final double confidence;
  final DateTime createdAt;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'specialistId': specialistId,
        'specialistName': specialistName,
        'category': category,
        'city': city,
        'price': price,
        'rating': rating,
        'photoUrl': photoUrl,
        'reason': reason,
        'confidence': confidence,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recommendation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Recommendation(id: $id, specialist: $specialistName, reason: $reason)';
}
