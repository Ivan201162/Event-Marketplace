import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Провайдер сервиса чатов
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Провайдер списка чатов
final chatsProvider = FutureProvider<List<Chat>>((ref) async {
  final chatService = ref.read(chatServiceProvider);
  return await chatService.getChats();
});

/// Провайдер сообщений чата
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, chatId) async {
  final chatService = ref.read(chatServiceProvider);
  return await chatService.getMessages(chatId);
});

/// Провайдер для отправки сообщения
final sendMessageProvider = FutureProvider.family<void, Map<String, String>>((ref, params) async {
  final chatService = ref.read(chatServiceProvider);
  final chatId = params['chatId']!;
  final text = params['text']!;
  await chatService.sendMessage(chatId, text);
});