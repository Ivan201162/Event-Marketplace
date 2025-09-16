import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../core/feature_flags.dart';

/// Провайдер сервиса чата
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Провайдер для проверки доступности чата
final chatAvailableProvider = Provider<bool>((ref) {
  return FeatureFlags.chatAttachmentsEnabled;
});

/// Провайдер чатов пользователя
final userChatsProvider = StreamProvider.family<List<Chat>, String>((ref, userId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getUserChats(userId);
});

/// Провайдер сообщений чата
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getChatMessages(chatId);
});

/// Провайдер чата по ID
final chatProvider = FutureProvider.family<Chat?, String>((ref, chatId) async {
  final chatService = ref.read(chatServiceProvider);
  return await chatService.getChat(chatId);
});

/// Провайдер поиска сообщений
final messageSearchProvider = StreamProvider.family<List<ChatMessage>, ({String chatId, String query})>((ref, params) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.searchMessages(params.chatId, params.query);
});