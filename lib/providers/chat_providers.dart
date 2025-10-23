import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Сервис чатов провайдер
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Провайдер для списка чатов пользователя
final userChatsProvider = StreamProvider<List<Chat>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  final chatService = ref.read(chatServiceProvider);
  return chatService.getUserChats(user.uid);
});

/// Провайдер для сообщений конкретного чата
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getChatMessages(chatId);
});

/// Провайдер для информации о конкретном чате
final chatProvider = FutureProvider.family<Chat?, String>((ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getChat(chatId);
});

/// Провайдер для общего количества непрочитанных сообщений
final totalUnreadCountProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  final chatService = ref.read(chatServiceProvider);

  // Создаем периодический стрим для обновления счетчика
  return Stream.periodic(const Duration(seconds: 30), (_) {
    return chatService.getTotalUnreadCount(user.uid);
  }).asyncMap((_) => chatService.getTotalUnreadCount(user.uid));
});

/// Провайдер для состояния отправки сообщения
final messageSendingProvider =
    NotifierProvider<MessageSendingNotifier, bool>(() {
  return MessageSendingNotifier();
});

/// Notifier для состояния отправки сообщения
class MessageSendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSending(bool isSending) {
    state = isSending;
  }
}

/// Провайдер для выбранного чата
final selectedChatProvider =
    NotifierProvider<SelectedChatNotifier, String?>(() {
  return SelectedChatNotifier();
});

/// Notifier для выбранного чата
class SelectedChatNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectChat(String? chatId) {
    state = chatId;
  }
}

/// Провайдер для поиска в чатах
final chatSearchProvider = NotifierProvider<ChatSearchNotifier, String>(() {
  return ChatSearchNotifier();
});

/// Notifier для поиска в чатах
class ChatSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearchQuery(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

/// Провайдер для отфильтрованных чатов
final filteredChatsProvider = Provider<List<Chat>>((ref) {
  final chats = ref.watch(userChatsProvider).value ?? [];
  final searchQuery = ref.watch(chatSearchProvider);

  if (searchQuery.isEmpty) return chats;

  return chats.where((chat) {
    return chat.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (chat.lastMessageContent
                ?.toLowerCase()
                .contains(searchQuery.toLowerCase()) ??
            false);
  }).toList();
});

/// Провайдер для чата с пользователем (для отображения информации о собеседнике)
final chatWithUserProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, chatId) async {
  final chat = await ref.watch(chatProvider(chatId).future);
  if (chat == null) return null;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  // Для прямых чатов получаем информацию о другом участнике
  if (chat.isDirectChat) {
    final otherUserId = chat.getOtherParticipantId(user.uid);
    if (otherUserId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          return {
            'id': otherUserId,
            'name': userData['name'] ?? 'Пользователь',
            'avatarUrl': userData['avatarUrl'],
            'isOnline': userData['isOnline'] ?? false,
          };
        }
      } catch (e) {
        // Игнорируем ошибки получения данных пользователя
      }
    }
  }

  return {
    'id': chat.id,
    'name': chat.name,
    'avatarUrl': null,
    'isOnline': false,
  };
});

/// Провайдер для состояния загрузки чатов
final chatsLoadingProvider = NotifierProvider<ChatsLoadingNotifier, bool>(() {
  return ChatsLoadingNotifier();
});

/// Notifier для состояния загрузки чатов
class ChatsLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool isLoading) {
    state = isLoading;
  }
}
