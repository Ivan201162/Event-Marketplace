/// Расширенная модель сообщения
class EnhancedMessage {
  const EnhancedMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.createdAt,
    this.attachments = const [],
    this.replyTo,
    this.forwardedFrom,
    this.status = MessageStatus.sent,
    this.editedAt,
    this.deletedAt,
    this.reactions = const {},
    this.readBy = const {},
    this.metadata = const {},
  });

  /// Создать из Map
  factory EnhancedMessage.fromMap(Map<String, dynamic> map) => EnhancedMessage(
        id: map['id'] as String,
        chatId: map['chatId'] as String,
        senderId: map['senderId'] as String,
        text: map['text'] as String,
        type: MessageType.fromString(map['type'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        attachments: (map['attachments'] as List?)
                ?.map((attachment) => MessageAttachment.fromMap(
                    attachment as Map<String, dynamic>))
                .toList() ??
            [],
        replyTo: map['replyTo'] != null
            ? MessageReply.fromMap(map['replyTo'] as Map<String, dynamic>)
            : null,
        forwardedFrom: map['forwardedFrom'] != null
            ? MessageForward.fromMap(
                map['forwardedFrom'] as Map<String, dynamic>)
            : null,
        status: MessageStatus.fromString(map['status'] as String? ?? 'sent'),
        editedAt: map['editedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'] as int)
            : null,
        deletedAt: map['deletedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'] as int)
            : null,
        reactions: Map<String, List<String>>.from(
          (map['reactions'] as Map?)?.map(
                (key, value) =>
                    MapEntry(key as String, List<String>.from(value as List)),
              ) ??
              {},
        ),
        readBy: Map<String, DateTime>.from(
          (map['readBy'] as Map?)?.map(
                (key, value) => MapEntry(key as String,
                    DateTime.fromMillisecondsSinceEpoch(value as int)),
              ) ??
              {},
        ),
        metadata: Map<String, dynamic>.from((map['metadata'] as Map?) ?? {}),
      );

  /// Уникальный идентификатор
  final String id;

  /// ID чата
  final String chatId;

  /// ID отправителя
  final String senderId;

  /// Текст сообщения
  final String text;

  /// Тип сообщения
  final MessageType type;

  /// Дата создания
  final DateTime createdAt;

  /// Вложения
  final List<MessageAttachment> attachments;

  /// Ответ на сообщение
  final MessageReply? replyTo;

  /// Пересланное сообщение
  final MessageForward? forwardedFrom;

  /// Статус сообщения
  final MessageStatus status;

  /// Дата редактирования
  final DateTime? editedAt;

  /// Дата удаления
  final DateTime? deletedAt;

  /// Реакции на сообщение
  final Map<String, List<String>> reactions;

  /// Прочитано пользователями
  final Map<String, DateTime> readBy;

  /// Дополнительные данные
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'text': text,
        'type': type.value,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'attachments':
            attachments.map((attachment) => attachment.toMap()).toList(),
        'replyTo': replyTo?.toMap(),
        'forwardedFrom': forwardedFrom?.toMap(),
        'status': status.value,
        'editedAt': editedAt?.millisecondsSinceEpoch,
        'deletedAt': deletedAt?.millisecondsSinceEpoch,
        'reactions': reactions.map(
          MapEntry.new,
        ),
        'readBy': readBy.map(
          (key, value) => MapEntry(key, value.millisecondsSinceEpoch),
        ),
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  EnhancedMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    MessageType? type,
    DateTime? createdAt,
    List<MessageAttachment>? attachments,
    MessageReply? replyTo,
    MessageForward? forwardedFrom,
    MessageStatus? status,
    DateTime? editedAt,
    DateTime? deletedAt,
    Map<String, List<String>>? reactions,
    Map<String, DateTime>? readBy,
    Map<String, dynamic>? metadata,
  }) =>
      EnhancedMessage(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        text: text ?? this.text,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        attachments: attachments ?? this.attachments,
        replyTo: replyTo ?? this.replyTo,
        forwardedFrom: forwardedFrom ?? this.forwardedFrom,
        status: status ?? this.status,
        editedAt: editedAt ?? this.editedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        reactions: reactions ?? this.reactions,
        readBy: readBy ?? this.readBy,
        metadata: metadata ?? this.metadata,
      );
}

/// Тип сообщения
enum MessageType {
  text('text'),
  image('image'),
  video('video'),
  audio('audio'),
  document('document'),
  location('location'),
  contact('contact'),
  sticker('sticker'),
  system('system');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'document':
        return MessageType.document;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      case 'sticker':
        return MessageType.sticker;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  String get icon {
    switch (this) {
      case MessageType.text:
        return '💬';
      case MessageType.image:
        return '🖼️';
      case MessageType.video:
        return '🎥';
      case MessageType.audio:
        return '🎵';
      case MessageType.document:
        return '📄';
      case MessageType.location:
        return '📍';
      case MessageType.contact:
        return '👤';
      case MessageType.sticker:
        return '😀';
      case MessageType.system:
        return 'ℹ️';
    }
  }
}

