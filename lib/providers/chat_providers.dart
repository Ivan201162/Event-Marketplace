import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/message_service.dart';
import '../services/bot_service.dart';
import '../services/file_upload_service.dart';

// Services
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
final messageServiceProvider = Provider<MessageService>((ref) => MessageService());
final botServiceProvider = Provider<BotService>((ref) => BotService());
final fileUploadServiceProvider = Provider<FileUploadService>((ref) => FileUploadService());

// Chat providers
final userChatsProvider = StreamProvider.family<List<Chat>, String>((ref, userId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getUserChats(userId);
});

final chatProvider = FutureProvider.family<Chat?, String>((ref, chatId) async {
  final chatService = ref.watch(chatServiceProvider);
  return await chatService.getChat(chatId);
});

// Message providers
final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  final messageService = ref.watch(messageServiceProvider);
  return messageService.getChatMessages(chatId);
});

final unreadMessagesCountProvider = FutureProvider.family<int, ({String chatId, String userId})>((ref, params) async {
  final messageService = ref.watch(messageServiceProvider);
  return await messageService.getUnreadMessagesCount(params.chatId, params.userId);
});

// Chat state providers
final selectedChatProvider = StateProvider<String?>((ref) => null);
final chatSearchQueryProvider = StateProvider<String>((ref) => '');
final messageSendingStateProvider = StateProvider<Map<String, bool>>((ref) => {});
final fileUploadProgressProvider = StateProvider<Map<String, double>>((ref) => {});

// Chat statistics
final chatStatisticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final chatService = ref.watch(chatServiceProvider);
  return await chatService.getChatStatistics(userId);
});

// Unread chats count
final unreadChatsCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final chatService = ref.watch(chatServiceProvider);
  return await chatService.getUnreadChatsCount(userId);
});

// Chat creation state
final chatCreationStateProvider = StateProvider<AsyncValue<String>?>((ref) => null);

// Message editing state
final messageEditingStateProvider = StateProvider<Map<String, String>>((ref) => {});

// Chat typing indicators
final typingUsersProvider = StateProvider<Map<String, List<String>>>((ref) => {});

// Chat notifications state
final chatNotificationsProvider = StateProvider<Map<String, bool>>((ref) => {});

// Chat settings
final chatSettingsProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'soundEnabled': true,
  'vibrationEnabled': true,
  'notificationsEnabled': true,
  'autoDownloadMedia': true,
  'showOnlineStatus': true,
  'showReadReceipts': true,
});

// Message search
final messageSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedMessagesProvider = FutureProvider.family<List<Message>, ({String chatId, String query})>((ref, params) async {
  final messageService = ref.watch(messageServiceProvider);
  return await messageService.searchMessages(params.chatId, params.query);
});

// Chat media
final chatMediaProvider = FutureProvider.family<List<Message>, String>((ref, chatId) async {
  final messageService = ref.watch(messageServiceProvider);
  final messages = await messageService.getChatMessages(chatId).first;
  return messages.where((message) => message.isMedia).toList();
});

// Chat files
final chatFilesProvider = FutureProvider.family<List<Message>, String>((ref, chatId) async {
  final messageService = ref.watch(messageServiceProvider);
  final messages = await messageService.getChatMessages(chatId).first;
  return messages.where((message) => message.type == MessageType.file).toList();
});

// Chat draft messages
final draftMessagesProvider = StateProvider<Map<String, String>>((ref) => {});

// Chat security
final chatSecurityProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'blockedUsers': <String>[],
  'reportedUsers': <String>[],
  'mutedUsers': <String>[],
  'securityLevel': 'normal',
});

// Chat privacy
final chatPrivacyProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'showOnlineStatus': true,
  'showLastSeen': true,
  'showReadReceipts': true,
  'allowMessageRequests': true,
  'blockUnknownUsers': false,
});