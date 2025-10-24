import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Провайдер сервиса чатов
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Провайдер состояния чатов
final chatsProvider = StateNotifierProvider<ChatsNotifier, AsyncValue<List<Chat>>>((ref) {
  return ChatsNotifier(ref.read(chatServiceProvider));
});

/// Провайдер сообщений чата
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, String>((ref, chatId) {
  return ChatMessagesNotifier(ref.read(chatServiceProvider), chatId);
});

/// Notifier для управления состоянием чатов
class ChatsNotifier extends StateNotifier<AsyncValue<List<Chat>>> {
  final ChatService _chatService;

  ChatsNotifier(this._chatService) : super(const AsyncValue.loading()) {
    _loadInitialChats();
  }

  Future<void> _loadInitialChats() async {
    try {
      state = const AsyncValue.loading();
      final chats = await _chatService.getChats();
      state = AsyncValue.data(chats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshChats() async {
    await _loadInitialChats();
  }

  Future<void> loadMoreChats() async {
    if (state.hasValue) {
      try {
        final currentChats = state.value!;
        final newChats = await _chatService.getMoreChats(currentChats.length);
        state = AsyncValue.data([...currentChats, ...newChats]);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> searchChats(String query) async {
    try {
      state = const AsyncValue.loading();
      final chats = await _chatService.searchChats(query);
      state = AsyncValue.data(chats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> filterChats(String filter) async {
    try {
      state = const AsyncValue.loading();
      final chats = await _chatService.filterChats(filter);
      state = AsyncValue.data(chats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createChat(String otherUserId, String otherUserName, String? otherUserAvatar) async {
    try {
      await _chatService.createChat(otherUserId, otherUserName, otherUserAvatar);
      await refreshChats();
    } catch (error) {
      // Обработка ошибки создания чата
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _chatService.deleteChat(chatId);
      await refreshChats();
    } catch (error) {
      // Обработка ошибки удаления чата
      rethrow;
    }
  }
}

/// Notifier для управления сообщениями чата
class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatService _chatService;
  final String _chatId;

  ChatMessagesNotifier(this._chatService, this._chatId) : super(const AsyncValue.loading()) {
    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    try {
      state = const AsyncValue.loading();
      final messages = await _chatService.getMessages(_chatId);
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshMessages() async {
    await _loadInitialMessages();
  }

  Future<void> loadMoreMessages() async {
    if (state.hasValue) {
      try {
        final currentMessages = state.value!;
        final newMessages = await _chatService.getMoreMessages(_chatId, currentMessages.length);
        state = AsyncValue.data([...currentMessages, ...newMessages]);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> sendMessage(String text, {List<String>? attachments}) async {
    try {
      await _chatService.sendMessage(_chatId, text, attachments: attachments);
      await refreshMessages();
    } catch (error) {
      // Обработка ошибки отправки сообщения
      rethrow;
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    try {
      await _chatService.editMessage(_chatId, messageId, newText);
      await refreshMessages();
    } catch (error) {
      // Обработка ошибки редактирования сообщения
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(_chatId, messageId);
      await refreshMessages();
    } catch (error) {
      // Обработка ошибки удаления сообщения
      rethrow;
    }
  }

  Future<void> markAsRead() async {
    try {
      await _chatService.markAsRead(_chatId);
    } catch (error) {
      // Обработка ошибки отметки как прочитанное
    }
  }
}