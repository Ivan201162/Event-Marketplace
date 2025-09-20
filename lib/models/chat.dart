import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы сообщений
enum MessageType {
  text, // Текстовое сообщение
  image, // Изображение
  file, // Файл
  system, // Системное сообщение
  bookingUpdate, // Обновление заявки
  paymentUpdate, // Обновление платежа
}

/// Статусы сообщений
enum MessageStatus {
  sent, // Отправлено
  delivered, // Доставлено
  read, // Прочитано
  failed, // Неудачно
}

/// Модель сообщения
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.receiverId,
    required this.type,
    required this.content,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.metadata,
    this.replyToMessageId,
    this.attachments = const [],
    this.senderName,
  });

  /// Создать из документа Firestore
  factory ChatMessage.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'],
      type: _parseMessageType(data['type']),
      content: data['content'] ?? '',
      status: _parseMessageStatus(data['status']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'],
      replyToMessageId: data['replyToMessageId'],
      attachments: List<String>.from(data['attachments'] ?? []),
      senderName: data['senderName'],
    );
  }
  final String id;
  final String chatId;
  final String senderId;
  final String? receiverId;
  final MessageType type;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final List<String> attachments;
  final String? senderName;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'type': type.name,
        'content': content,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
        'metadata': metadata,
        'replyToMessageId': replyToMessageId,
        'attachments': attachments,
        'senderName': senderName,
      };

  /// Копировать с изменениями
  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    MessageType? type,
    String? content,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    List<String>? attachments,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        receiverId: receiverId ?? this.receiverId,
        type: type ?? this.type,
        content: content ?? this.content,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        readAt: readAt ?? this.readAt,
        metadata: metadata ?? this.metadata,
        replyToMessageId: replyToMessageId ?? this.replyToMessageId,
        attachments: attachments ?? this.attachments,
      );

  /// Проверить, прочитано ли сообщение
  bool get isRead => status == MessageStatus.read;

  /// Проверить, доставлено ли сообщение
  bool get isDelivered => status == MessageStatus.delivered || isRead;

  /// Проверить, отправлено ли сообщение
  bool get isSent => status == MessageStatus.sent || isDelivered;

  /// Проверить, неудачно ли сообщение
  bool get isFailed => status == MessageStatus.failed;

  /// Получить отображаемое название типа сообщения
  String get typeDisplayName {
    switch (type) {
      case MessageType.text:
        return 'Текст';
      case MessageType.image:
        return 'Изображение';
      case MessageType.file:
        return 'Файл';
      case MessageType.system:
        return 'Системное';
      case MessageType.bookingUpdate:
        return 'Обновление заявки';
      case MessageType.paymentUpdate:
        return 'Обновление платежа';
    }
  }

  /// Парсинг типа сообщения
  static MessageType _parseMessageType(typeData) {
    if (typeData == null) return MessageType.text;

    final typeString = typeData.toString().toLowerCase();
    switch (typeString) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'bookingUpdate':
        return MessageType.bookingUpdate;
      case 'paymentUpdate':
        return MessageType.paymentUpdate;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  /// Парсинг статуса сообщения
  static MessageStatus _parseMessageStatus(statusData) {
    if (statusData == null) return MessageStatus.sent;

    final statusString = statusData.toString().toLowerCase();
    switch (statusString) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChatMessage(id: $id, type: $type, content: $content, status: $status)';
}

/// Модель чата
class Chat {
  const Chat({
    required this.id,
    required this.customerId,
    required this.specialistId,
    this.bookingId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isActive = true,
    this.metadata,
    this.title,
  });

  /// Создать из документа Firestore
  factory Chat.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      bookingId: data['bookingId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessage: data['lastMessage'] != null
          ? ChatMessage.fromDocument(data['lastMessage'])
          : null,
      unreadCount: data['unreadCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
      title: data['title'],
    );
  }
  final String id;
  final String customerId;
  final String specialistId;
  final String? bookingId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final String? title;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'specialistId': specialistId,
        'bookingId': bookingId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'lastMessage': lastMessage?.toMap(),
        'unreadCount': unreadCount,
        'isActive': isActive,
        'metadata': metadata,
        'title': title,
      };

  /// Копировать с изменениями
  Chat copyWith({
    String? id,
    String? customerId,
    String? specialistId,
    String? bookingId,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChatMessage? lastMessage,
    int? unreadCount,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) =>
      Chat(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        bookingId: bookingId ?? this.bookingId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        isActive: isActive ?? this.isActive,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, есть ли непрочитанные сообщения
  bool get hasUnreadMessages => unreadCount > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Chat(id: $id, customerId: $customerId, specialistId: $specialistId, unreadCount: $unreadCount)';
}
