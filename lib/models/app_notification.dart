import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Модель уведомления
class AppNotification extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type;
  final String userId;
  final String? senderId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.userId,
    this.senderId,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  /// Создает уведомление из Firestore документа
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'system',
      userId: data['userId'] ?? '',
      senderId: data['senderId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  /// Создает уведомление из Map
  factory AppNotification.fromMap(Map<String, dynamic> data) {
    return AppNotification(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'system',
      userId: data['userId'] ?? '',
      senderId: data['senderId'],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  /// Преобразует уведомление в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'userId': userId,
      'senderId': senderId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }

  /// Создает копию уведомления с обновленными полями
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? userId,
    String? senderId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        userId,
        senderId,
        isRead,
        createdAt,
        data,
      ];
}
