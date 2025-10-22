import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Типы сообщений
enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  system('system');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Статус сообщения
enum MessageStatus {
  sent('sent'),
  delivered('delivered'),
  read('read');

  const MessageStatus(this.value);
  final String value;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MessageStatus.sent,
    );
  }
}

/// Модель сообщения в чате
class ChatMessage extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String? receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final bool isEdited;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.replyToMessageId,
    this.isEdited = false,
  });

  /// Создать ChatMessage из Firestore документа
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'],
      content: data['content'] ?? '',
      type: MessageType.fromString(data['type'] ?? 'text'),
      status: MessageStatus.fromString(data['status'] ?? 'sent'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      replyToMessageId: data['replyToMessageId'],
      isEdited: data['isEdited'] ?? false,
    );
  }

  /// Конвертировать ChatMessage в Firestore документ
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.value,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'isEdited': isEdited,
    };
  }

  /// Создать копию с обновленными полями
  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    bool? isEdited,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  /// Проверить, является ли сообщение системным
  bool get isSystemMessage => type == MessageType.system;

  /// Проверить, является ли сообщение от текущего пользователя
  bool isFromUser(String userId) => senderId == userId;

  /// Получить отформатированное время
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
    } else if (difference.inHours > 0) {
      return '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      return 'только что';
    }
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        receiverId,
        content,
        type,
        status,
        createdAt,
        updatedAt,
        metadata,
        replyToMessageId,
        isEdited,
      ];

  @override
  String toString() {
    return 'ChatMessage(id: $id, chatId: $chatId, senderId: $senderId, content: $content, type: $type, status: $status)';
  }
}
