import 'package:event_marketplace_app/models/chat.dart';
import 'package:event_marketplace_app/models/chat_message.dart';
import 'package:event_marketplace_app/services/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер сервиса чатов
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Провайдер списка чатов
final chatsProvider = FutureProvider<List<Chat>>((ref) async {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getChats();
});

/// Провайдер сообщений чата
final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, chatId) async {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getMessages(chatId);
});

/// Провайдер для отправки сообщения
final sendMessageProvider =
    FutureProvider.family<void, Map<String, String>>((ref, params) async {
  final chatService = ref.read(chatServiceProvider);
  final chatId = params['chatId']!;
  final text = params['text']!;
  await chatService.sendMessage(chatId, text);
});
