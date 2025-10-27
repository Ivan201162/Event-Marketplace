import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Типы чатов
enum ChatType {
  personal('personal', 'Личный'),
  group('group', 'Групповой'),
  request('request', 'Заявка'),
  support('support', 'Поддержка');

  const ChatType(this.value, this.label);
  final String value;
  final String label;
}

/// Типы сообщений
enum MessageType {
  text('text', 'Текст'),
  image('image', 'Изображение'),
  video('video', 'Видео'),
  audio('audio', 'Аудио'),
  file('file', 'Файл'),
  location('location', 'Локация'),
  sticker('sticker', 'Стикер'),
  gif('gif', 'GIF'),
  reaction('reaction', 'Реакция'),
  system('system', 'Системное');

  const MessageType(this.value, this.label);
  final String value;
  final String label;
}

/// Статусы сообщений
enum MessageStatus {
  sending('sending', 'Отправляется'),
  sent('sent', 'Отправлено'),
  delivered('delivered', 'Доставлено'),
  read('read', 'Прочитано'),
  failed('failed', 'Ошибка');

  const MessageStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Расширенная модель чата
class ChatEnhanced extends Equatable {
  final String id;
  final String name;
  final String description;
  final String avatar;
  final ChatType type;
  final List<String> participants;
  final List<String> admins;
  final String? lastMessageId;
  final String? lastMessageText;
  final String? lastMessageAuthorId;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? requestId;
  final String? groupId;
  final Map<String, dynamic> settings;
  final List<String> sharedFiles;
  final Map<String, dynamic> analytics;

  const ChatEnhanced({
    required this.id,
    required this.name,
    required this.description,
    required this.avatar,
    required this.type,
    required this.participants,
    required this.admins,
    this.lastMessageId,
    this.lastMessageText,
    this.lastMessageAuthorId,
    this.lastMessageTime,
    required this.unreadCount,
    required this.isMuted,
    required this.isPinned,
    required this.isArchived,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    this.requestId,
    this.groupId,
    required this.settings,
    required this.sharedFiles,
    required this.analytics,
  });

  /// Создание из Firestore документа
  factory ChatEnhanced.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatEnhanced(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      avatar: data['avatar'] ?? '',
      type: ChatType.values.firstWhere(
        (e) => e.value == data['type'],
        orElse: () => ChatType.personal,
      ),
      participants: List<String>.from(data['participants'] ?? []),
      admins: List<String>.from(data['admins'] ?? []),
      lastMessageId: data['lastMessageId'],
      lastMessageText: data['lastMessageText'],
      lastMessageAuthorId: data['lastMessageAuthorId'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      isMuted: data['isMuted'] ?? false,
      isPinned: data['isPinned'] ?? false,
      isArchived: data['isArchived'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      requestId: data['requestId'],
      groupId: data['groupId'],
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      sharedFiles: List<String>.from(data['sharedFiles'] ?? []),
      analytics: Map<String, dynamic>.from(data['analytics'] ?? {}),
    );
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'avatar': avatar,
      'type': type.value,
      'participants': participants,
      'admins': admins,
      'lastMessageId': lastMessageId,
      'lastMessageText': lastMessageText,
      'lastMessageAuthorId': lastMessageAuthorId,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'requestId': requestId,
      'groupId': groupId,
      'settings': settings,
      'sharedFiles': sharedFiles,
      'analytics': analytics,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        avatar,
        type,
        participants,
        admins,
        lastMessageId,
        lastMessageText,
        lastMessageAuthorId,
        lastMessageTime,
        unreadCount,
        isMuted,
        isPinned,
        isArchived,
        metadata,
        createdAt,
        updatedAt,
        tags,
        requestId,
        groupId,
        settings,
        sharedFiles,
        analytics,
      ];
}

/// Расширенная модель сообщения
class ChatMessageEnhanced extends Equatable {
  final String id;
  final String chatId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? readAt;
  final String? replyToMessageId;
  final String? replyToMessageContent;
  final List<String> attachments;
  final Map<String, dynamic> metadata;
  final List<MessageReaction> reactions;
  final List<String> readBy;
  final List<String> forwardedTo;
  final bool isEdited;
  final bool isDeleted;
  final String? deletedBy;
  final DateTime? deletedAt;
  final Map<String, dynamic> analytics;

  const ChatMessageEnhanced({
    required this.id,
    required this.chatId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.editedAt,
    this.readAt,
    this.replyToMessageId,
    this.replyToMessageContent,
    required this.attachments,
    required this.metadata,
    required this.reactions,
    required this.readBy,
    required this.forwardedTo,
    required this.isEdited,
    required this.isDeleted,
    this.deletedBy,
    this.deletedAt,
    required this.analytics,
  });

  /// Создание из Firestore документа
  factory ChatMessageEnhanced.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageEnhanced(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.value == data['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.value == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      replyToMessageId: data['replyToMessageId'],
      replyToMessageContent: data['replyToMessageContent'],
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      reactions: (data['reactions'] as List<dynamic>?)
              ?.map((e) => MessageReaction.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      readBy: List<String>.from(data['readBy'] ?? []),
      forwardedTo: List<String>.from(data['forwardedTo'] ?? []),
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      deletedBy: data['deletedBy'],
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      analytics: Map<String, dynamic>.from(data['analytics'] ?? {}),
    );
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'type': type.value,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'replyToMessageId': replyToMessageId,
      'replyToMessageContent': replyToMessageContent,
      'attachments': attachments,
      'metadata': metadata,
      'reactions': reactions.map((e) => e.toMap()).toList(),
      'readBy': readBy,
      'forwardedTo': forwardedTo,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'analytics': analytics,
    };
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        authorId,
        authorName,
        authorAvatar,
        content,
        type,
        status,
        createdAt,
        editedAt,
        readAt,
        replyToMessageId,
        replyToMessageContent,
        attachments,
        metadata,
        reactions,
        readBy,
        forwardedTo,
        isEdited,
        isDeleted,
        deletedBy,
        deletedAt,
        analytics,
      ];
}

/// Реакция на сообщение
class MessageReaction extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String emoji;
  final DateTime createdAt;

  const MessageReaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      emoji: map['emoji'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'emoji': emoji,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, userName, emoji, createdAt];
}

/// Фильтры для чатов
class ChatFilters extends Equatable {
  final ChatType? type;
  final bool? isMuted;
  final bool? isPinned;
  final bool? isArchived;
  final String? searchQuery;
  final List<String>? tags;
  final String? requestId;
  final String? groupId;
  final DateTime? startDate;
  final DateTime? endDate;

  const ChatFilters({
    this.type,
    this.isMuted,
    this.isPinned,
    this.isArchived,
    this.searchQuery,
    this.tags,
    this.requestId,
    this.groupId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        type,
        isMuted,
        isPinned,
        isArchived,
        searchQuery,
        tags,
        requestId,
        groupId,
        startDate,
        endDate,
      ];
}

/// Фильтры для сообщений
class MessageFilters extends Equatable {
  final MessageType? type;
  final String? authorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final bool? hasAttachments;
  final bool? hasReactions;
  final bool? isEdited;
  final bool? isDeleted;

  const MessageFilters({
    this.type,
    this.authorId,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.hasAttachments,
    this.hasReactions,
    this.isEdited,
    this.isDeleted,
  });

  @override
  List<Object?> get props => [
        type,
        authorId,
        startDate,
        endDate,
        searchQuery,
        hasAttachments,
        hasReactions,
        isEdited,
        isDeleted,
      ];
}
