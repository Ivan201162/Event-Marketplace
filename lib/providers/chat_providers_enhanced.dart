import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_enhanced.dart';
import '../services/chat_service_enhanced.dart';

/// Провайдер для получения чатов пользователя
final userChatsProvider =
    FutureProvider.family<List<ChatEnhanced>, ChatFilters?>(
  (ref, filters) async {
    return await ChatServiceEnhanced.getUserChats(filters: filters);
  },
);

/// Провайдер для получения чата по ID
final chatByIdProvider = FutureProvider.family<ChatEnhanced?, String>(
  (ref, chatId) async {
    return await ChatServiceEnhanced.getChatById(chatId);
  },
);

/// Провайдер для получения сообщений чата
final chatMessagesProvider =
    FutureProvider.family<List<ChatMessageEnhanced>, Map<String, dynamic>>(
  (ref, params) async {
    final chatId = params['chatId'] as String;
    final filters = params['filters'] as MessageFilters?;
    final limit = params['limit'] as int? ?? 50;
    final lastDocument = params['lastDocument'] as DocumentSnapshot?;

    return await ChatServiceEnhanced.getChatMessages(
      chatId: chatId,
      filters: filters,
      limit: limit,
      lastDocument: lastDocument,
    );
  },
);

/// Провайдер для поиска сообщений
final searchMessagesProvider =
    FutureProvider.family<List<ChatMessageEnhanced>, Map<String, dynamic>>(
  (ref, params) async {
    final chatId = params['chatId'] as String;
    final query = params['query'] as String;
    final filters = params['filters'] as MessageFilters?;

    return await ChatServiceEnhanced.searchMessages(
      chatId: chatId,
      query: query,
      filters: filters,
    );
  },
);

/// Провайдер для фильтров чатов
final chatFiltersProvider =
    StateNotifierProvider<ChatFiltersNotifier, ChatFilters>(
  (ref) => ChatFiltersNotifier(),
);

/// Провайдер для фильтров сообщений
final messageFiltersProvider =
    StateNotifierProvider<MessageFiltersNotifier, MessageFilters>(
  (ref) => MessageFiltersNotifier(),
);

/// Провайдер для сортировки чатов
final chatSortProvider = StateProvider<String>((ref) => 'updatedAt');

/// Провайдер для поиска чатов
final chatSearchProvider = StateProvider<String>((ref) => '');

/// Провайдер для типов чатов
final chatTypesProvider = Provider<List<ChatType>>(
  (ref) => ChatType.values,
);

/// Провайдер для типов сообщений
final messageTypesProvider = Provider<List<MessageType>>(
  (ref) => MessageType.values,
);

/// Провайдер для статусов сообщений
final messageStatusesProvider = Provider<List<MessageStatus>>(
  (ref) => MessageStatus.values,
);

/// Провайдер для уведомлений чатов
final chatNotificationsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    yield* FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('data.type', whereIn: [
          'chat_created',
          'group_invite',
          'request_chat',
          'message'
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  },
);

/// Провайдер для непрочитанных сообщений
final unreadMessagesCountProvider = StreamProvider<int>(
  (ref) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    yield* FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(0, (sum, doc) {
              final data = doc.data();
              return sum + (data['unreadCount'] ?? 0);
            }));
  },
);

/// Провайдер для аналитики чатов
final chatAnalyticsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final chats = await ChatServiceEnhanced.getUserChats();

    return {
      'totalChats': chats.length,
      'personalChats': chats.where((c) => c.type == ChatType.personal).length,
      'groupChats': chats.where((c) => c.type == ChatType.group).length,
      'requestChats': chats.where((c) => c.type == ChatType.request).length,
      'mutedChats': chats.where((c) => c.isMuted).length,
      'pinnedChats': chats.where((c) => c.isPinned).length,
      'archivedChats': chats.where((c) => c.isArchived).length,
      'totalUnread': chats.fold(0, (sum, c) => sum + c.unreadCount),
    };
  },
);

