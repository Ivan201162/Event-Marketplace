import 'enhanced_message.dart';

/// Расширенная модель чата
class EnhancedChat {
  const EnhancedChat({
    required this.id,
    required this.type,
    required this.members,
    required this.createdAt,
    this.name,
    this.description,
    this.avatarUrl,
    this.lastMessage,
    this.updatedAt,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.settings = const ChatSettings(),
    this.metadata = const {},
  });

  /// Создать из Map
  factory EnhancedChat.fromMap(Map<String, dynamic> map) => EnhancedChat(
        id: map['id'] as String,
        type: ChatType.fromString(map['type'] as String),
        members: (map['members'] as List?)
                ?.map(
                  (member) =>
                      ChatMember.fromMap(member as Map<String, dynamic>),
                )
                .toList() ??
            [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        name: map['name'] as String?,
        description: map['description'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        lastMessage: map['lastMessage'] != null
            ? ChatLastMessage.fromMap(
                map['lastMessage'] as Map<String, dynamic>,
              )
            : null,
        updatedAt: map['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
            : null,
        isPinned: (map['isPinned'] as bool?) ?? false,
        isMuted: (map['isMuted'] as bool?) ?? false,
        isArchived: (map['isArchived'] as bool?) ?? false,
        settings: map['settings'] != null
            ? ChatSettings.fromMap(map['settings'] as Map<String, dynamic>)
            : const ChatSettings(),
        metadata: Map<String, dynamic>.from((map['metadata'] as Map?) ?? {}),
      );

  /// Уникальный идентификатор
  final String id;

  /// Тип чата
  final ChatType type;

  /// Участники чата
  final List<ChatMember> members;

  /// Дата создания
  final DateTime createdAt;

  /// Название чата
  final String? name;

  /// Описание чата
  final String? description;

  /// Аватар чата
  final String? avatarUrl;

  /// Последнее сообщение
  final ChatLastMessage? lastMessage;

  /// Дата обновления
  final DateTime? updatedAt;

  /// Закреплён ли чат
  final bool isPinned;

  /// Заглушен ли чат
  final bool isMuted;

  /// Архивирован ли чат
  final bool isArchived;

  /// Настройки чата
  final ChatSettings settings;

  /// Дополнительные данные
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.value,
        'members': members.map((member) => member.toMap()).toList(),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'name': name,
        'description': description,
        'avatarUrl': avatarUrl,
        'lastMessage': lastMessage?.toMap(),
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'isPinned': isPinned,
        'isMuted': isMuted,
        'isArchived': isArchived,
        'settings': settings.toMap(),
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  EnhancedChat copyWith({
    String? id,
    ChatType? type,
    List<ChatMember>? members,
    DateTime? createdAt,
    String? name,
    String? description,
    String? avatarUrl,
    ChatLastMessage? lastMessage,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    ChatSettings? settings,
    Map<String, dynamic>? metadata,
  }) =>
      EnhancedChat(
        id: id ?? this.id,
        type: type ?? this.type,
        members: members ?? this.members,
        createdAt: createdAt ?? this.createdAt,
        name: name ?? this.name,
        description: description ?? this.description,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        lastMessage: lastMessage ?? this.lastMessage,
        updatedAt: updatedAt ?? this.updatedAt,
        isPinned: isPinned ?? this.isPinned,
        isMuted: isMuted ?? this.isMuted,
        isArchived: isArchived ?? this.isArchived,
        settings: settings ?? this.settings,
        metadata: metadata ?? this.metadata,
      );
}

/// Тип чата
enum ChatType {
  direct('direct'),
  group('group'),
  channel('channel'),
  support('support');

  const ChatType(this.value);
  final String value;

  static ChatType fromString(String value) {
    switch (value) {
      case 'direct':
        return ChatType.direct;
      case 'group':
        return ChatType.group;
      case 'channel':
        return ChatType.channel;
      case 'support':
        return ChatType.support;
      default:
        return ChatType.direct;
    }
  }

  String get displayName {
    switch (this) {
      case ChatType.direct:
        return 'Личный чат';
      case ChatType.group:
        return 'Групповой чат';
      case ChatType.channel:
        return 'Канал';
      case ChatType.support:
        return 'Поддержка';
    }
  }

  String get icon {
    switch (this) {
      case ChatType.direct:
        return '💬';
      case ChatType.group:
        return '👥';
      case ChatType.channel:
        return '📢';
      case ChatType.support:
        return '🆘';
    }
  }
}

/// Участник чата
class ChatMember {
  const ChatMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.nickname,
    this.permissions = const ChatPermissions(),
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatMember.fromMap(Map<String, dynamic> map) => ChatMember(
        userId: map['userId'] as String,
        role: ChatMemberRole.fromString(map['role'] as String),
        joinedAt: DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] as int),
        nickname: map['nickname'] as String?,
        permissions: map['permissions'] != null
            ? ChatPermissions.fromMap(
                map['permissions'] as Map<String, dynamic>,
              )
            : const ChatPermissions(),
        isOnline: (map['isOnline'] as bool?) ?? false,
        lastSeen: map['lastSeen'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] as int)
            : null,
      );

  final String userId;
  final ChatMemberRole role;
  final DateTime joinedAt;
  final String? nickname;
  final ChatPermissions permissions;
  final bool isOnline;
  final DateTime? lastSeen;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'role': role.value,
        'joinedAt': joinedAt.millisecondsSinceEpoch,
        'nickname': nickname,
        'permissions': permissions.toMap(),
        'isOnline': isOnline,
        'lastSeen': lastSeen?.millisecondsSinceEpoch,
      };
}

