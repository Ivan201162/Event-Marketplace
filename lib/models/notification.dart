import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Notification type
enum NotificationType {
  request,
  message,
  like,
  comment,
  system,
  reminder,
  promotion
}

/// Notification model
class AppNotification extends Equatable {

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.data,
    this.imageUrl,
    this.actionUrl,
    this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    this.targetId,
    this.message,
    this.isRead = false,
  });

  /// Create AppNotification from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      read: data['read'] ?? false,
      data: data['data'],
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      senderAvatarUrl: data['senderAvatarUrl'],
      targetId: data['targetId'],
      message: data['message'],
      isRead: data['isRead'] ?? false,
    );
  }
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? data; // JSON string with additional data
  final String? imageUrl;
  final String? actionUrl;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? targetId;
  final String? message;
  final bool isRead;

  /// Convert AppNotification to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'targetId': targetId,
      'message': message,
      'isRead': isRead,
    };
  }

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? read,
    String? data,
    String? imageUrl,
    String? actionUrl,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? targetId,
    String? message,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      targetId: targetId ?? this.targetId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }

  /// Get notification type icon
  String get typeIcon {
    switch (type) {
      case NotificationType.request:
        return '📋';
      case NotificationType.message:
        return '💬';
      case NotificationType.like:
        return '❤️';
      case NotificationType.comment:
        return '💭';
      case NotificationType.system:
        return '🔔';
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.promotion:
        return '🎉';
    }
  }

  /// Get notification type color
  String get typeColor {
    switch (type) {
      case NotificationType.request:
        return 'blue';
      case NotificationType.message:
        return 'green';
      case NotificationType.like:
        return 'red';
      case NotificationType.comment:
        return 'orange';
      case NotificationType.system:
        return 'grey';
      case NotificationType.reminder:
        return 'purple';
      case NotificationType.promotion:
        return 'yellow';
    }
  }

  /// Get notification type text
  String get typeText {
    switch (type) {
      case NotificationType.request:
        return 'Заявка';
      case NotificationType.message:
        return 'Сообщение';
      case NotificationType.like:
        return 'Лайк';
      case NotificationType.comment:
        return 'Комментарий';
      case NotificationType.system:
        return 'Система';
      case NotificationType.reminder:
        return 'Напоминание';
      case NotificationType.promotion:
        return 'Акция';
    }
  }

  /// Check if notification has action
  bool get hasAction => actionUrl != null && actionUrl!.isNotEmpty;

  /// Check if notification has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Check if notification has sender info
  bool get hasSender => senderId != null && senderName != null;

  /// Get parsed data as Map
  Map<String, dynamic>? get parsedData {
    if (data == null || data!.isEmpty) return null;
    try {
      // In a real app, you'd use jsonDecode here
      // For now, return null
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        body,
        createdAt,
        read,
        data,
        imageUrl,
        actionUrl,
        senderId,
        senderName,
        senderAvatarUrl,
        targetId,
        message,
        isRead,
      ];

  @override
  String toString() {
    return 'AppNotification(id: $id, userId: $userId, type: $type, title: $title)';
  }
}
