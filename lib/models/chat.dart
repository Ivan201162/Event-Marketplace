import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы сообщений
enum MessageType {
  text, // Текстовое сообщение
  image, // Изображение
  video, // Видео
  audio, // Аудио
  document, // Документ
  file, // Файл
  attachment, // Вложение
  location, // Местоположение
  system, // Системное сообщение
  bookingUpdate, // Обновление заявки
  paymentUpdate, // Обновление платежа
}

/// Статусы сообщений
enum MessageStatus {
  sending, // Отправляется
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
    this.fileUrl,
    this.timestamp,
    this.isFromCurrentUser,
    this.fileName,
    this.fileSize,
    this.editedAt,
    this.thumbnailUrl,
  });

  /// Создать из Map
  factory ChatMessage.fromMap(Map<String, dynamic> data, [String? id]) =>
      ChatMessage(
        id: id ?? data['id'] ?? '',
        chatId: data['chatId'] ?? '',
        senderId: data['senderId'] ?? '',
        receiverId: data['receiverId'],
        type: _parseMessageType(data['type']),
        content: data['content'] ?? '',
        status: _parseMessageStatus(data['status']),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
            : DateTime.now(),
        readAt: data['readAt'] != null
            ? (data['readAt'] is Timestamp
                ? (data['readAt'] as Timestamp).toDate()
                : DateTime.parse(data['readAt'].toString()))
            : null,
        metadata: data['metadata'] as Map<String, dynamic>?,
        replyToMessageId: data['replyToMessageId'],
        attachments: List<String>.from(data['attachments'] ?? []),
        senderName: data['senderName'],
        fileUrl: data['fileUrl'],
        timestamp: data['timestamp'] != null
            ? (data['timestamp'] is Timestamp
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.parse(data['timestamp'].toString()))
            : null,
        isFromCurrentUser: data['isFromCurrentUser'] as bool?,
        fileName: data['fileName'] as String?,
        fileSize: data['fileSize'] as int?,
        editedAt: data['editedAt'] != null
            ? (data['editedAt'] is Timestamp
                ? (data['editedAt'] as Timestamp).toDate()
                : DateTime.parse(data['editedAt'].toString()))
            : null,
        thumbnailUrl: data['thumbnailUrl'] as String?,
      );

  /// Создать из документа Firestore
  factory ChatMessage.fromDocument(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    // Безопасное преобразование данных
    Map<String, dynamic> safeData;
    if (data is Map<String, dynamic>) {
      safeData = data;
    } else if (data is Map<dynamic, dynamic>) {
      safeData = data.map((key, value) => MapEntry(key.toString(), value));
    } else {
      throw Exception('Document data is not a Map: ${data.runtimeType}');
    }

    return ChatMessage(
      id: doc.id,
      chatId: safeData['chatId'] as String? ?? '',
      senderId: safeData['senderId'] as String? ?? '',
      receiverId: safeData['receiverId'] as String?,
      type: _parseMessageType(safeData['type']),
      content: safeData['content'] as String? ?? '',
      status: _parseMessageStatus(safeData['status']),
      createdAt: safeData['createdAt'] != null
          ? (safeData['createdAt'] is Timestamp
              ? (safeData['createdAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['createdAt'].toString()))
          : DateTime.now(),
      readAt: safeData['readAt'] != null
          ? (safeData['readAt'] is Timestamp
              ? (safeData['readAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['readAt'].toString()))
          : null,
      metadata: safeData['metadata'] as Map<String, dynamic>?,
      replyToMessageId: safeData['replyToMessageId'] as String?,
      attachments:
          List<String>.from(safeData['attachments'] as List<dynamic>? ?? []),
      senderName: safeData['senderName'] as String?,
      fileUrl: safeData['fileUrl'] as String?,
      timestamp: safeData['timestamp'] != null
          ? (safeData['timestamp'] is Timestamp
              ? (safeData['timestamp'] as Timestamp).toDate()
              : DateTime.parse(safeData['timestamp'].toString()))
          : null,
      isFromCurrentUser: safeData['isFromCurrentUser'] as bool?,
      fileName: safeData['fileName'] as String?,
      fileSize: safeData['fileSize'] as int?,
      editedAt: safeData['editedAt'] != null
          ? (safeData['editedAt'] is Timestamp
              ? (safeData['editedAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['editedAt'].toString()))
          : null,
      thumbnailUrl: safeData['thumbnailUrl'] as String?,
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
  final String? fileUrl;
  final DateTime? timestamp;
  final bool? isFromCurrentUser;
  final String? fileName;
  final int? fileSize;
  final DateTime? editedAt;
  final String? thumbnailUrl;

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
        'fileUrl': fileUrl,
        'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
        'isFromCurrentUser': isFromCurrentUser,
        'fileName': fileName,
        'fileSize': fileSize,
        'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
        'thumbnailUrl': thumbnailUrl,
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
    String? senderName,
    String? fileUrl,
    DateTime? timestamp,
    bool? isFromCurrentUser,
    String? fileName,
    int? fileSize,
    DateTime? editedAt,
    String? thumbnailUrl,
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
        senderName: senderName ?? this.senderName,
        fileUrl: fileUrl ?? this.fileUrl,
        timestamp: timestamp ?? this.timestamp,
        isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
        fileName: fileName ?? this.fileName,
        fileSize: fileSize ?? this.fileSize,
        editedAt: editedAt ?? this.editedAt,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      );

  /// Проверить, прочитано ли сообщение
  bool get isRead => status == MessageStatus.read;

  /// Проверить, доставлено ли сообщение
  bool get isDelivered => status == MessageStatus.delivered || isRead;

  /// Проверить, отправлено ли сообщение
  bool get isSent => status == MessageStatus.sent || isDelivered;

  /// Проверить, неудачно ли сообщение
  bool get isFailed => status == MessageStatus.failed;

  /// Получить название типа сообщения
  String get typeName => typeDisplayName;

  /// Проверить, отредактировано ли сообщение
  bool get isEdited => editedAt != null;

  /// Получить отформатированный размер файла
  String get formattedFileSize {
    if (fileSize == null) return '';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = fileSize!;
    var unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size ~/= 1024;
      unitIndex++;
    }
    
    return '$size ${units[unitIndex]}';
  }

  /// Получить отображаемое название типа сообщения
  String get typeDisplayName {
    switch (type) {
      case MessageType.text:
        return 'Текст';
      case MessageType.image:
        return 'Изображение';
      case MessageType.video:
        return 'Видео';
      case MessageType.audio:
        return 'Аудио';
      case MessageType.document:
        return 'Документ';
      case MessageType.attachment:
        return 'Вложение';
      case MessageType.location:
        return 'Местоположение';
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
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'document':
        return MessageType.document;
      case 'attachment':
        return MessageType.attachment;
      case 'location':
        return MessageType.location;
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
      case 'sending':
        return MessageStatus.sending;
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
    this.name,
    this.participants = const [],
    this.participantNames = const {},
    this.participantAvatars = const {},
    this.lastMessageContent,
    this.lastMessageTime,
  });

  /// Создать из документа Firestore
  factory Chat.fromDocument(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    // Безопасное преобразование данных
    Map<String, dynamic> safeData;
    if (data is Map<String, dynamic>) {
      safeData = data;
    } else if (data is Map<dynamic, dynamic>) {
      safeData = data.map((key, value) => MapEntry(key.toString(), value));
    } else {
      throw Exception('Document data is not a Map: ${data.runtimeType}');
    }

    return Chat(
      id: doc.id,
      customerId: safeData['customerId'] as String? ?? '',
      specialistId: safeData['specialistId'] as String? ?? '',
      bookingId: safeData['bookingId'] as String?,
      createdAt: safeData['createdAt'] != null
          ? (safeData['createdAt'] is Timestamp
              ? (safeData['createdAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: safeData['updatedAt'] != null
          ? (safeData['updatedAt'] is Timestamp
              ? (safeData['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['updatedAt'].toString()))
          : DateTime.now(),
      lastMessage: safeData['lastMessage'] != null
          ? ChatMessage.fromDocument(
              safeData['lastMessage'] as DocumentSnapshot,)
          : null,
      unreadCount: safeData['unreadCount'] as int? ?? 0,
      isActive: safeData['isActive'] as bool? ?? true,
      metadata: safeData['metadata'] as Map<String, dynamic>?,
      title: safeData['title'] as String?,
      name: safeData['name'] as String?,
      participants: List<String>.from(safeData['participants'] ?? []),
      participantNames: Map<String, String>.from(safeData['participantNames'] ?? {}),
      participantAvatars: Map<String, String>.from(safeData['participantAvatars'] ?? {}),
      lastMessageContent: safeData['lastMessageContent'] as String?,
      lastMessageTime: safeData['lastMessageTime'] != null
          ? (safeData['lastMessageTime'] is Timestamp
              ? (safeData['lastMessageTime'] as Timestamp).toDate()
              : DateTime.parse(safeData['lastMessageTime'].toString()))
          : null,
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
  final String? name;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;

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
        'name': name,
        'participants': participants,
        'participantNames': participantNames,
        'participantAvatars': participantAvatars,
        'lastMessageContent': lastMessageContent,
        'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
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
    String? title,
    String? name,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String>? participantAvatars,
    String? lastMessageContent,
    DateTime? lastMessageTime,
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
        title: title ?? this.title,
        name: name ?? this.name,
        participants: participants ?? this.participants,
        participantNames: participantNames ?? this.participantNames,
        participantAvatars: participantAvatars ?? this.participantAvatars,
        lastMessageContent: lastMessageContent ?? this.lastMessageContent,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
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

  /// Получить имя собеседника
  String getDisplayName(String currentUserId) {
    if (participantNames.isNotEmpty) {
      final otherParticipantId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => participants.first,
      );
      return participantNames[otherParticipantId] ?? 'Пользователь';
    }
    
    if (currentUserId == customerId) {
      return 'Специалист';
    } else {
      return 'Клиент';
    }
  }

  /// Получить аватар собеседника
  String? getDisplayAvatar(String currentUserId) {
    if (participantAvatars.isNotEmpty) {
      final otherParticipantId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => participants.first,
      );
      return participantAvatars[otherParticipantId];
    }
    return null;
  }

  /// Получить время последнего сообщения
  DateTime? get lastMessageTimeValue => lastMessageTime ?? lastMessage?.createdAt;

  /// Получить содержимое последнего сообщения
  String? get lastMessageContentValue => lastMessageContent ?? lastMessage?.content;

  /// Получить список участников
  List<String> get participantsList => participants.isNotEmpty ? participants : [customerId, specialistId];

  @override
  String toString() =>
      'Chat(id: $id, customerId: $customerId, specialistId: $specialistId, unreadCount: $unreadCount)';
}