/// Провайдер для статистики сообщений
final messageStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, chatId) async {
    final messages =
        await ChatServiceEnhanced.getChatMessages(chatId: chatId, limit: 1000);

    return {
      'totalMessages': messages.length,
      'textMessages': messages.where((m) => m.type == MessageType.text).length,
      'imageMessages':
          messages.where((m) => m.type == MessageType.image).length,
      'videoMessages':
          messages.where((m) => m.type == MessageType.video).length,
      'audioMessages':
          messages.where((m) => m.type == MessageType.audio).length,
      'fileMessages': messages.where((m) => m.type == MessageType.file).length,
      'locationMessages':
          messages.where((m) => m.type == MessageType.location).length,
      'stickerMessages':
          messages.where((m) => m.type == MessageType.sticker).length,
      'gifMessages': messages.where((m) => m.type == MessageType.gif).length,
      'editedMessages': messages.where((m) => m.isEdited).length,
      'deletedMessages': messages.where((m) => m.isDeleted).length,
      'messagesWithReactions':
          messages.where((m) => m.reactions.isNotEmpty).length,
      'averageReactionsPerMessage': messages.isNotEmpty
          ? messages.fold(0, (sum, m) => sum + m.reactions.length) /
              messages.length
          : 0.0,
    };
  },
);

/// Провайдер для управления фильтрами чатов
class ChatFiltersNotifier extends StateNotifier<ChatFilters> {
  ChatFiltersNotifier() : super(const ChatFilters());

