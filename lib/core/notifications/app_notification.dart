import 'package:cloud_firestore/cloud_firestore.dart';

/// Приоритет уведомления
enum NotificationPriority { low, normal, high, urgent }

/// Модель уведомления приложения
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt, this.imageUrl,
    this.data = const {},
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.isPinned = false,
    this.type,
    this.actionUrl,
    this.expiresAt,
    this.readAt,
  });

  /// Создать из Map
  factory AppNotification.fromMap(Map<String, dynamic> data) {
    return AppNotification(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      priority: _parsePriority(data['priority']),
      isRead: data['isRead'] as bool? ?? false,
      isPinned: data['isPinned'] as bool? ?? false,
      type: data['type'] as String?,
      actionUrl: data['actionUrl'] as String?,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] is Timestamp
              ? (data['expiresAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['expiresAt'].toString()))
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      readAt: data['readAt'] != null
          ? (data['readAt'] is Timestamp
              ? (data['readAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['readAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return AppNotification.fromMap({'id': doc.id, ...data});
  }

  final String id;
  final String userId;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final NotificationPriority priority;
  final bool isRead;
  final bool isPinned;
  final String? type;
  final String? actionUrl;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'data': data,
        'priority': priority.name,
        'isRead': isRead,
        'isPinned': isPinned,
        'type': type,
        'actionUrl': actionUrl,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      };

  /// Копировать с изменениями
  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationPriority? priority,
    bool? isRead,
    bool? isPinned,
    String? type,
    String? actionUrl,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? readAt,
  }) =>
      AppNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        body: body ?? this.body,
        imageUrl: imageUrl ?? this.imageUrl,
        data: data ?? this.data,
        priority: priority ?? this.priority,
        isRead: isRead ?? this.isRead,
        isPinned: isPinned ?? this.isPinned,
        type: type ?? this.type,
        actionUrl: actionUrl ?? this.actionUrl,
        expiresAt: expiresAt ?? this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
        readAt: readAt ?? this.readAt,
      );

  /// Парсинг приоритета из строки
  static NotificationPriority _parsePriority(String? priority) {
    switch (priority) {
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

  /// Получить отображаемое название приоритета
  String get priorityDisplayName {
    switch (priority) {
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

  /// Проверить, истекло ли уведомление
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Проверить, является ли уведомление новым
  bool get isNew {
    return !isRead && !isExpired;
  }
}
