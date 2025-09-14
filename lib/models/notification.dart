import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы уведомлений
enum NotificationType {
  booking_created,     // Создана заявка
  booking_confirmed,   // Заявка подтверждена
  booking_rejected,    // Заявка отклонена
  booking_cancelled,   // Заявка отменена
  payment_created,     // Создан платеж
  payment_completed,   // Платеж завершен
  payment_failed,      // Платеж неудачен
  message_received,    // Получено сообщение
  schedule_updated,    // Обновлено расписание
  system_announcement, // Системное объявление
}

/// Приоритеты уведомлений
enum NotificationPriority {
  low,      // Низкий
  normal,   // Обычный
  high,     // Высокий
  urgent,   // Срочный
}

/// Статусы уведомлений
enum NotificationStatus {
  unread,   // Непрочитано
  read,     // Прочитано
  archived, // Архивировано
}

/// Модель уведомления
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? archivedAt;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? imageUrl;
  final bool isPushSent;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.archivedAt,
    this.data,
    this.actionUrl,
    this.imageUrl,
    this.isPushSent = false,
  });

  /// Создать из документа Firestore
  factory AppNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseNotificationType(data['type']),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      priority: _parseNotificationPriority(data['priority']),
      status: _parseNotificationStatus(data['status']),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      readAt: data['readAt'] != null 
          ? (data['readAt'] as Timestamp).toDate() 
          : null,
      archivedAt: data['archivedAt'] != null 
          ? (data['archivedAt'] as Timestamp).toDate() 
          : null,
      data: data['data'],
      actionUrl: data['actionUrl'],
      imageUrl: data['imageUrl'],
      isPushSent: data['isPushSent'] ?? false,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'priority': priority.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'data': data,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
      'isPushSent': isPushSent,
    };
  }

  /// Копировать с изменениями
  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? archivedAt,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
    bool? isPushSent,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      archivedAt: archivedAt ?? this.archivedAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isPushSent: isPushSent ?? this.isPushSent,
    );
  }

  /// Проверить, прочитано ли уведомление
  bool get isRead => status == NotificationStatus.read;

  /// Проверить, архивировано ли уведомление
  bool get isArchived => status == NotificationStatus.archived;

  /// Проверить, непрочитано ли уведомление
  bool get isUnread => status == NotificationStatus.unread;

  /// Получить отображаемое название типа уведомления
  String get typeDisplayName {
    switch (type) {
      case NotificationType.booking_created:
        return 'Новая заявка';
      case NotificationType.booking_confirmed:
        return 'Заявка подтверждена';
      case NotificationType.booking_rejected:
        return 'Заявка отклонена';
      case NotificationType.booking_cancelled:
        return 'Заявка отменена';
      case NotificationType.payment_created:
        return 'Новый платеж';
      case NotificationType.payment_completed:
        return 'Платеж завершен';
      case NotificationType.payment_failed:
        return 'Платеж неудачен';
      case NotificationType.message_received:
        return 'Новое сообщение';
      case NotificationType.schedule_updated:
        return 'Расписание обновлено';
      case NotificationType.system_announcement:
        return 'Системное объявление';
    }
  }

  /// Получить иконку для типа уведомления
  String get typeIcon {
    switch (type) {
      case NotificationType.booking_created:
        return '📋';
      case NotificationType.booking_confirmed:
        return '✅';
      case NotificationType.booking_rejected:
        return '❌';
      case NotificationType.booking_cancelled:
        return '🚫';
      case NotificationType.payment_created:
        return '💳';
      case NotificationType.payment_completed:
        return '💰';
      case NotificationType.payment_failed:
        return '⚠️';
      case NotificationType.message_received:
        return '💬';
      case NotificationType.schedule_updated:
        return '📅';
      case NotificationType.system_announcement:
        return '📢';
    }
  }

  /// Получить цвет приоритета
  String get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return 'grey';
      case NotificationPriority.normal:
        return 'blue';
      case NotificationPriority.high:
        return 'orange';
      case NotificationPriority.urgent:
        return 'red';
    }
  }

  /// Парсинг типа уведомления
  static NotificationType _parseNotificationType(dynamic typeData) {
    if (typeData == null) return NotificationType.system_announcement;
    
    final typeString = typeData.toString().toLowerCase();
    switch (typeString) {
      case 'booking_created':
        return NotificationType.booking_created;
      case 'booking_confirmed':
        return NotificationType.booking_confirmed;
      case 'booking_rejected':
        return NotificationType.booking_rejected;
      case 'booking_cancelled':
        return NotificationType.booking_cancelled;
      case 'payment_created':
        return NotificationType.payment_created;
      case 'payment_completed':
        return NotificationType.payment_completed;
      case 'payment_failed':
        return NotificationType.payment_failed;
      case 'message_received':
        return NotificationType.message_received;
      case 'schedule_updated':
        return NotificationType.schedule_updated;
      case 'system_announcement':
      default:
        return NotificationType.system_announcement;
    }
  }

  /// Парсинг приоритета уведомления
  static NotificationPriority _parseNotificationPriority(dynamic priorityData) {
    if (priorityData == null) return NotificationPriority.normal;
    
    final priorityString = priorityData.toString().toLowerCase();
    switch (priorityString) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      case 'normal':
      default:
        return NotificationPriority.normal;
    }
  }

  /// Парсинг статуса уведомления
  static NotificationStatus _parseNotificationStatus(dynamic statusData) {
    if (statusData == null) return NotificationStatus.unread;
    
    final statusString = statusData.toString().toLowerCase();
    switch (statusString) {
      case 'read':
        return NotificationStatus.read;
      case 'archived':
        return NotificationStatus.archived;
      case 'unread':
      default:
        return NotificationStatus.unread;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $type, title: $title, status: $status)';
  }
}

/// Статистика уведомлений
class NotificationStatistics {
  final int totalCount;
  final int unreadCount;
  final int readCount;
  final int archivedCount;
  final Map<NotificationType, int> typeCounts;
  final Map<NotificationPriority, int> priorityCounts;

  const NotificationStatistics({
    required this.totalCount,
    required this.unreadCount,
    required this.readCount,
    required this.archivedCount,
    required this.typeCounts,
    required this.priorityCounts,
  });

  factory NotificationStatistics.empty() {
    return const NotificationStatistics(
      totalCount: 0,
      unreadCount: 0,
      readCount: 0,
      archivedCount: 0,
      typeCounts: {},
      priorityCounts: {},
    );
  }

  /// Процент непрочитанных уведомлений
  double get unreadPercentage {
    if (totalCount == 0) return 0;
    return (unreadCount / totalCount) * 100;
  }
}
