import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../models/chat.dart';
import '../models/notification.dart';

/// Провайдер сервиса чатов
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Провайдер сервиса уведомлений
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Провайдер чатов для пользователя
final userChatsProvider = StreamProvider.family<List<Chat>, UserChatsParams>((ref, params) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChatsForUserStream(params.userId, isSpecialist: params.isSpecialist);
});

/// Провайдер сообщений чата
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChatMessagesStream(chatId);
});

/// Провайдер уведомлений пользователя
final userNotificationsProvider = StreamProvider.family<List<AppNotification>, UserNotificationsParams>((ref, params) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getUserNotificationsStream(
    params.userId,
    status: params.status,
    limit: params.limit,
  );
});

/// Провайдер статистики уведомлений
final notificationStatisticsProvider = FutureProvider.family<NotificationStatistics, String>((ref, userId) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getNotificationStatistics(userId);
});

/// Провайдер для управления состоянием чатов
final chatStateProvider = StateNotifierProvider<ChatStateNotifier, ChatState>((ref) {
  return ChatStateNotifier(ref.read(chatServiceProvider));
});

/// Провайдер для управления состоянием уведомлений
final notificationStateProvider = StateNotifierProvider<NotificationStateNotifier, NotificationState>((ref) {
  return NotificationStateNotifier(ref.read(notificationServiceProvider));
});

/// Состояние чатов
class ChatState {
  final bool isLoading;
  final String? errorMessage;
  final String? selectedChatId;
  final List<ChatMessage> currentMessages;
  final bool isTyping;

  const ChatState({
    this.isLoading = false,
    this.errorMessage,
    this.selectedChatId,
    this.currentMessages = const [],
    this.isTyping = false,
  });

  ChatState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? selectedChatId,
    List<ChatMessage>? currentMessages,
    bool? isTyping,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedChatId: selectedChatId ?? this.selectedChatId,
      currentMessages: currentMessages ?? this.currentMessages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

/// Состояние уведомлений
class NotificationState {
  final bool isLoading;
  final String? errorMessage;
  final int unreadCount;
  final List<AppNotification> recentNotifications;

  const NotificationState({
    this.isLoading = false,
    this.errorMessage,
    this.unreadCount = 0,
    this.recentNotifications = const [],
  });

  NotificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    int? unreadCount,
    List<AppNotification>? recentNotifications,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      recentNotifications: recentNotifications ?? this.recentNotifications,
    );
  }
}

/// Нотификатор состояния чатов
class ChatStateNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;

  ChatStateNotifier(this._chatService) : super(const ChatState());

  /// Создать чат
  Future<Chat?> createChat({
    required String customerId,
    required String specialistId,
    String? bookingId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final chat = await _chatService.createChat(
        customerId: customerId,
        specialistId: specialistId,
        bookingId: bookingId,
      );
      state = state.copyWith(isLoading: false);
      return chat;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Отправить сообщение
  Future<ChatMessage?> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? receiverId,
    List<String>? attachments,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final message = await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: type,
        receiverId: receiverId,
        attachments: attachments,
      );
      state = state.copyWith(isLoading: false);
      return message;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Выбрать чат
  void selectChat(String chatId) {
    state = state.copyWith(selectedChatId: chatId);
  }

  /// Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(chatId, userId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Нотификатор состояния уведомлений
class NotificationStateNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationStateNotifier(this._notificationService) : super(const NotificationState());

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllAsRead(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _notificationService.markAllAsRead(userId);
      state = state.copyWith(
        isLoading: false,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Архивировать уведомление
  Future<void> archiveNotification(String notificationId) async {
    try {
      await _notificationService.archiveNotification(notificationId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Обновить счетчик непрочитанных
  void updateUnreadCount(int count) {
    state = state.copyWith(unreadCount: count);
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Параметры для чатов пользователя
class UserChatsParams {
  final String userId;
  final bool isSpecialist;

  const UserChatsParams({
    required this.userId,
    required this.isSpecialist,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserChatsParams &&
        other.userId == userId &&
        other.isSpecialist == isSpecialist;
  }

  @override
  int get hashCode => userId.hashCode ^ isSpecialist.hashCode;
}

/// Параметры для уведомлений пользователя
class UserNotificationsParams {
  final String userId;
  final NotificationStatus? status;
  final int limit;

  const UserNotificationsParams({
    required this.userId,
    this.status,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserNotificationsParams &&
        other.userId == userId &&
        other.status == status &&
        other.limit == limit;
  }

  @override
  int get hashCode => userId.hashCode ^ status.hashCode ^ limit.hashCode;
}

/// Провайдер для управления формой сообщения
final messageFormProvider = StateNotifierProvider<MessageFormNotifier, MessageFormState>((ref) {
  return MessageFormNotifier();
});

/// Состояние формы сообщения
class MessageFormState {
  final String content;
  final bool isSending;
  final String? errorMessage;
  final MessageType selectedType;

  const MessageFormState({
    this.content = '',
    this.isSending = false,
    this.errorMessage,
    this.selectedType = MessageType.text,
  });

  MessageFormState copyWith({
    String? content,
    bool? isSending,
    String? errorMessage,
    MessageType? selectedType,
  }) {
    return MessageFormState(
      content: content ?? this.content,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

/// Нотификатор формы сообщения
class MessageFormNotifier extends StateNotifier<MessageFormState> {
  MessageFormNotifier() : super(const MessageFormState());

  /// Обновить содержимое сообщения
  void updateContent(String content) {
    state = state.copyWith(content: content);
  }

  /// Выбрать тип сообщения
  void selectType(MessageType type) {
    state = state.copyWith(selectedType: type);
  }

  /// Начать отправку
  void startSending() {
    state = state.copyWith(isSending: true, errorMessage: null);
  }

  /// Завершить отправку
  void finishSending() {
    state = state.copyWith(isSending: false, content: '');
  }

  /// Установить ошибку
  void setError(String error) {
    state = state.copyWith(
      isSending: false,
      errorMessage: error,
    );
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Сбросить форму
  void reset() {
    state = const MessageFormState();
  }
}
