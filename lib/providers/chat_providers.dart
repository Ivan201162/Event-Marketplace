import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Провайдер сервиса чата
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Провайдер для списка чатов пользователя
final userChatsProvider = FutureProvider.family<List<Chat>, UserChatsParams>((ref, params) async {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getUserChats(params.userId);
});

/// Параметры для получения чатов пользователя
class UserChatsParams {
  final String userId;

  const UserChatsParams({required this.userId});
}

/// Провайдер для сообщений чата
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getChatMessages(chatId);
});

/// Провайдер для состояния формы сообщения
final messageFormProvider = NotifierProvider<MessageFormNotifier, MessageFormState>(() {
  return MessageFormNotifier();
});

/// Состояние формы сообщения
class MessageFormState {
  final String text;
  final List<String> attachments;
  final bool isSending;
  final String? error;

  const MessageFormState({
    this.text = '',
    this.attachments = const [],
    this.isSending = false,
    this.error,
  });

  MessageFormState copyWith({
    String? text,
    List<String>? attachments,
    bool? isSending,
    String? error,
  }) {
    return MessageFormState(
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
    );
  }
}

/// Нотификатор для формы сообщения
class MessageFormNotifier extends Notifier<MessageFormState> {
  @override
  MessageFormState build() {
    return const MessageFormState();
  }

  void updateText(String text) {
    state = state.copyWith(text: text);
  }

  void addAttachment(String attachment) {
    final updatedAttachments = [...state.attachments, attachment];
    state = state.copyWith(attachments: updatedAttachments);
  }

  void removeAttachment(String attachment) {
    final updatedAttachments = state.attachments.where((a) => a != attachment).toList();
    state = state.copyWith(attachments: updatedAttachments);
  }

  void setSending(bool isSending) {
    state = state.copyWith(isSending: isSending);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clear() {
    state = const MessageFormState();
  }
}

/// Провайдер для состояния чата
final chatStateProvider = NotifierProvider<ChatStateNotifier, ChatState>(() {
  return ChatStateNotifier();
});

/// Состояние чата
class ChatState {
  final List<Chat> chats;
  final Map<String, List<ChatMessage>> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.chats = const [],
    this.messages = const {},
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<Chat>? chats,
    Map<String, List<ChatMessage>>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Нотификатор для состояния чата
class ChatStateNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return const ChatState();
  }

  void setChats(List<Chat> chats) {
    state = state.copyWith(chats: chats);
  }

  void setMessages(String chatId, List<ChatMessage> messages) {
    final updatedMessages = Map<String, List<ChatMessage>>.from(state.messages);
    updatedMessages[chatId] = messages;
    state = state.copyWith(messages: updatedMessages);
  }

  void addMessage(String chatId, ChatMessage message) {
    final currentMessages = state.messages[chatId] ?? [];
    final updatedMessages = [...currentMessages, message];
    setMessages(chatId, updatedMessages);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}