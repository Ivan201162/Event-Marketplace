import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип участника группового чата
enum GroupChatParticipantType {
  organizer, // Организатор мероприятия
  specialist, // Специалист
  customer, // Заказчик
  guest, // Гость
}

/// Участник группового чата
class GroupChatParticipant {
  const GroupChatParticipant({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.type,
    required this.joinedAt,
    this.isActive = true,
    this.canSendMessages = true,
    this.canUploadFiles = true,
  });

  /// Создать из Map
  factory GroupChatParticipant.fromMap(Map<String, dynamic> data) =>
      GroupChatParticipant(
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? '',
        userPhoto: data['userPhoto'],
        type: GroupChatParticipantType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => GroupChatParticipantType.guest,
        ),
        joinedAt: (data['joinedAt'] as Timestamp).toDate(),
        isActive: data['isActive'] ?? true,
        canSendMessages: data['canSendMessages'] ?? true,
        canUploadFiles: data['canUploadFiles'] ?? true,
      );
  final String userId;
  final String userName;
  final String? userPhoto;
  final GroupChatParticipantType type;
  final DateTime joinedAt;
  final bool isActive;
  final bool canSendMessages;
  final bool canUploadFiles;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userPhoto': userPhoto,
        'type': type.name,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'isActive': isActive,
        'canSendMessages': canSendMessages,
        'canUploadFiles': canUploadFiles,
      };

  /// Создать копию с изменениями
  GroupChatParticipant copyWith({
    String? userId,
    String? userName,
    String? userPhoto,
    GroupChatParticipantType? type,
    DateTime? joinedAt,
    bool? isActive,
    bool? canSendMessages,
    bool? canUploadFiles,
  }) =>
      GroupChatParticipant(
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userPhoto: userPhoto ?? this.userPhoto,
        type: type ?? this.type,
        joinedAt: joinedAt ?? this.joinedAt,
        isActive: isActive ?? this.isActive,
        canSendMessages: canSendMessages ?? this.canSendMessages,
        canUploadFiles: canUploadFiles ?? this.canUploadFiles,
      );
}

/// Тип сообщения в групповом чате
enum GroupChatMessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  system,
  greeting, // Поздравление от гостя
}

/// Сообщение в групповом чате
class GroupChatMessage {
  const GroupChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.content,
    required this.type,
    required this.createdAt,
    this.editedAt,
    this.isEdited = false,
    this.replyToMessageId,
    this.metadata,
    this.readBy = const [],
    this.isPinned = false,
  });

  /// Создать из Map
  factory GroupChatMessage.fromMap(Map<String, dynamic> data) =>
      GroupChatMessage(
        id: data['id'] ?? '',
        chatId: data['chatId'] ?? '',
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? '',
        senderPhoto: data['senderPhoto'],
        content: data['content'] ?? '',
        type: GroupChatMessageType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => GroupChatMessageType.text,
        ),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        editedAt: data['editedAt'] != null
            ? (data['editedAt'] as Timestamp).toDate()
            : null,
        isEdited: data['isEdited'] ?? false,
        replyToMessageId: data['replyToMessageId'],
        metadata: data['metadata'],
        readBy: List<String>.from(data['readBy'] ?? []),
        isPinned: data['isPinned'] ?? false,
      );
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String content;
  final GroupChatMessageType type;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isEdited;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata;
  final List<String> readBy;
  final bool isPinned;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhoto': senderPhoto,
        'content': content,
        'type': type.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
        'isEdited': isEdited,
        'replyToMessageId': replyToMessageId,
        'metadata': metadata,
        'readBy': readBy,
        'isPinned': isPinned,
      };

  /// Создать копию с изменениями
  GroupChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhoto,
    String? content,
    GroupChatMessageType? type,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isEdited,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
    bool? isPinned,
  }) =>
      GroupChatMessage(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderPhoto: senderPhoto ?? this.senderPhoto,
        content: content ?? this.content,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt ?? this.editedAt,
        isEdited: isEdited ?? this.isEdited,
        replyToMessageId: replyToMessageId ?? this.replyToMessageId,
        metadata: metadata ?? this.metadata,
        readBy: readBy ?? this.readBy,
        isPinned: isPinned ?? this.isPinned,
      );
}

