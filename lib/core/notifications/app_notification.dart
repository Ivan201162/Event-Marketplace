import 'notification_priority.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationPriority priority;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final String? userId;
  final bool isUnread;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.priority = NotificationPriority.normal,
    DateTime? createdAt,
    this.data,
    this.userId,
    this.isUnread = true,
  }) : createdAt = (createdAt ?? DateTime.now().toUtc());

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final p = j['priority']?.toString() ?? 'normal';
    return AppNotification(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      body: j['body']?.toString() ?? '',
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == p,
        orElse: () => NotificationPriority.normal,
      ),
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toUtc(),
      data: (j['data'] is Map<String, dynamic>) ? (j['data'] as Map<String, dynamic>) : null,
      userId: j['userId']?.toString(),
      isUnread: j['isUnread'] as bool? ?? true,
    );
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification.fromJson(map);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
    'isUnread': isUnread,
    if (data != null) 'data': data,
  };

  Map<String, dynamic> toMap() => toJson();
}