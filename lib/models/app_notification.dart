import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель уведомления приложения
class AppNotification {

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  /// Создать уведомление из Map
  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      readAt: map['readAt'] != null
          ? (map['readAt'] is Timestamp
              ? (map['readAt'] as Timestamp).toDate()
              : DateTime.parse(map['readAt'].toString()))
          : null,
    );

  /// Создать уведомление из Firestore документа
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification.fromMap({
      'id': doc.id,
      ...data,
    });
  }
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };

  /// Создать копию с изменениями
  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) => AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );

  @override
  String toString() => 'AppNotification(id: $id, userId: $userId, title: $title, body: $body, type: $type, isRead: $isRead, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.body == body &&
        other.type == type &&
        other.isRead == isRead &&
        other.createdAt == createdAt &&
        other.readAt == readAt;
  }

  @override
  int get hashCode => id.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        body.hashCode ^
        type.hashCode ^
        isRead.hashCode ^
        createdAt.hashCode ^
        readAt.hashCode;
}

/// Типы уведомлений
enum NotificationType {
  newBooking,
  bookingConfirmed,
  bookingRejected,
  chatMessage,
  system,
  discount,
}

/// Расширение для получения отображаемого имени типа уведомления
extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.newBooking:
        return 'Новая заявка';
      case NotificationType.bookingConfirmed:
        return 'Заявка подтверждена';
      case NotificationType.bookingRejected:
        return 'Заявка отклонена';
      case NotificationType.chatMessage:
        return 'Новое сообщение';
      case NotificationType.system:
        return 'Системное уведомление';
      case NotificationType.discount:
        return 'Скидка';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.newBooking:
        return '📋';
      case NotificationType.bookingConfirmed:
        return '✅';
      case NotificationType.bookingRejected:
        return '❌';
      case NotificationType.chatMessage:
        return '💬';
      case NotificationType.system:
        return '🔔';
      case NotificationType.discount:
        return '🎉';
    }
  }
}









