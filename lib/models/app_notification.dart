import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип уведомления
enum NotificationType {
  bookingConfirmed,
  bookingRejected,
  bookingCancelled,
  paymentCompleted,
  paymentFailed,
  eventReminder,
  newMessage,
  reviewRequest,
  systemAnnouncement,
}

/// Приоритет уведомления
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Модель уведомления
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.timestamp,
    required this.isRead,
    this.bookingId,
    this.paymentId,
    this.data,
    required this.createdAt,
    this.readAt,
  });

  /// Создать из документа Firestore
  factory AppNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.systemAnnouncement,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: (data['isRead'] as bool?) ?? false,
      bookingId: data['bookingId'] as String?,
      paymentId: data['paymentId'] as String?,
      data: data['data'] != null ? Map<String, dynamic>.from(data['data'] as Map<dynamic, dynamic>) : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
    );
  }
  final String id;
  final String userId;
  final String title;
  final String content;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final String? bookingId;
  final String? paymentId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'content': content,
        'type': type.name,
        'priority': priority.name,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRead': isRead,
        'bookingId': bookingId,
        'paymentId': paymentId,
        'data': data,
        'createdAt': Timestamp.fromDate(createdAt),
        'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      };

  /// Копировать с изменениями
  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    bool? isRead,
    String? bookingId,
    String? paymentId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) =>
      AppNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        content: content ?? this.content,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        timestamp: timestamp ?? this.timestamp,
        isRead: isRead ?? this.isRead,
        bookingId: bookingId ?? this.bookingId,
        paymentId: paymentId ?? this.paymentId,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
        readAt: readAt ?? this.readAt,
      );

  /// Отметить как прочитанное
  AppNotification markAsRead() => copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );

  @override
  String toString() =>
      'AppNotification(id: $id, title: $title, type: $type, isRead: $isRead)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