/// Роль участника чата
enum ChatMemberRole {
  owner('owner'),
  admin('admin'),
  member('member'),
  viewer('viewer');

  const ChatMemberRole(this.value);
  final String value;

  static ChatMemberRole fromString(String value) {
    switch (value) {
      case 'owner':
        return ChatMemberRole.owner;
      case 'admin':
        return ChatMemberRole.admin;
      case 'member':
        return ChatMemberRole.member;
      case 'viewer':
        return ChatMemberRole.viewer;
      default:
        return ChatMemberRole.member;
    }
  }

  String get displayName {
    switch (this) {
      case ChatMemberRole.owner:
        return 'Владелец';
      case ChatMemberRole.admin:
        return 'Администратор';
      case ChatMemberRole.member:
        return 'Участник';
      case ChatMemberRole.viewer:
        return 'Наблюдатель';
    }
  }
}

/// Разрешения участника чата
class ChatPermissions {
  const ChatPermissions({
    this.canSendMessages = true,
    this.canSendMedia = true,
    this.canSendDocuments = true,
    this.canInviteMembers = false,
    this.canEditChat = false,
    this.canDeleteMessages = false,
    this.canPinMessages = false,
  });

  factory ChatPermissions.fromMap(Map<String, dynamic> map) => ChatPermissions(
        canSendMessages: (map['canSendMessages'] as bool?) ?? true,
        canSendMedia: (map['canSendMedia'] as bool?) ?? true,
        canSendDocuments: (map['canSendDocuments'] as bool?) ?? true,
        canInviteMembers: (map['canInviteMembers'] as bool?) ?? false,
        canEditChat: (map['canEditChat'] as bool?) ?? false,
        canDeleteMessages: (map['canDeleteMessages'] as bool?) ?? false,
        canPinMessages: (map['canPinMessages'] as bool?) ?? false,
      );

  final bool canSendMessages;
  final bool canSendMedia;
  final bool canSendDocuments;
  final bool canInviteMembers;
  final bool canEditChat;
  final bool canDeleteMessages;
  final bool canPinMessages;

  Map<String, dynamic> toMap() => {
        'canSendMessages': canSendMessages,
        'canSendMedia': canSendMedia,
        'canSendDocuments': canSendDocuments,
        'canInviteMembers': canInviteMembers,
        'canEditChat': canEditChat,
        'canDeleteMessages': canDeleteMessages,
        'canPinMessages': canPinMessages,
      };
}

/// Последнее сообщение в чате
class ChatLastMessage {
  const ChatLastMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.createdAt,
    this.attachments = const [],
  });

  factory ChatLastMessage.fromMap(Map<String, dynamic> map) => ChatLastMessage(
        id: map['id'] as String,
        senderId: map['senderId'] as String,
        text: map['text'] as String,
        type: MessageType.fromString(map['type'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        attachments: (map['attachments'] as List?)
                ?.map(
                  (attachment) => MessageAttachment.fromMap(
                    attachment as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
      );

  final String id;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime createdAt;
  final List<MessageAttachment> attachments;

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'type': type.value,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'attachments':
            attachments.map((attachment) => attachment.toMap()).toList(),
      };
}

/// Настройки чата
class ChatSettings {
  const ChatSettings({
    this.notifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.showPreview = true,
    this.autoDownloadMedia = true,
    this.autoDownloadDocuments = false,
    this.language = 'ru',
    this.theme = ChatTheme.system,
  });

  factory ChatSettings.fromMap(Map<String, dynamic> map) => ChatSettings(
        notifications: (map['notifications'] as bool?) ?? true,
        soundEnabled: (map['soundEnabled'] as bool?) ?? true,
        vibrationEnabled: (map['vibrationEnabled'] as bool?) ?? true,
        showPreview: (map['showPreview'] as bool?) ?? true,
        autoDownloadMedia: (map['autoDownloadMedia'] as bool?) ?? true,
        autoDownloadDocuments: (map['autoDownloadDocuments'] as bool?) ?? false,
        language: (map['language'] as String?) ?? 'ru',
        theme: ChatTheme.fromString(map['theme'] as String? ?? 'system'),
      );

  final bool notifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool showPreview;
  final bool autoDownloadMedia;
  final bool autoDownloadDocuments;
  final String language;
  final ChatTheme theme;

  Map<String, dynamic> toMap() => {
        'notifications': notifications,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'showPreview': showPreview,
        'autoDownloadMedia': autoDownloadMedia,
        'autoDownloadDocuments': autoDownloadDocuments,
        'language': language,
        'theme': theme.value,
      };
}

/// Тема чата
enum ChatTheme {
  light('light'),
  dark('dark'),
  system('system');

  const ChatTheme(this.value);
  final String value;

  static ChatTheme fromString(String value) {
    switch (value) {
      case 'light':
        return ChatTheme.light;
      case 'dark':
        return ChatTheme.dark;
      case 'system':
        return ChatTheme.system;
      default:
        return ChatTheme.system;
    }
  }

  String get displayName {
    switch (this) {
      case ChatTheme.light:
        return 'Светлая';
      case ChatTheme.dark:
        return 'Тёмная';
      case ChatTheme.system:
        return 'Системная';
    }
  }
}