  void updateType(ChatType? type) {
    state = ChatFilters(
      type: type,
      isMuted: state.isMuted,
      isPinned: state.isPinned,
      isArchived: state.isArchived,
      searchQuery: state.searchQuery,
      tags: state.tags,
      requestId: state.requestId,
      groupId: state.groupId,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void updateMuted(bool? isMuted) {
    state = ChatFilters(
      type: state.type,
      isMuted: isMuted,
      isPinned: state.isPinned,
      isArchived: state.isArchived,
      searchQuery: state.searchQuery,
      tags: state.tags,
      requestId: state.requestId,
      groupId: state.groupId,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void updatePinned(bool? isPinned) {
    state = ChatFilters(
      type: state.type,
      isMuted: state.isMuted,
      isPinned: isPinned,
      isArchived: state.isArchived,
      searchQuery: state.searchQuery,
      tags: state.tags,
      requestId: state.requestId,
      groupId: state.groupId,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void updateArchived(bool? isArchived) {
    state = ChatFilters(
      type: state.type,
      isMuted: state.isMuted,
      isPinned: state.isPinned,
      isArchived: isArchived,
      searchQuery: state.searchQuery,
      tags: state.tags,
      requestId: state.requestId,
      groupId: state.groupId,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void updateSearchQuery(String? searchQuery) {
    state = ChatFilters(
      type: state.type,
      isMuted: state.isMuted,
      isPinned: state.isPinned,
      isArchived: state.isArchived,
      searchQuery: searchQuery,
      tags: state.tags,
      requestId: state.requestId,
      groupId: state.groupId,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void updateTags(List<String>? tags) {
    state = ChatFilters(
      type: state.type,
      isMuted: state.isMuted,
      isPinned: state.isPinned,
      isArchived: state.isArchived,
      searchQuery: state.searchQuery,
      tags: tags,
      requestId: state.requestId,
      groupId: state.groupId,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void updateRequestId(String? requestId) {
    state = ChatFilters(
      type: state.type,
      isMuted: state.isMuted,
      isPinned: state.isPinned,
      isArchived: state.isArchived,
      searchQuery: state.searchQuery,
      tags: state.tags,
      requestId: requestId,
      groupId: state.groupId,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void updateGroupId(String? groupId) {
    state = ChatFilters(
      type: state.type,
      isMuted: state.isMuted,
      isPinned: state.isPinned,
      isArchived: state.isArchived,
      searchQuery: state.searchQuery,
      tags: state.tags,
      requestId: state.requestId,
      groupId: groupId,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = ChatFilters(
      type: state.type,
      isMuted: state.isMuted,
      isPinned: state.isPinned,
      isArchived: state.isArchived,
      searchQuery: state.searchQuery,
      tags: state.tags,
      requestId: state.requestId,
      groupId: state.groupId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  void clearFilters() {
    state = const ChatFilters();
  }
}

/// Провайдер для управления фильтрами сообщений
class MessageFiltersNotifier extends StateNotifier<MessageFilters> {
  MessageFiltersNotifier() : super(const MessageFilters());

  void updateType(MessageType? type) {
    state = MessageFilters(
      type: type,
      authorId: state.authorId,
      startDate: state.startDate,
      endDate: state.endDate,
      searchQuery: state.searchQuery,
      hasAttachments: state.hasAttachments,
      hasReactions: state.hasReactions,
      isEdited: state.isEdited,
      isDeleted: state.isDeleted,
    );
  }

  void updateAuthorId(String? authorId) {
    state = MessageFilters(
      type: state.type,
      authorId: authorId,
      startDate: state.startDate,
      endDate: state.endDate,
      searchQuery: state.searchQuery,
      hasAttachments: state.hasAttachments,
      hasReactions: state.hasReactions,
      isEdited: state.isEdited,
      isDeleted: state.isDeleted,
    );
  }

  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = MessageFilters(
      type: state.type,
      authorId: state.authorId,
      startDate: startDate,
      endDate: endDate,
      searchQuery: state.searchQuery,
      hasAttachments: state.hasAttachments,
      hasReactions: state.hasReactions,
      isEdited: state.isEdited,
      isDeleted: state.isDeleted,
    );
  }

  void updateSearchQuery(String? searchQuery) {
    state = MessageFilters(
      type: state.type,
      authorId: state.authorId,
      startDate: state.startDate,
      endDate: state.endDate,
      searchQuery: searchQuery,
      hasAttachments: state.hasAttachments,
      hasReactions: state.hasReactions,
      isEdited: state.isEdited,
      isDeleted: state.isDeleted,
    );
  }

  void updateHasAttachments(bool? hasAttachments) {
    state = MessageFilters(
      type: state.type,
      authorId: state.authorId,
      startDate: state.startDate,
      endDate: state.endDate,
      searchQuery: state.searchQuery,
      hasAttachments: hasAttachments,
      hasReactions: state.hasReactions,
      isEdited: state.isEdited,
      isDeleted: state.isDeleted,
    );
  }

  void updateHasReactions(bool? hasReactions) {
    state = MessageFilters(
      type: state.type,
      authorId: state.authorId,
      startDate: state.startDate,
      endDate: state.endDate,
      searchQuery: state.searchQuery,
      hasAttachments: state.hasAttachments,
      hasReactions: hasReactions,
      isEdited: state.isEdited,
      isDeleted: state.isDeleted,
    );
  }

  void updateIsEdited(bool? isEdited) {
    state = MessageFilters(
      type: state.type,
      authorId: state.authorId,
      startDate: state.startDate,
      endDate: state.endDate,
      searchQuery: state.searchQuery,
      hasAttachments: state.hasAttachments,
      hasReactions: state.hasReactions,
      isEdited: isEdited,
      isDeleted: state.isDeleted,
    );
  }

  void updateIsDeleted(bool? isDeleted) {
    state = MessageFilters(
      type: state.type,
      authorId: state.authorId,
      startDate: state.startDate,
      endDate: state.endDate,
      searchQuery: state.searchQuery,
      hasAttachments: state.hasAttachments,
      hasReactions: state.hasReactions,
      isEdited: state.isEdited,
      isDeleted: isDeleted,
    );
  }

  void clearFilters() {
    state = const MessageFilters();
  }
}