/// Групповой чат для мероприятия
class GroupChat {
  const GroupChat({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.organizerId,
    required this.organizerName,
    required this.participants,
    this.lastMessage,
    required this.lastActivityAt,
    this.unreadCount = 0,
    this.isActive = true,
    this.allowGuestUploads = true,
    this.allowGuestMessages = true,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  /// Создать из Map
  factory GroupChat.fromMap(Map<String, dynamic> data) => GroupChat(
        id: data['id'] ?? '',
        eventId: data['eventId'] ?? '',
        eventTitle: data['eventTitle'] ?? '',
        organizerId: data['organizerId'] ?? '',
        organizerName: data['organizerName'] ?? '',
        participants: (data['participants'] as List<dynamic>?)
                ?.map(
                  (p) =>
                      GroupChatParticipant.fromMap(p as Map<String, dynamic>),
                )
                .toList() ??
            [],
        lastMessage: data['lastMessage'] != null
            ? GroupChatMessage.fromMap(
                data['lastMessage'] as Map<String, dynamic>,
              )
            : null,
        lastActivityAt: (data['lastActivityAt'] as Timestamp).toDate(),
        unreadCount: data['unreadCount'] ?? 0,
        isActive: data['isActive'] ?? true,
        allowGuestUploads: data['allowGuestUploads'] ?? true,
        allowGuestMessages: data['allowGuestMessages'] ?? true,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        settings: data['settings'],
      );
  final String id;
  final String eventId;
  final String eventTitle;
  final String organizerId;
  final String organizerName;
  final List<GroupChatParticipant> participants;
  final GroupChatMessage? lastMessage;
  final DateTime lastActivityAt;
  final int unreadCount;
  final bool isActive;
  final bool allowGuestUploads;
  final bool allowGuestMessages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'participants': participants.map((p) => p.toMap()).toList(),
        'lastMessage': lastMessage?.toMap(),
        'lastActivityAt': Timestamp.fromDate(lastActivityAt),
        'unreadCount': unreadCount,
        'isActive': isActive,
        'allowGuestUploads': allowGuestUploads,
        'allowGuestMessages': allowGuestMessages,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'settings': settings,
      };

  /// Создать копию с изменениями
  GroupChat copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? organizerId,
    String? organizerName,
    List<GroupChatParticipant>? participants,
    GroupChatMessage? lastMessage,
    DateTime? lastActivityAt,
    int? unreadCount,
    bool? isActive,
    bool? allowGuestUploads,
    bool? allowGuestMessages,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
  }) =>
      GroupChat(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        eventTitle: eventTitle ?? this.eventTitle,
        organizerId: organizerId ?? this.organizerId,
        organizerName: organizerName ?? this.organizerName,
        participants: participants ?? this.participants,
        lastMessage: lastMessage ?? this.lastMessage,
        lastActivityAt: lastActivityAt ?? this.lastActivityAt,
        unreadCount: unreadCount ?? this.unreadCount,
        isActive: isActive ?? this.isActive,
        allowGuestUploads: allowGuestUploads ?? this.allowGuestUploads,
        allowGuestMessages: allowGuestMessages ?? this.allowGuestMessages,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        settings: settings ?? this.settings,
      );

  /// Получить количество участников
  int get participantsCount => participants.length;

  /// Получить активных участников
  List<GroupChatParticipant> get activeParticipants =>
      participants.where((p) => p.isActive).toList();

  /// Проверить, является ли пользователь участником
  bool isParticipant(String userId) =>
      participants.any((p) => p.userId == userId && p.isActive);

  /// Получить тип участника
  GroupChatParticipantType? getParticipantType(String userId) {
    final participant = participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => throw StateError('Participant not found'),
    );
    return participant.type;
  }

  /// Проверить, может ли пользователь отправлять сообщения
  bool canUserSendMessages(String userId) {
    final participant = participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => throw StateError('Participant not found'),
    );

    if (participant.type == GroupChatParticipantType.guest) {
      return allowGuestMessages && participant.canSendMessages;
    }

    return participant.canSendMessages;
  }

  /// Проверить, может ли пользователь загружать файлы
  bool canUserUploadFiles(String userId) {
    final participant = participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => throw StateError('Participant not found'),
    );

    if (participant.type == GroupChatParticipantType.guest) {
      return allowGuestUploads && participant.canUploadFiles;
    }

    return participant.canUploadFiles;
  }
}
