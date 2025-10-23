import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Unified notification model
class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? data;
  final String? imageUrl;
  final String? actionUrl;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? targetId;
  final String? message;
  final bool isRead;

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
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
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

  /// Convert AppNotification to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
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
    String? type,
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
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
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
