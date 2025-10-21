import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationPriority { low, normal, high }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? payloadType; // например: "chat","request","system"
  final String? payloadId;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.payloadType,
    this.payloadId,
    required this.priority,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      payloadType: json['payloadType'] as String?,
      payloadId: json['payloadId'] as String?,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'payloadType': payloadType,
      'payloadId': payloadId,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? payloadType,
    String? payloadId,
    NotificationPriority? priority,
    DateTime? createdAt,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      payloadType: payloadType ?? this.payloadType,
      payloadId: payloadId ?? this.payloadId,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
    );
  }
}
