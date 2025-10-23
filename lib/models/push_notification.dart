import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Push notification type enum
enum PushNotificationType {
  booking('Бронирование'),
  payment('Платеж'),
  message('Сообщение'),
  review('Отзыв'),
  request('Заявка'),
  system('Системное'),
  promotion('Акция'),
  reminder('Напоминание');

  const PushNotificationType(this.displayName);
  final String displayName;
}

/// Push notification priority enum
enum PushNotificationPriority {
  low('Низкий'),
  normal('Обычный'),
  high('Высокий'),
  urgent('Срочный');

  const PushNotificationPriority(this.displayName);
  final String displayName;
}

/// Push notification model
class PushNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final PushNotificationType type;
  final PushNotificationPriority priority;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final bool read;
  final bool delivered;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;

  const PushNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.data,
    this.imageUrl,
    this.actionUrl,
    this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    required this.read,
    required this.delivered,
    required this.createdAt,
    this.readAt,
    this.deliveredAt,
    this.scheduledAt,
    this.expiresAt,
  });

  /// Create PushNotification from Firestore document
  factory PushNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PushNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: PushNotificationType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => PushNotificationType.system,
      ),
      priority: PushNotificationPriority.values.firstWhere(
        (priority) => priority.name == data['priority'],
        orElse: () => PushNotificationPriority.normal,
      ),
      data: data['data'],
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      senderAvatarUrl: data['senderAvatarUrl'],
      read: data['read'] ?? false,
      delivered: data['delivered'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
      scheduledAt: data['scheduledAt'] != null
          ? (data['scheduledAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert PushNotification to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'read': read,
      'delivered': delivered,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'scheduledAt':
          scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// Create a copy of PushNotification with updated fields
  PushNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    PushNotificationType? type,
    PushNotificationPriority? priority,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    bool? read,
    bool? delivered,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? deliveredAt,
    DateTime? scheduledAt,
    DateTime? expiresAt,
  }) {
    return PushNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      read: read ?? this.read,
      delivered: delivered ?? this.delivered,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Get type icon
  String get typeIcon {
    switch (type) {
      case PushNotificationType.booking:
        return '📅';
      case PushNotificationType.payment:
        return '💳';
      case PushNotificationType.message:
        return '💬';
      case PushNotificationType.review:
        return '⭐';
      case PushNotificationType.request:
        return '📋';
      case PushNotificationType.system:
        return '⚙️';
      case PushNotificationType.promotion:
        return '🎉';
      case PushNotificationType.reminder:
        return '⏰';
    }
  }

  /// Get priority color
  String get priorityColor {
    switch (priority) {
      case PushNotificationPriority.low:
        return 'grey';
      case PushNotificationPriority.normal:
        return 'blue';
      case PushNotificationPriority.high:
        return 'orange';
      case PushNotificationPriority.urgent:
        return 'red';
    }
  }

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
    }
  }

  /// Get formatted time
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date and time
  String get formattedDateTime {
    return '$formattedDate в $formattedTime';
  }

  /// Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if notification is scheduled
  bool get isScheduled {
    if (scheduledAt == null) return false;
    return DateTime.now().isBefore(scheduledAt!);
  }

  /// Check if notification can be delivered
  bool get canBeDelivered {
    return !isExpired && !isScheduled;
  }

  /// Get notification age in minutes
  int get ageInMinutes {
    return DateTime.now().difference(createdAt).inMinutes;
  }

  /// Get notification age in hours
  int get ageInHours {
    return DateTime.now().difference(createdAt).inHours;
  }

  /// Get notification age in days
  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Get formatted age
  String get formattedAge {
    if (ageInMinutes < 60) {
      return '$ageInMinutes мин. назад';
    } else if (ageInHours < 24) {
      return '$ageInHours ч. назад';
    } else {
      return '$ageInDays дн. назад';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        type,
        priority,
        data,
        imageUrl,
        actionUrl,
        senderId,
        senderName,
        senderAvatarUrl,
        read,
        delivered,
        createdAt,
        readAt,
        deliveredAt,
        scheduledAt,
        expiresAt,
      ];
}
