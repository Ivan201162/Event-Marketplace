import 'package:cloud_firestore/cloud_firestore.dart';

/// Расширенная модель сообщения чата
class ChatMessageExtended {
  const ChatMessageExtended({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.type = MessageType.text,
    this.audioUrl,
    this.audioDuration,
    this.audioWaveform,
    this.reactions = const [],
    this.isEdited = false,
    this.editedAt,
    this.replyToMessageId,
    this.attachments = const [],
    this.metadata = const {},
  });

  factory ChatMessageExtended.fromChatMessage(ChatMessageExtended message) =>
      ChatMessageExtended(
        id: message.id,
        chatId: message.chatId,
        senderId: message.senderId,
        senderName: message.senderName,
        senderAvatar: message.senderAvatar,
        content: message.content,
        timestamp: message.timestamp,
        isRead: message.isRead,
        readBy: message.readBy,
      );

  factory ChatMessageExtended.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return ChatMessageExtended(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderAvatar: data['senderAvatar'] as String?,
      content: data['content'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      readBy: List<String>.from(data['readBy'] as List<dynamic>? ?? []),
      type: MessageType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => MessageType.text,
      ),
      audioUrl: data['audioUrl'] as String?,
      audioDuration: data['audioDuration'] as int?,
      audioWaveform: data['audioWaveform'] as String?,
      reactions: (data['reactions'] as List<dynamic>?)
              ?.map((e) => MessageReaction.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isEdited: data['isEdited'] as bool? ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      replyToMessageId: data['replyToMessageId'] as String?,
      attachments:
          List<String>.from(data['attachments'] as List<dynamic>? ?? []),
      metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<dynamic, dynamic>? ?? {}),
    );
  }
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final MessageType type;
  final String? audioUrl;
  final int? audioDuration; // в секундах
  final String? audioWaveform; // JSON строка с данными волны
  final List<MessageReaction> reactions;
  final bool isEdited;
  final DateTime? editedAt;
  final String? replyToMessageId;
  final List<String> attachments; // URL вложений
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRead': isRead,
        'readBy': readBy,
        'type': type.name,
        'audioUrl': audioUrl,
        'audioDuration': audioDuration,
        'audioWaveform': audioWaveform,
        'reactions': reactions.map((e) => e.toMap()).toList(),
        'isEdited': isEdited,
        'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
        'replyToMessageId': replyToMessageId,
        'attachments': attachments,
        'metadata': metadata,
      };

  ChatMessageExtended copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
    MessageType? type,
    String? audioUrl,
    int? audioDuration,
    String? audioWaveform,
    List<MessageReaction>? reactions,
    bool? isEdited,
    DateTime? editedAt,
    String? replyToMessageId,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) =>
      ChatMessageExtended(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderAvatar: senderAvatar ?? this.senderAvatar,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        isRead: isRead ?? this.isRead,
        readBy: readBy ?? this.readBy,
        type: type ?? this.type,
        audioUrl: audioUrl ?? this.audioUrl,
        audioDuration: audioDuration ?? this.audioDuration,
        audioWaveform: audioWaveform ?? this.audioWaveform,
        reactions: reactions ?? this.reactions,
        isEdited: isEdited ?? this.isEdited,
        editedAt: editedAt ?? this.editedAt,
        replyToMessageId: replyToMessageId ?? this.replyToMessageId,
        attachments: attachments ?? this.attachments,
        metadata: metadata ?? this.metadata,
      );

  /// Получить количество реакций по типу
  int getReactionCount(String emoji) =>
      reactions.where((reaction) => reaction.emoji == emoji).length;

  /// Проверить, есть ли реакция от пользователя
  bool hasReactionFromUser(String userId, String emoji) => reactions
      .any((reaction) => reaction.userId == userId && reaction.emoji == emoji);

  /// Получить все уникальные эмодзи реакций
  List<String> get uniqueReactionEmojis =>
      reactions.map((reaction) => reaction.emoji).toSet().toList();

  /// Проверить, является ли сообщение голосовым
  bool get isVoiceMessage => type == MessageType.voice;

  /// Проверить, является ли сообщение текстовым
  bool get isTextMessage => type == MessageType.text;

  /// Проверить, является ли сообщение с вложениями
  bool get hasAttachments => attachments.isNotEmpty;

  /// Проверить, является ли сообщение ответом
  bool get isReply => replyToMessageId != null;
}

/// Тип сообщения
enum MessageType { text, voice, image, file, system }

/// Реакция на сообщение
class MessageReaction {
  const MessageReaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.emoji,
    required this.timestamp,
  });

  factory MessageReaction.fromMap(Map<String, dynamic> map) => MessageReaction(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? '',
        emoji: map['emoji'] as String? ?? '',
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  final String id;
  final String userId;
  final String userName;
  final String emoji;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'emoji': emoji,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  MessageReaction copyWith({
    String? id,
    String? userId,
    String? userName,
    String? emoji,
    DateTime? timestamp,
  }) =>
      MessageReaction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        emoji: emoji ?? this.emoji,
        timestamp: timestamp ?? this.timestamp,
      );
}

/// Данные волны для аудио
class AudioWaveform {
  const AudioWaveform(
      {required this.samples,
      required this.duration,
      required this.sampleRate});

  factory AudioWaveform.fromJson() {
    // TODO(developer): Реализовать парсинг JSON
    return const AudioWaveform(samples: [], duration: 0, sampleRate: 44100);
  }
  final List<double> samples;
  final int duration; // в миллисекундах
  final int sampleRate;

  String toJson() {
    // TODO(developer): Реализовать сериализацию в JSON
    return '{}';
  }

  /// Получить нормализованные сэмплы для отображения
  List<double> get normalizedSamples {
    if (samples.isEmpty) return [];

    final maxSample = samples.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    if (maxSample == 0) return samples;

    return samples.map((sample) => sample / maxSample).toList();
  }
}

/// Статистика сообщений
class MessageStats {
  const MessageStats({
    required this.totalMessages,
    required this.textMessages,
    required this.voiceMessages,
    required this.imageMessages,
    required this.fileMessages,
    required this.totalReactions,
    required this.reactionCounts,
    required this.lastActivity,
  });

  factory MessageStats.empty() => MessageStats(
        totalMessages: 0,
        textMessages: 0,
        voiceMessages: 0,
        imageMessages: 0,
        fileMessages: 0,
        totalReactions: 0,
        reactionCounts: {},
        lastActivity: DateTime.now(),
      );
  final int totalMessages;
  final int textMessages;
  final int voiceMessages;
  final int imageMessages;
  final int fileMessages;
  final int totalReactions;
  final Map<String, int> reactionCounts;
  final DateTime lastActivity;
}
