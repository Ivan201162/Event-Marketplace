import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель подписки на специалиста
class Subscription {
  final String id;
  final String userId;
  final String specialistId;
  final String specialistName;
  final String? specialistPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const Subscription({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.specialistName,
    this.specialistPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.metadata,
  });

  /// Создать из документа Firestore
  factory Subscription.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      userId: data['userId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      specialistPhotoUrl: data['specialistPhotoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'specialistId': specialistId,
      'specialistName': specialistName,
      'specialistPhotoUrl': specialistPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Создать копию с изменениями
  Subscription copyWith({
    String? id,
    String? userId,
    String? specialistId,
    String? specialistName,
    String? specialistPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistPhotoUrl: specialistPhotoUrl ?? this.specialistPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Модель уведомления о подписке
class SubscriptionNotification {
  final String id;
  final String userId;
  final String specialistId;
  final String specialistName;
  final String? specialistPhotoUrl;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final String? postId;
  final String? storyId;

  const SubscriptionNotification({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.specialistName,
    this.specialistPhotoUrl,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    required this.isRead,
    this.postId,
    this.storyId,
  });

  /// Создать из документа Firestore
  factory SubscriptionNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      specialistPhotoUrl: data['specialistPhotoUrl'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.newPost,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      postId: data['postId'],
      storyId: data['storyId'],
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'specialistId': specialistId,
      'specialistName': specialistName,
      'specialistPhotoUrl': specialistPhotoUrl,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'postId': postId,
      'storyId': storyId,
    };
  }
}

/// Типы уведомлений о подписке
enum NotificationType {
  newPost,
  newStory,
  newEvent,
  newPortfolio,
  announcement,
}