/// Статус сообщения
enum MessageStatus {
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  const MessageStatus(this.value);
  final String value;

  static MessageStatus fromString(String value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  String get icon {
    switch (this) {
      case MessageStatus.sending:
        return '⏳';
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '✓✓';
      case MessageStatus.failed:
        return '❌';
    }
  }

  String get color {
    switch (this) {
      case MessageStatus.sending:
        return '#FFA500';
      case MessageStatus.sent:
        return '#6C757D';
      case MessageStatus.delivered:
        return '#6C757D';
      case MessageStatus.read:
        return '#007BFF';
      case MessageStatus.failed:
        return '#DC3545';
    }
  }
}

/// Вложение к сообщению
class MessageAttachment {
  const MessageAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
    this.thumbnailUrl,
    this.duration,
    this.width,
    this.height,
    this.metadata = const {},
  });

  factory MessageAttachment.fromMap(Map<String, dynamic> map) =>
      MessageAttachment(
        id: map['id'] as String,
        name: map['name'] as String,
        url: map['url'] as String,
        type: MessageAttachmentType.fromString(map['type'] as String),
        size: map['size'] as int,
        uploadedAt:
            DateTime.fromMillisecondsSinceEpoch(map['uploadedAt'] as int),
        thumbnailUrl: map['thumbnailUrl'] as String?,
        duration: map['duration'] != null
            ? Duration(milliseconds: map['duration'] as int)
            : null,
        width: map['width'] as int?,
        height: map['height'] as int?,
        metadata: Map<String, dynamic>.from((map['metadata'] as Map?) ?? {}),
      );

  final String id;
  final String name;
  final String url;
  final MessageAttachmentType type;
  final int size;
  final DateTime uploadedAt;
  final String? thumbnailUrl;
  final Duration? duration;
  final int? width;
  final int? height;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'url': url,
        'type': type.value,
        'size': size,
        'uploadedAt': uploadedAt.millisecondsSinceEpoch,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration?.inMilliseconds,
        'width': width,
        'height': height,
        'metadata': metadata,
      };
}

/// Тип вложения сообщения
enum MessageAttachmentType {
  image('image'),
  video('video'),
  audio('audio'),
  document('document'),
  voice('voice'),
  sticker('sticker');

  const MessageAttachmentType(this.value);
  final String value;

  static MessageAttachmentType fromString(String value) {
    switch (value) {
      case 'image':
        return MessageAttachmentType.image;
      case 'video':
        return MessageAttachmentType.video;
      case 'audio':
        return MessageAttachmentType.audio;
      case 'document':
        return MessageAttachmentType.document;
      case 'voice':
        return MessageAttachmentType.voice;
      case 'sticker':
        return MessageAttachmentType.sticker;
      default:
        return MessageAttachmentType.document;
    }
  }

  String get icon {
    switch (this) {
      case MessageAttachmentType.image:
        return '🖼️';
      case MessageAttachmentType.video:
        return '🎥';
      case MessageAttachmentType.audio:
        return '🎵';
      case MessageAttachmentType.document:
        return '📄';
      case MessageAttachmentType.voice:
        return '🎤';
      case MessageAttachmentType.sticker:
        return '😀';
    }
  }
}

/// Ответ на сообщение
class MessageReply {
  const MessageReply({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.type,
  });

  factory MessageReply.fromMap(Map<String, dynamic> map) => MessageReply(
        messageId: map['messageId'] as String,
        senderId: map['senderId'] as String,
        text: map['text'] as String,
        type: MessageType.fromString(map['type'] as String),
      );

  final String messageId;
  final String senderId;
  final String text;
  final MessageType type;

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'senderId': senderId,
        'text': text,
        'type': type.value,
      };
}

/// Пересланное сообщение
class MessageForward {
  const MessageForward({
    required this.originalMessageId,
    required this.originalChatId,
    required this.originalSenderId,
    required this.forwardedAt,
  });

  factory MessageForward.fromMap(Map<String, dynamic> map) => MessageForward(
        originalMessageId: map['originalMessageId'] as String,
        originalChatId: map['originalChatId'] as String,
        originalSenderId: map['originalSenderId'] as String,
        forwardedAt:
            DateTime.fromMillisecondsSinceEpoch(map['forwardedAt'] as int),
      );

  final String originalMessageId;
  final String originalChatId;
  final String originalSenderId;
  final DateTime forwardedAt;

  Map<String, dynamic> toMap() => {
        'originalMessageId': originalMessageId,
        'originalChatId': originalChatId,
        'originalSenderId': originalSenderId,
        'forwardedAt': forwardedAt.millisecondsSinceEpoch,
      };
}
