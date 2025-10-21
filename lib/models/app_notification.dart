import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Notification type enum
enum NotificationType {
  message,
  booking,
  payment,
  review,
  system,
  promotion,
  reminder,
}

/// Notification status enum
enum NotificationStatus {
  unread,
  read,
  archived,
}

/// App notification model
class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final bool isImportant;
  final DateTime? expiresAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.data,
    this.imageUrl,
    this.actionUrl,
    this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    this.isImportant = false,
    this.expiresAt,
  });

  /// Create AppNotification from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
      data: data['data'] as Map<String, dynamic>?,
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      senderAvatarUrl: data['senderAvatarUrl'],
      isImportant: data['isImportant'] ?? false,
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
    );
  }

  /// Convert AppNotification to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'isImportant': isImportant,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    bool? isImportant,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      isImportant: isImportant ?? this.isImportant,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Check if notification is read
  bool get isRead => status == NotificationStatus.read;

  /// Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get time ago string
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

  /// Get notification icon
  String get icon {
    switch (type) {
      case NotificationType.message:
        return '💬';
      case NotificationType.booking:
        return '📅';
      case NotificationType.payment:
        return '💳';
      case NotificationType.review:
        return '⭐';
      case NotificationType.system:
        return '🔔';
      case NotificationType.promotion:
        return '🎉';
      case NotificationType.reminder:
        return '⏰';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        type,
        status,
        createdAt,
        readAt,
        data,
        imageUrl,
        actionUrl,
        senderId,
        senderName,
        senderAvatarUrl,
        isImportant,
        expiresAt,
      ];

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, type: $type, status: $status)';
  }
}
