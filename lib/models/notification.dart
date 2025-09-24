import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_template.dart';

/// Приоритеты уведомлений
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Типы уведомлений
enum NotificationType {
  booking,
  payment,
  message,
  system,
  reminder,
}

/// Каналы уведомлений
enum NotificationChannel {
  push,
  email,
  sms,
  inApp,
}

/// Модель уведомления
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.priority = NotificationPriority.normal,
  });

  /// Создаёт уведомление из документа Firestore
  factory AppNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      data: Map<String, dynamic>.from(data['data'] as Map? ?? {}),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => NotificationPriority.normal,
      ),
    );
  }
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final NotificationPriority priority;

  /// Преобразует уведомление в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
        'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
        'priority': priority.name,
      };

  /// Создаёт копию уведомления с обновлёнными полями
  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    NotificationPriority? priority,
  }) =>
      AppNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        data: data ?? this.data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
        readAt: readAt ?? this.readAt,
        priority: priority ?? this.priority,
      );

  /// Типы уведомлений
  static const String typeReview = 'review';
  static const String typeBooking = 'booking';
  static const String typePayment = 'payment';
  static const String typeReminder = 'reminder';
  static const String typeMessage = 'message';
  static const String typeMarketing = 'marketing';
  static const String typeSystem = 'system';

  /// Получает иконку для типа уведомления
  String get typeIcon {
    switch (type) {
      case typeReview:
        return '⭐';
      case typeBooking:
        return '📅';
      case typePayment:
        return '💳';
      case typeReminder:
        return '⏰';
      case typeMessage:
        return '💬';
      case typeMarketing:
        return '📢';
      case typeSystem:
        return '⚙️';
      default:
        return '🔔';
    }
  }

  /// Получает цвет для типа уведомления
  String get typeColor {
    switch (type) {
      case typeReview:
        return '#FFD700'; // Золотой
      case typeBooking:
        return '#4CAF50'; // Зелёный
      case typePayment:
        return '#2196F3'; // Синий
      case typeReminder:
        return '#FF9800'; // Оранжевый
      case typeMessage:
        return '#9C27B0'; // Фиолетовый
      case typeMarketing:
        return '#E91E63'; // Розовый
      case typeSystem:
        return '#607D8B'; // Серый
      default:
        return '#757575'; // Тёмно-серый
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Проверить, является ли уведомление непрочитанным
  bool get isUnread => !isRead;

  @override
  String toString() =>
      'AppNotification(id: $id, type: $type, title: $title, isRead: $isRead)';
}

/// Расширение для работы с уведомлениями
extension NotificationExtension on List<AppNotification> {
  /// Получает непрочитанные уведомления
  List<AppNotification> get unread => where((n) => !n.isRead).toList();

  /// Получает уведомления по типу
  List<AppNotification> byType(String type) =>
      where((n) => n.type == type).toList();

  /// Получает последние уведомления
  List<AppNotification> get recent =>
      toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Группирует уведомления по типу
  Map<String, List<AppNotification>> get groupedByType {
    final grouped = <String, List<AppNotification>>{};
    for (final notification in this) {
      grouped.putIfAbsent(notification.type, () => []).add(notification);
    }
    return grouped;
  }
}
