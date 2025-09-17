import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_extended.dart';
import '../services/voice_message_service.dart';
import '../services/message_reaction_service.dart';

/// Провайдер для сервиса голосовых сообщений
final voiceMessageServiceProvider = Provider<VoiceMessageService>((ref) {
  return VoiceMessageService();
});

/// Провайдер для сервиса реакций
final messageReactionServiceProvider = Provider<MessageReactionService>((ref) {
  return MessageReactionService();
});

/// Провайдер для сообщений чата
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessageExtended>, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chat_messages')
      .where('chatId', isEqualTo: chatId)
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => ChatMessageExtended.fromDocument(doc))
        .toList();
  });
});

/// Провайдер для последнего сообщения чата
final lastChatMessageProvider =
    StreamProvider.family<ChatMessageExtended?, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chat_messages')
      .where('chatId', isEqualTo: chatId)
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;
    return ChatMessageExtended.fromDocument(snapshot.docs.first);
  });
});

/// Провайдер для непрочитанных сообщений
final unreadMessagesCountProvider =
    StreamProvider.family<int, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chat_messages')
      .where('chatId', isEqualTo: chatId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Провайдер для голосовых сообщений чата
final voiceMessagesProvider =
    StreamProvider.family<List<ChatMessageExtended>, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chat_messages')
      .where('chatId', isEqualTo: chatId)
      .where('type', isEqualTo: 'voice')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => ChatMessageExtended.fromDocument(doc))
        .toList();
  });
});

/// Провайдер для сообщений с реакциями
final messagesWithReactionsProvider =
    StreamProvider.family<List<ChatMessageExtended>, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chat_messages')
      .where('chatId', isEqualTo: chatId)
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => ChatMessageExtended.fromDocument(doc))
        .where((message) => message.reactions.isNotEmpty)
        .toList();
  });
});

/// Провайдер для статистики реакций чата
final chatReactionStatsProvider =
    StreamProvider.family<Map<String, int>, String>((ref, chatId) {
  return ref.watch(chatMessagesProvider(chatId)).when(
        data: (messages) async* {
          final reactionService = ref.read(messageReactionServiceProvider);
          yield await reactionService.getChatReactionStats(chatId);
        },
        loading: () => Stream.value({}),
        error: (_, __) => Stream.value({}),
      );
});

/// Провайдер для поиска сообщений
final messageSearchProvider =
    StreamProvider.family<List<ChatMessageExtended>, (String, String)>(
        (ref, params) {
  final (chatId, query) = params;

  if (query.isEmpty) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('chat_messages')
      .where('chatId', isEqualTo: chatId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => ChatMessageExtended.fromDocument(doc))
        .where((message) =>
            message.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
  });
});

/// Провайдер для медиафайлов чата
final chatMediaProvider =
    StreamProvider.family<List<ChatMessageExtended>, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chat_messages')
      .where('chatId', isEqualTo: chatId)
      .where('type', whereIn: ['image', 'file'])
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessageExtended.fromDocument(doc))
            .toList();
      });
});

/// Нотификатор для статуса записи
class RecordingStatusNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setRecording(bool isRecording) {
    state = isRecording;
  }
}

/// Провайдер для статуса записи
final recordingStatusProvider =
    NotifierProvider<RecordingStatusNotifier, bool>(() {
  return RecordingStatusNotifier();
});

/// Нотификатор для статуса воспроизведения
class PlayingStatusNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPlaying(String? messageId) {
    state = messageId;
  }
}

/// Провайдер для статуса воспроизведения
final playingStatusProvider =
    NotifierProvider<PlayingStatusNotifier, String?>(() {
  return PlayingStatusNotifier();
});

/// Нотификатор для текущего воспроизводимого сообщения
class CurrentPlayingMessageNotifier extends Notifier<ChatMessageExtended?> {
  @override
  ChatMessageExtended? build() => null;

  void setCurrentPlaying(ChatMessageExtended? message) {
    state = message;
  }
}

/// Провайдер для текущего воспроизводимого сообщения
final currentPlayingMessageProvider =
    NotifierProvider<CurrentPlayingMessageNotifier, ChatMessageExtended?>(() {
  return CurrentPlayingMessageNotifier();
});

/// Нотификатор для статуса "печатает"
class TypingStatusNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setTyping(bool isTyping) {
    state = isTyping;
  }
}

/// Провайдер для статуса "печатает"
final typingStatusProvider = Provider<Map<String, bool>>((ref) {
  return {};
});

/// Провайдер для активных пользователей в чате
final activeUsersProvider =
    StreamProvider.family<List<String>, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chat_sessions')
      .where('chatId', isEqualTo: chatId)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
  });
});

/// Провайдер для настроек чата
final chatSettingsProvider =
    NotifierProvider<ChatSettingsNotifier, ChatSettings>(() {
  return ChatSettingsNotifier();
});

/// Настройки чата
class ChatSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool showReadReceipts;
  final bool showTypingIndicator;
  final String theme;

  const ChatSettings({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.showReadReceipts = true,
    this.showTypingIndicator = true,
    this.theme = 'default',
  });

  ChatSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    String? theme,
  }) {
    return ChatSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
      theme: theme ?? this.theme,
    );
  }
}

/// Notifier для настроек чата
class ChatSettingsNotifier extends Notifier<ChatSettings> {
  @override
  ChatSettings build() => const ChatSettings();

  void updateSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
  }

  void updateVibrationEnabled(bool enabled) {
    state = state.copyWith(vibrationEnabled: enabled);
  }

  void updateShowReadReceipts(bool enabled) {
    state = state.copyWith(showReadReceipts: enabled);
  }

  void updateShowTypingIndicator(bool enabled) {
    state = state.copyWith(showTypingIndicator: enabled);
  }

  void updateTheme(String theme) {
    state = state.copyWith(theme: theme);
  }
}

/// Провайдер для статистики чата
final chatStatsProvider =
    StreamProvider.family<ChatStats, String>((ref, chatId) {
  return ref.watch(chatMessagesProvider(chatId)).when(
        data: (messages) async* {
          final stats = ChatStats(
            totalMessages: messages.length,
            textMessages:
                messages.where((m) => m.type == MessageType.text).length,
            voiceMessages:
                messages.where((m) => m.type == MessageType.voice).length,
            imageMessages:
                messages.where((m) => m.type == MessageType.image).length,
            fileMessages:
                messages.where((m) => m.type == MessageType.file).length,
            totalReactions:
                messages.fold(0, (sum, m) => sum + m.reactions.length),
            lastActivity:
                messages.isNotEmpty ? messages.last.timestamp : DateTime.now(),
          );
          yield stats;
        },
        loading: () => Stream.value(ChatStats.empty()),
        error: (_, __) => Stream.value(ChatStats.empty()),
      );
});

/// Статистика чата
class ChatStats {
  final int totalMessages;
  final int textMessages;
  final int voiceMessages;
  final int imageMessages;
  final int fileMessages;
  final int totalReactions;
  final DateTime lastActivity;

  const ChatStats({
    required this.totalMessages,
    required this.textMessages,
    required this.voiceMessages,
    required this.imageMessages,
    required this.fileMessages,
    required this.totalReactions,
    required this.lastActivity,
  });

  factory ChatStats.empty() {
    return ChatStats(
      totalMessages: 0,
      textMessages: 0,
      voiceMessages: 0,
      imageMessages: 0,
      fileMessages: 0,
      totalReactions: 0,
      lastActivity: DateTime.now(),
    );
  }
}
