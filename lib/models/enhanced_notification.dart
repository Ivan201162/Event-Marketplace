/// Расширенная модель уведомления
class EnhancedNotification {
  const EnhancedNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.isArchived = false,
    this.data = const {},
    this.imageUrl,
    this.actionUrl,
    this.priority = NotificationPriority.normal,
    this.category,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.expiresAt,
    this.readAt,
    this.archivedAt,
  });

  /// Создать из Map
  factory EnhancedNotification.fromMap(Map<String, dynamic> map) =>
      EnhancedNotification(
        id: map['id'] as String,
        userId: map['userId'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        type: NotificationType.fromString(map['type'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        isRead: (map['isRead'] as bool?) ?? false,
        isArchived: (map['isArchived'] as bool?) ?? false,
        data: Map<String, dynamic>.from((map['data'] as Map?) ?? {}),
        imageUrl: map['imageUrl'] as String?,
        actionUrl: map['actionUrl'] as String?,
        priority: NotificationPriority.fromString(
            map['priority'] as String? ?? 'normal'),
        category: map['category'] as String?,
        senderId: map['senderId'] as String?,
        senderName: map['senderName'] as String?,
        senderAvatar: map['senderAvatar'] as String?,
        expiresAt: map['expiresAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
            : null,
        readAt: map['readAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['readAt'] as int)
            : null,
        archivedAt: map['archivedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['archivedAt'] as int)
            : null,
      );

  /// Уникальный идентификатор
  final String id;

  /// ID пользователя-получателя
  final String userId;

  /// Заголовок уведомления
  final String title;

  /// Текст уведомления
  final String body;

  /// Тип уведомления
  final NotificationType type;

  /// Дата создания
  final DateTime createdAt;

  /// Прочитано ли уведомление
  final bool isRead;

  /// Архивировано ли уведомление
  final bool isArchived;

  /// Дополнительные данные
  final Map<String, dynamic> data;

  /// URL изображения
  final String? imageUrl;

  /// URL для действия
  final String? actionUrl;

  /// Приоритет уведомления
  final NotificationPriority priority;

  /// Категория уведомления
  final String? category;

  /// ID отправителя
  final String? senderId;

  /// Имя отправителя
  final String? senderName;

  /// Аватар отправителя
  final String? senderAvatar;

  /// Дата истечения
  final DateTime? expiresAt;

  /// Дата прочтения
  final DateTime? readAt;

  /// Дата архивирования
  final DateTime? archivedAt;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isRead': isRead,
        'isArchived': isArchived,
        'data': data,
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
        'priority': priority.value,
        'category': category,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
        'readAt': readAt?.millisecondsSinceEpoch,
        'archivedAt': archivedAt?.millisecondsSinceEpoch,
      };

  /// Создать копию с изменениями
  EnhancedNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    bool? isArchived,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority? priority,
    String? category,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    DateTime? expiresAt,
    DateTime? readAt,
    DateTime? archivedAt,
  }) =>
      EnhancedNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
        isArchived: isArchived ?? this.isArchived,
        data: data ?? this.data,
        imageUrl: imageUrl ?? this.imageUrl,
        actionUrl: actionUrl ?? this.actionUrl,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderAvatar: senderAvatar ?? this.senderAvatar,
        expiresAt: expiresAt ?? this.expiresAt,
        readAt: readAt ?? this.readAt,
        archivedAt: archivedAt ?? this.archivedAt,
      );
}

/// Тип уведомления
enum NotificationType {
  message('message'),
  request('request'),
  like('like'),
  comment('comment'),
  follow('follow'),
  system('system'),
  promotion('promotion'),
  reminder('reminder'),
  update('update'),
  security('security');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    switch (value) {
      case 'message':
        return NotificationType.message;
      case 'request':
        return NotificationType.request;
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'system':
        return NotificationType.system;
      case 'promotion':
        return NotificationType.promotion;
      case 'reminder':
        return NotificationType.reminder;
      case 'update':
        return NotificationType.update;
      case 'security':
        return NotificationType.security;
      default:
        return NotificationType.system;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.message:
        return 'Сообщение';
      case NotificationType.request:
        return 'Заявка';
      case NotificationType.like:
        return 'Лайк';
      case NotificationType.comment:
        return 'Комментарий';
      case NotificationType.follow:
        return 'Подписка';
      case NotificationType.system:
        return 'Система';
      case NotificationType.promotion:
        return 'Акция';
      case NotificationType.reminder:
        return 'Напоминание';
      case NotificationType.update:
        return 'Обновление';
      case NotificationType.security:
        return 'Безопасность';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.message:
        return '💬';
      case NotificationType.request:
        return '📋';
      case NotificationType.like:
        return '❤️';
      case NotificationType.comment:
        return '💭';
      case NotificationType.follow:
        return '👥';
      case NotificationType.system:
        return '⚙️';
      case NotificationType.promotion:
        return '🎁';
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.update:
        return '🔄';
      case NotificationType.security:
        return '🔒';
    }
  }

  String get color {
    switch (this) {
      case NotificationType.message:
        return 'blue';
      case NotificationType.request:
        return 'orange';
      case NotificationType.like:
        return 'red';
      case NotificationType.comment:
        return 'green';
      case NotificationType.follow:
        return 'purple';
      case NotificationType.system:
        return 'grey';
      case NotificationType.promotion:
        return 'yellow';
      case NotificationType.reminder:
        return 'teal';
      case NotificationType.update:
        return 'indigo';
      case NotificationType.security:
        return 'red';
    }
  }
}

/// Приоритет уведомления
enum NotificationPriority {
  low('low'),
  normal('normal'),
  high('high'),
  urgent('urgent');

  const NotificationPriority(this.value);
  final String value;

  static NotificationPriority fromString(String value) {
    switch (value) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Низкий';
      case NotificationPriority.normal:
        return 'Обычный';
      case NotificationPriority.high:
        return 'Высокий';
      case NotificationPriority.urgent:
        return 'Срочный';
    }
  }
}

/// Статистика уведомлений
class NotificationStats {
  const NotificationStats({
    this.total = 0,
    this.unread = 0,
    this.archived = 0,
    this.byType = const {},
    this.byPriority = const {},
  });

  factory NotificationStats.fromMap(Map<String, dynamic> map) =>
      NotificationStats(
        total: (map['total'] as int?) ?? 0,
        unread: (map['unread'] as int?) ?? 0,
        archived: (map['archived'] as int?) ?? 0,
        byType: Map<NotificationType, int>.from(
          (map['byType'] as Map?)?.map(
                (key, value) => MapEntry(
                    NotificationType.fromString(key as String), value as int),
              ) ??
              {},
        ),
        byPriority: Map<NotificationPriority, int>.from(
          (map['byPriority'] as Map?)?.map(
                (key, value) => MapEntry(
                    NotificationPriority.fromString(key as String),
                    value as int),
              ) ??
              {},
        ),
      );

  final int total;
  final int unread;
  final int archived;
  final Map<NotificationType, int> byType;
  final Map<NotificationPriority, int> byPriority;

  Map<String, dynamic> toMap() => {
        'total': total,
        'unread': unread,
        'archived': archived,
        'byType': byType.map((key, value) => MapEntry(key.value, value)),
        'byPriority':
            byPriority.map((key, value) => MapEntry(key.value, value)),
      };
}
