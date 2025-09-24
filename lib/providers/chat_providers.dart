import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../models/chat_message.dart' as chat_message;
import '../models/chat_attachment.dart';
import '../services/chat_service.dart';

/// Провайдер сервиса чата
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

/// Провайдер для списка чатов пользователя
final userChatsProvider =
    FutureProvider.family<List<Chat>, UserChatsParams>((ref, params) async {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getUserChats(params.userId);
});

/// Параметры для получения чатов пользователя
class UserChatsParams {
  const UserChatsParams({required this.userId});
  final String userId;
}

/// Провайдер для сообщений чата
final chatMessagesProvider =
    StreamProvider.family<List<chat_message.ChatMessage>, String>(
        (ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getChatMessages(chatId);
});

/// Провайдер для чата
final chatProvider = StreamProvider.family<Chat?, String>((ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getChat(chatId);
});

/// Провайдер для состояния формы сообщения
final messageFormProvider =
    NotifierProvider<MessageFormNotifier, MessageFormState>(
  MessageFormNotifier.new,
);

/// Состояние формы сообщения
class MessageFormState {
  const MessageFormState({
    this.text = '',
    this.attachments = const [],
    this.isSending = false,
    this.error,
  });
  final String text;
  final List<String> attachments;
  final bool isSending;
  final String? error;

  MessageFormState copyWith({
    String? text,
    List<String>? attachments,
    bool? isSending,
    String? error,
  }) =>
      MessageFormState(
        text: text ?? this.text,
        attachments: attachments ?? this.attachments,
        isSending: isSending ?? this.isSending,
        error: error ?? this.error,
      );
}

/// Нотификатор для формы сообщения
class MessageFormNotifier extends Notifier<MessageFormState> {
  @override
  MessageFormState build() => const MessageFormState();

  void updateText(String text) {
    state = state.copyWith(text: text);
  }

  void addAttachment(String attachment) {
    final updatedAttachments = [...state.attachments, attachment];
    state = state.copyWith(attachments: updatedAttachments);
  }

  void removeAttachment(String attachment) {
    final updatedAttachments =
        state.attachments.where((a) => a != attachment).toList();
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
final chatStateProvider =
    NotifierProvider<ChatStateNotifier, ChatState>(ChatStateNotifier.new);

/// Состояние чата
class ChatState {
  const ChatState({
    this.chats = const [],
    this.messages = const {},
    this.isLoading = false,
    this.error,
  });
  final List<Chat> chats;
  final Map<String, List<chat_message.ChatMessage>> messages;
  final bool isLoading;
  final String? error;

  ChatState copyWith({
    List<Chat>? chats,
    Map<String, List<chat_message.ChatMessage>>? messages,
    bool? isLoading,
    String? error,
  }) =>
      ChatState(
        chats: chats ?? this.chats,
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Нотификатор для состояния чата
class ChatStateNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  void setChats(List<Chat> chats) {
    state = state.copyWith(chats: chats);
  }

  void setMessages(String chatId, List<chat_message.ChatMessage> messages) {
    final updatedMessages =
        Map<String, List<chat_message.ChatMessage>>.from(state.messages);
    updatedMessages[chatId] = messages;
    state = state.copyWith(messages: updatedMessages);
  }

  void addMessage(String chatId, chat_message.ChatMessage message) {
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

  Future<void> sendMessage(String chatId, String text, {ChatAttachment? attachment}) async {
    try {
      setLoading(true);
      final chatService = ref.read(chatServiceProvider);
      await chatService.sendMessage(chatId, chat_message.ChatMessage(
        id: '',
        chatId: chatId,
        senderId: 'current_user_id',
        type: attachment != null ? chat_message.MessageType.attachment : chat_message.MessageType.text,
        content: text,
        status: chat_message.MessageStatus.sent,
        timestamp: DateTime.now(),
        senderName: 'Current User',
        attachmentId: attachment?.id,
      ));
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    try {
      setLoading(true);
      final chatService = ref.read(chatServiceProvider);
      await chatService.editMessage(chatId, messageId, newContent);
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      setLoading(true);
      final chatService = ref.read(chatServiceProvider);
      await chatService.deleteMessageById(chatId, messageId);
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }
}
