import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Модель сообщения
class Message extends Equatable {
  final String id;
  final String chatId;
  final String text;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final DateTime timestamp;
  final bool read;
  final DateTime? readAt;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? formattedFileSize;
  final DateTime? createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.text,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.timestamp,
    this.read = false,
    this.readAt,
    this.type = MessageType.text,
    this.metadata,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.formattedFileSize,
    this.createdAt,
  });

  /// Создание сообщения из Firestore документа
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'],
      senderAvatar: data['senderAvatar'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] ?? false,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      type: MessageType.values.firstWhere(
        (type) => type.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'type': type.name,
      'metadata': metadata,
    };
  }

  /// Создание копии с обновленными полями
  Message copyWith({
    String? id,
    String? chatId,
    String? text,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    DateTime? timestamp,
    bool? read,
    DateTime? readAt,
    MessageType? type,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Проверка, является ли сообщение отправленным текущим пользователем
  bool isFromUser(String userId) {
    return senderId == userId;
  }

  /// Проверка, является ли сообщение прочитанным
  bool get isRead => read;

  /// Получение времени в удобном формате
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

  /// Получение времени в формате HH:MM
  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        text,
        senderId,
        senderName,
        senderAvatar,
        timestamp,
        read,
        readAt,
        type,
        metadata,
      ];
}

/// Типы сообщений
enum MessageType {
  text,
  image,
  file,
  system,
  video,
  audio,
  document,
  location,
  attachment,
}

/// Модель для отображения чата с информацией о собеседнике
class ChatWithUser extends Equatable {
  final Chat chat;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool isOnline;

  const ChatWithUser({
    required this.chat,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.isOnline = false,
  });

  /// Получение отображаемого имени собеседника
  String get displayName {
    return otherUserName ?? 'Пользователь';
  }

  /// Получение отображаемого аватара собеседника
  String? get displayAvatar {
    return otherUserAvatar;
  }

  /// Проверка, есть ли непрочитанные сообщения
  bool get hasUnreadMessages {
    return chat.hasUnreadMessages(chat.participants.first);
  }

  /// Получение количества непрочитанных сообщений
  int get unreadCount {
    return chat.getUnreadCount(chat.participants.first);
  }

  @override
  List<Object?> get props => [
        chat,
        otherUserId,
        otherUserName,
        otherUserAvatar,
        isOnline,
      ];
}
