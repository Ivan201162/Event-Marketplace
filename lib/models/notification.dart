import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип уведомления
enum NotificationType {
  newBooking, // Новая заявка
  bookingAccepted, // Заявка принята
  bookingRejected, // Заявка отклонена
  bookingCancelled, // Заявка отменена
  newReview, // Новый отзыв
  paymentReceived, // Получен платеж
  reminder, // Напоминание
  system, // Системное уведомление
  discount, // Скидка предоставлена
  recommendation, // Рекомендации по мероприятию
}

/// Статус уведомления
enum NotificationStatus {
  unread, // Не прочитано
  read, // Прочитано
  archived, // Архивировано
}

/// Модель уведомления
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.status = NotificationStatus.unread,
    this.isRead = false,
    this.createdAt,
  });

  /// Создать уведомление из документа Firestore
  factory AppNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => NotificationStatus.unread,
      ),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final NotificationStatus status;
  final bool isRead;
  final DateTime? createdAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'data': data,
        'status': status.name,
        'isRead': isRead,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  /// Копировать с изменениями
  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    NotificationStatus? status,
    bool? isRead,
    DateTime? createdAt,
  }) =>
      AppNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        title: title ?? this.title,
        message: message ?? this.message,
        data: data ?? this.data,
        status: status ?? this.status,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Получить иконку для типа уведомления
  String get iconName {
    switch (type) {
      case NotificationType.newBooking:
        return 'booking';
      case NotificationType.bookingAccepted:
        return 'check_circle';
      case NotificationType.bookingRejected:
        return 'cancel';
      case NotificationType.bookingCancelled:
        return 'event_busy';
      case NotificationType.newReview:
        return 'star';
      case NotificationType.paymentReceived:
        return 'payment';
      case NotificationType.reminder:
        return 'schedule';
      case NotificationType.system:
        return 'info';
      case NotificationType.discount:
        return 'local_offer';
      case NotificationType.recommendation:
        return 'lightbulb';
    }
  }

  /// Получить цвет для типа уведомления
  String get colorName {
    switch (type) {
      case NotificationType.newBooking:
        return 'blue';
      case NotificationType.bookingAccepted:
        return 'green';
      case NotificationType.bookingRejected:
        return 'red';
      case NotificationType.bookingCancelled:
        return 'orange';
      case NotificationType.newReview:
        return 'amber';
      case NotificationType.paymentReceived:
        return 'green';
      case NotificationType.reminder:
        return 'purple';
      case NotificationType.system:
        return 'grey';
      case NotificationType.discount:
        return 'green';
      case NotificationType.recommendation:
        return 'blue';
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
  String toString() =>
      'AppNotification(id: $id, type: $type, title: $title, isRead: $isRead)';
}
