import 'message_status.dart';

/// Тип сообщения
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
}

/// Модель сообщения чата
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderAvatar;
  final String text;
  final MessageType type;
  final List<String> attachments;
  final Map<String, String> reactions;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderAvatar,
    required this.text,
    required this.type,
    required this.attachments,
    required this.reactions,
    required this.createdAt,
    this.editedAt,
    required this.isRead,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderAvatar: map['senderAvatar'],
      text: map['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      attachments: List<String>.from(map['attachments'] ?? []),
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      editedAt: map['editedAt'] != null ? DateTime.parse(map['editedAt']) : null,
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderAvatar': senderAvatar,
      'text': text,
      'type': type.name,
      'attachments': attachments,
      'reactions': reactions,
      'createdAt': createdAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isRead': isRead,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderAvatar,
    String? text,
    MessageType? type,
    List<String>? attachments,
    Map<String, String>? reactions,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      text: text ?? this.text,
      type: type ?? this.type,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Проверяет, отправлено ли сообщение от указанного пользователя
  bool isFromUser(String userId) {
    return senderId == userId;
  }

  /// Проверяет, является ли сообщение системным
  bool get isSystemMessage {
    return senderId == 'system';
  }

  /// Получает контент сообщения
  String get content {
    return text;
  }

  /// Получает отформатированное время
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}д';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'сейчас';
    }
  }

  /// Получает статус сообщения
  MessageStatus get status {
    if (isRead) return MessageStatus.read;
    if (createdAt.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      return MessageStatus.delivered;
    }
    return MessageStatus.sent;
  }
}