import 'package:flutter/foundation.dart';
import 'notification_type.dart';

/// Уведомление о подписке
@immutable
class SubscriptionNotification {
  final String id;
  final String userId;
  final String specialistId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;

  const SubscriptionNotification({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    required this.createdAt,
    this.isRead = false,
  });

  SubscriptionNotification copyWith({
    String? id,
    String? userId,
    String? specialistId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return SubscriptionNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialistId: specialistId ?? this.specialistId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubscriptionNotification &&
        other.id == id &&
        other.userId == userId &&
        other.specialistId == specialistId &&
        other.type == type &&
        other.title == title &&
        other.body == body &&
        mapEquals(other.data, data) &&
        other.createdAt == createdAt &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        specialistId.hashCode ^
        type.hashCode ^
        title.hashCode ^
        body.hashCode ^
        data.hashCode ^
        createdAt.hashCode ^
        isRead.hashCode;
  }

  @override
  String toString() {
    return 'SubscriptionNotification(id: $id, userId: $userId, specialistId: $specialistId, type: $type, title: $title, body: $body, data: $data, createdAt: $createdAt, isRead: $isRead)';
  }
}
