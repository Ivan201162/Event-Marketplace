import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы сообщений в чате
enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  system,
}

/// Статус сообщения
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Модель сообщения в чате
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.metadata,
    required this.status,
    required this.timestamp,
    this.editedAt,
    this.replyToMessageId,
    this.readBy = const [],
    this.isDeleted = false,
  });

  /// Создать сообщение из документа Firestore
  factory ChatMessage.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'],
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      content: data['content'] ?? '',
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      thumbnailUrl: data['thumbnailUrl'],
      metadata: data['metadata'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      replyToMessageId: data['replyToMessageId'],
      readBy: List<String>.from(data['readBy'] ?? []),
      isDeleted: data['isDeleted'] ?? false,
    );
  }
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? editedAt;
  final String? replyToMessageId;
  final List<String> readBy;
  final bool isDeleted;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'type': type.name,
        'content': content,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'thumbnailUrl': thumbnailUrl,
        'metadata': metadata,
        'status': status.name,
        'timestamp': Timestamp.fromDate(timestamp),
        'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
        'replyToMessageId': replyToMessageId,
        'readBy': readBy,
        'isDeleted': isDeleted,
      };

  /// Создать копию с изменениями
  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    String? content,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? editedAt,
    String? replyToMessageId,
    List<String>? readBy,
    bool? isDeleted,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderAvatar: senderAvatar ?? this.senderAvatar,
        type: type ?? this.type,
        content: content ?? this.content,
        fileUrl: fileUrl ?? this.fileUrl,
        fileName: fileName ?? this.fileName,
        fileSize: fileSize ?? this.fileSize,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        metadata: metadata ?? this.metadata,
        status: status ?? this.status,
        timestamp: timestamp ?? this.timestamp,
        editedAt: editedAt ?? this.editedAt,
        replyToMessageId: replyToMessageId ?? this.replyToMessageId,
        readBy: readBy ?? this.readBy,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  /// Проверить, является ли сообщение вложением
  bool get isAttachment =>
      type != MessageType.text && type != MessageType.system;

  /// Проверить, является ли сообщение медиафайлом
  bool get isMedia =>
      type == MessageType.image ||
      type == MessageType.video ||
      type == MessageType.audio;

  /// Проверить, является ли сообщение файлом
  bool get isFile => type == MessageType.file;

  /// Получить размер файла в читаемом формате
  String get formattedFileSize {
    if (fileSize == null) return '';

    final bytes = fileSize!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Получить иконку для типа сообщения
  String get typeIcon {
    switch (type) {
      case MessageType.text:
        return '💬';
      case MessageType.image:
        return '🖼️';
      case MessageType.video:
        return '🎥';
      case MessageType.audio:
        return '🎵';
      case MessageType.file:
        return '📎';
      case MessageType.location:
        return '📍';
      case MessageType.system:
        return 'ℹ️';
    }
  }

  /// Получить название типа сообщения
  String get typeName {
    switch (type) {
      case MessageType.text:
        return 'Текст';
      case MessageType.image:
        return 'Изображение';
      case MessageType.video:
        return 'Видео';
      case MessageType.audio:
        return 'Аудио';
      case MessageType.file:
        return 'Файл';
      case MessageType.location:
        return 'Местоположение';
      case MessageType.system:
        return 'Системное';
    }
  }

  /// Проверить, прочитано ли сообщение пользователем
  bool isReadBy(String userId) => readBy.contains(userId);

  /// Проверить, является ли сообщение ответом
  bool get isReply => replyToMessageId != null;

  /// Проверить, отредактировано ли сообщение
  bool get isEdited => editedAt != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChatMessage(id: $id, type: $type, content: $content, sender: $senderName)';
}

/// Модель чата
class Chat {
  const Chat({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.participants,
    required this.participantNames,
    required this.participantAvatars,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageType,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isGroup = false,
    this.createdBy,
    this.settings,
  });

  /// Создать чат из документа Firestore
  factory Chat.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Chat(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      avatar: data['avatar'],
      participants: List<String>.from(data['participants'] ?? []),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? {}),
      participantAvatars:
          Map<String, String>.from(data['participantAvatars'] ?? {}),
      lastMessageId: data['lastMessageId'],
      lastMessageContent: data['lastMessageContent'],
      lastMessageType: data['lastMessageType'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == data['lastMessageType'],
              orElse: () => MessageType.text,
            )
          : null,
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: data['unreadCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isGroup: data['isGroup'] ?? false,
      createdBy: data['createdBy'],
      settings: data['settings'],
    );
  }
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final String? lastMessageId;
  final String? lastMessageContent;
  final MessageType? lastMessageType;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isGroup;
  final String? createdBy;
  final Map<String, dynamic>? settings;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'avatar': avatar,
        'participants': participants,
        'participantNames': participantNames,
        'participantAvatars': participantAvatars,
        'lastMessageId': lastMessageId,
        'lastMessageContent': lastMessageContent,
        'lastMessageType': lastMessageType?.name,
        'lastMessageTime': lastMessageTime != null
            ? Timestamp.fromDate(lastMessageTime!)
            : null,
        'lastMessageSenderId': lastMessageSenderId,
        'unreadCount': unreadCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isGroup': isGroup,
        'createdBy': createdBy,
        'settings': settings,
      };

  /// Создать копию с изменениями
  Chat copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String>? participantAvatars,
    String? lastMessageId,
    String? lastMessageContent,
    MessageType? lastMessageType,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isGroup,
    String? createdBy,
    Map<String, dynamic>? settings,
  }) =>
      Chat(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        avatar: avatar ?? this.avatar,
        participants: participants ?? this.participants,
        participantNames: participantNames ?? this.participantNames,
        participantAvatars: participantAvatars ?? this.participantAvatars,
        lastMessageId: lastMessageId ?? this.lastMessageId,
        lastMessageContent: lastMessageContent ?? this.lastMessageContent,
        lastMessageType: lastMessageType ?? this.lastMessageType,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
        unreadCount: unreadCount ?? this.unreadCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isGroup: isGroup ?? this.isGroup,
        createdBy: createdBy ?? this.createdBy,
        settings: settings ?? this.settings,
      );

  /// Получить название чата для пользователя
  String getDisplayName(String currentUserId) {
    if (isGroup) {
      return name;
    } else {
      // Для личных чатов показываем имя собеседника
      final otherParticipant = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => participants.first,
      );
      return participantNames[otherParticipant] ?? 'Неизвестный пользователь';
    }
  }

  /// Получить аватар чата для пользователя
  String? getDisplayAvatar(String currentUserId) {
    if (isGroup) {
      return avatar;
    } else {
      // Для личных чатов показываем аватар собеседника
      final otherParticipant = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => participants.first,
      );
      return participantAvatars[otherParticipant];
    }
  }

  /// Проверить, является ли пользователь участником чата
  bool isParticipant(String userId) => participants.contains(userId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Chat(id: $id, name: $name, participants: ${participants.length})';
}
