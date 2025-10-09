import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы уведомлений
enum NotificationType {
  like,
  comment,
  follow,
  request,
  message,
  booking,
  system,
}

/// Модель уведомления
class Notification {
  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.isPinned = false,
    this.senderId,
    this.targetId,
  });

  /// Создание из Firestore документа
  factory Notification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Notification(
      id: doc.id,
      userId: data['userId'] ?? data['receiverId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      data: data['data'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp? ?? data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: data['isPinned'] ?? false,
      senderId: data['senderId'],
      targetId: data['targetId'],
    );
  }
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? data;
  final bool isRead;
  final DateTime createdAt;
  final bool isPinned;
  final String? senderId;
  final String? targetId;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPinned': isPinned,
      'senderId': senderId,
      'targetId': targetId,
    };

  /// Копирование с изменениями
  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? data,
    bool? isRead,
    DateTime? createdAt,
    bool? isPinned,
    String? senderId,
    String? targetId,
  }) => Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      senderId: senderId ?? this.senderId,
      targetId: targetId ?? this.targetId,
    );

  /// Получение иконки для типа уведомления
  String get icon {
    switch (type) {
      case NotificationType.like:
        return '❤️';
      case NotificationType.comment:
        return '💬';
      case NotificationType.follow:
        return '👥';
      case NotificationType.request:
        return '📋';
      case NotificationType.message:
        return '💌';
      case NotificationType.booking:
        return '📅';
      case NotificationType.system:
        return '🔔';
    }
  }

  /// Получение цвета для типа уведомления
  String get color {
    switch (type) {
      case NotificationType.like:
        return '#FF6B6B';
      case NotificationType.comment:
        return '#4ECDC4';
      case NotificationType.follow:
        return '#45B7D1';
      case NotificationType.request:
        return '#96CEB4';
      case NotificationType.message:
        return '#FFEAA7';
      case NotificationType.booking:
        return '#DDA0DD';
      case NotificationType.system:
        return '#98D8C8';
    }
  }
}