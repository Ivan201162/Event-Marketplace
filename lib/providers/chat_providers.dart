import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

/// Провайдер сервиса чатов
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

/// Провайдер для получения чатов пользователя
final userChatsProvider = StreamProvider.family<List<Chat>, String>((ref, userId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getUserChatsStream(userId);
});

/// Провайдер для получения чатов с информацией о пользователях
final userChatsWithUsersProvider = FutureProvider.family<List<ChatWithUser>, String>((ref, userId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getUserChatsWithUsers(userId);
});

/// Провайдер для получения сообщений чата
final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getMessagesStream(chatId);
});

/// Провайдер для получения информации о чате
final chatProvider = FutureProvider.family<Chat?, String>((ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getChat(chatId);
});

/// Провайдер для получения общего количества непрочитанных сообщений
final totalUnreadCountProvider = FutureProvider.family<int, String>((ref, userId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getTotalUnreadCount(userId);
});

/// Провайдер для поиска чатов
final searchChatsProvider = FutureProvider.family<List<ChatWithUser>, ({String userId, String query})>((ref, params) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.searchChats(params.userId, params.query);
});

/// Провайдер для управления состоянием чата
final chatStateProvider = StateNotifierProvider.family<ChatStateNotifier, ChatState, String>((ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return ChatStateNotifier(chatService, chatId);
});

/// Состояние чата
class ChatState {
  final bool isLoading;
  final bool isSending;
  final String? error;
  final List<Message> messages;
  final Chat? chat;

  const ChatState({
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.messages = const [],
    this.chat,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isSending,
    String? error,
    List<Message>? messages,
    Chat? chat,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
      messages: messages ?? this.messages,
      chat: chat ?? this.chat,
    );
  }
}

/// Нотификатор состояния чата
class ChatStateNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final String _chatId;

  ChatStateNotifier(this._chatService, this._chatId) : super(const ChatState()) {
    _loadChat();
  }

  /// Загрузка чата
  Future<void> _loadChat() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final chat = await _chatService.getChat(_chatId);
      state = state.copyWith(
        isLoading: false,
        chat: chat,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Отправка сообщения
  Future<void> sendMessage({
    required String text,
    required String senderId,
    String? senderName,
    String? senderAvatar,
  }) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(isSending: true, error: null);

    try {
      await _chatService.sendMessage(
        chatId: _chatId,
        text: text.trim(),
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
      );

      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  /// Отметка сообщений как прочитанных
  Future<void> markAsRead(String userId) async {
    try {
      await _chatService.markMessagesAsRead(_chatId, userId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Провайдер для управления состоянием списка чатов
final chatListStateProvider = StateNotifierProvider.family<ChatListStateNotifier, ChatListState, String>((ref, userId) {
  final chatService = ref.read(chatServiceProvider);
  return ChatListStateNotifier(chatService, userId);
});

/// Состояние списка чатов
class ChatListState {
  final bool isLoading;
  final String? error;
  final List<ChatWithUser> chats;
  final String searchQuery;

  const ChatListState({
    this.isLoading = false,
    this.error,
    this.chats = const [],
    this.searchQuery = '',
  });

  ChatListState copyWith({
    bool? isLoading,
    String? error,
    List<ChatWithUser>? chats,
    String? searchQuery,
  }) {
    return ChatListState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      chats: chats ?? this.chats,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Нотификатор состояния списка чатов
class ChatListStateNotifier extends StateNotifier<ChatListState> {
  final ChatService _chatService;
  final String _userId;

  ChatListStateNotifier(this._chatService, this._userId) : super(const ChatListState()) {
    _loadChats();
  }

  /// Загрузка чатов
  Future<void> _loadChats() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final chats = await _chatService.getUserChatsWithUsers(_userId);
      state = state.copyWith(
        isLoading: false,
        chats: chats,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Поиск чатов
  Future<void> searchChats(String query) async {
    state = state.copyWith(searchQuery: query);
    
    if (query.trim().isEmpty) {
      await _loadChats();
      return;
    }

    try {
      final chats = await _chatService.searchChats(_userId, query);
      state = state.copyWith(chats: chats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Очистка поиска
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    _loadChats();
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Обновление чатов
  Future<void> refresh() async {
    await _loadChats();
  }
}