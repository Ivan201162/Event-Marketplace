import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../services/chat_service.dart';

/// Chat service provider
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// User's chats provider
final userChatsProvider =
    FutureProvider.family<List<Chat>, String>((ref, userId) async {
  final service = ref.read(chatServiceProvider);
  return await service.getUserChats(userId);
});

/// Chat by ID provider
final chatByIdProvider =
    FutureProvider.family<Chat?, String>((ref, chatId) async {
  final service = ref.read(chatServiceProvider);
  return await service.getChatById(chatId);
});

/// Chat messages provider
final chatMessagesProvider =
    FutureProvider.family<List<Message>, String>((ref, chatId) async {
  final service = ref.read(chatServiceProvider);
  return await service.getChatMessages(chatId);
});

/// Stream of user's chats provider
final userChatsStreamProvider =
    StreamProvider.family<List<Chat>, String>((ref, userId) {
  final service = ref.read(chatServiceProvider);
  return service.getUserChatsStream(userId);
});

/// Stream of chat messages provider
final chatMessagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final service = ref.read(chatServiceProvider);
  return service.getChatMessagesStream(chatId);
});

/// Unread messages count provider
final unreadMessagesCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.read(chatServiceProvider);
  return await service.getUnreadMessagesCount(userId);
});

/// Stream of unread messages count provider
final unreadMessagesCountStreamProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final service = ref.read(chatServiceProvider);
  return service.getUnreadMessagesCountStream(userId);
});
