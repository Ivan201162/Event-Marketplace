import 'package:event_marketplace_app/models/enhanced_chat.dart';
import 'package:event_marketplace_app/models/enhanced_message.dart';
import 'package:event_marketplace_app/services/enhanced_chats_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер сервиса чатов
final enhancedChatsServiceProvider = Provider<EnhancedChatsService>(
  (ref) => EnhancedChatsService(),
);

/// Провайдер чатов пользователя
final userChatsProvider =
    FutureProvider.family<List<EnhancedChat>, String>((ref, userId) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.getUserChats(userId);
});

/// Провайдер сообщений чата
final chatMessagesProvider =
    FutureProvider.family<List<EnhancedMessage>, ChatMessagesParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.getChatMessages(params.chatId,
      limit: params.limit, startAfter: params.startAfter,);
});

/// Провайдер для отправки сообщения
final sendMessageProvider =
    FutureProvider.family<String, SendMessageParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.sendMessage(params.message);
});

/// Провайдер для отправки текстового сообщения
final sendTextMessageProvider =
    FutureProvider.family<String, SendTextMessageParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.sendTextMessage(
    params.chatId,
    params.senderId,
    params.text,
    replyTo: params.replyTo,
  );
});

/// Провайдер для отправки медиа сообщения
final sendMediaMessageProvider =
    FutureProvider.family<String, SendMediaMessageParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.sendMediaMessage(
    params.chatId,
    params.senderId,
    params.attachments,
    caption: params.caption,
    replyTo: params.replyTo,
  );
});

/// Провайдер для отправки голосового сообщения
final sendVoiceMessageProvider =
    FutureProvider.family<String, SendVoiceMessageParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.sendVoiceMessage(
    params.chatId,
    params.senderId,
    params.voiceAttachment,
    replyTo: params.replyTo,
  );
});

/// Провайдер для пересылки сообщения
final forwardMessageProvider =
    FutureProvider.family<String, ForwardMessageParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.forwardMessage(
    params.originalMessageId,
    params.originalChatId,
    params.newChatId,
    params.senderId,
  );
});

/// Провайдер для редактирования сообщения
final editMessageProvider =
    FutureProvider.family<void, EditMessageParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.editMessage(params.chatId, params.messageId, params.newText);
});

/// Провайдер для удаления сообщения
final deleteMessageProvider =
    FutureProvider.family<void, DeleteMessageParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.deleteMessage(params.chatId, params.messageId);
});

/// Провайдер для добавления реакции
final addReactionProvider =
    FutureProvider.family<void, AddReactionParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.addReaction(
      params.chatId, params.messageId, params.userId, params.emoji,);
});

/// Провайдер для удаления реакции
final removeReactionProvider =
    FutureProvider.family<void, RemoveReactionParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.removeReaction(
      params.chatId, params.messageId, params.userId, params.emoji,);
});

/// Провайдер для отметки сообщений как прочитанных
final markMessagesAsReadProvider =
    FutureProvider.family<void, MarkMessagesAsReadParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.markMessagesAsRead(
      params.chatId, params.userId, params.messageIds,);
});

/// Провайдер для создания чата
final createChatProvider =
    FutureProvider.family<String, EnhancedChat>((ref, chat) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.createChat(chat);
});

/// Провайдер для создания личного чата
final createDirectChatProvider =
    FutureProvider.family<String, CreateDirectChatParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.createDirectChat(params.userId1, params.userId2);
});

/// Провайдер для создания группового чата
final createGroupChatProvider =
    FutureProvider.family<String, CreateGroupChatParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.createGroupChat(
    params.creatorId,
    params.name,
    params.memberIds,
    description: params.description,
    avatarUrl: params.avatarUrl,
  );
});

/// Провайдер для закрепления чата
final pinChatProvider =
    FutureProvider.family<void, PinChatParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.pinChat(params.chatId, params.userId);
});

/// Провайдер для открепления чата
final unpinChatProvider =
    FutureProvider.family<void, UnpinChatParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.unpinChat(params.chatId, params.userId);
});

/// Провайдер для заглушения чата
final muteChatProvider =
    FutureProvider.family<void, MuteChatParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.muteChat(params.chatId, params.userId);
});

/// Провайдер для разглушения чата
final unmuteChatProvider =
    FutureProvider.family<void, UnmuteChatParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.unmuteChat(params.chatId, params.userId);
});

/// Провайдер для архивирования чата
final archiveChatProvider =
    FutureProvider.family<void, ArchiveChatParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.archiveChat(params.chatId, params.userId);
});

/// Провайдер для разархивирования чата
final unarchiveChatProvider =
    FutureProvider.family<void, UnarchiveChatParams>((ref, params) async {
  final service = ref.read(enhancedChatsServiceProvider);
  await service.unarchiveChat(params.chatId, params.userId);
});

/// Провайдер для поиска по чатам
final searchChatsProvider =
    FutureProvider.family<List<EnhancedChat>, SearchChatsParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.searchChats(params.userId, params.query);
});

/// Провайдер для поиска по сообщениям
final searchMessagesProvider =
    FutureProvider.family<List<EnhancedMessage>, SearchMessagesParams>((
  ref,
  params,
) async {
  final service = ref.read(enhancedChatsServiceProvider);
  return service.searchMessages(params.chatId, params.query);
});

/// Параметры для получения сообщений чата
class ChatMessagesParams {
  const ChatMessagesParams(
      {required this.chatId, this.limit = 50, this.startAfter,});
  final String chatId;
  final int limit;
  final DocumentSnapshot? startAfter;
}

/// Параметры для отправки сообщения
class SendMessageParams {
  const SendMessageParams({required this.message});
  final EnhancedMessage message;
}

/// Параметры для отправки текстового сообщения
class SendTextMessageParams {
  const SendTextMessageParams({
    required this.chatId,
    required this.senderId,
    required this.text,
    this.replyTo,
  });
  final String chatId;
  final String senderId;
  final String text;
  final MessageReply? replyTo;
}

/// Параметры для отправки медиа сообщения
class SendMediaMessageParams {
  const SendMediaMessageParams({
    required this.chatId,
    required this.senderId,
    required this.attachments,
    this.caption,
    this.replyTo,
  });
  final String chatId;
  final String senderId;
  final List<MessageAttachment> attachments;
  final String? caption;
  final MessageReply? replyTo;
}

/// Параметры для отправки голосового сообщения
class SendVoiceMessageParams {
  const SendVoiceMessageParams({
    required this.chatId,
    required this.senderId,
    required this.voiceAttachment,
    this.replyTo,
  });
  final String chatId;
  final String senderId;
  final MessageAttachment voiceAttachment;
  final MessageReply? replyTo;
}

/// Параметры для пересылки сообщения
class ForwardMessageParams {
  const ForwardMessageParams({
    required this.originalMessageId,
    required this.originalChatId,
    required this.newChatId,
    required this.senderId,
  });
  final String originalMessageId;
  final String originalChatId;
  final String newChatId;
  final String senderId;
}

/// Параметры для редактирования сообщения
class EditMessageParams {
  const EditMessageParams(
      {required this.chatId, required this.messageId, required this.newText,});
  final String chatId;
  final String messageId;
  final String newText;
}

/// Параметры для удаления сообщения
class DeleteMessageParams {
  const DeleteMessageParams({required this.chatId, required this.messageId});
  final String chatId;
  final String messageId;
}

/// Параметры для добавления реакции
class AddReactionParams {
  const AddReactionParams({
    required this.chatId,
    required this.messageId,
    required this.userId,
    required this.emoji,
  });
  final String chatId;
  final String messageId;
  final String userId;
  final String emoji;
}

/// Параметры для удаления реакции
class RemoveReactionParams {
  const RemoveReactionParams({
    required this.chatId,
    required this.messageId,
    required this.userId,
    required this.emoji,
  });
  final String chatId;
  final String messageId;
  final String userId;
  final String emoji;
}

/// Параметры для отметки сообщений как прочитанных
class MarkMessagesAsReadParams {
  const MarkMessagesAsReadParams({
    required this.chatId,
    required this.userId,
    required this.messageIds,
  });
  final String chatId;
  final String userId;
  final List<String> messageIds;
}

/// Параметры для создания личного чата
class CreateDirectChatParams {
  const CreateDirectChatParams({required this.userId1, required this.userId2});
  final String userId1;
  final String userId2;
}

/// Параметры для создания группового чата
class CreateGroupChatParams {
  const CreateGroupChatParams({
    required this.creatorId,
    required this.name,
    required this.memberIds,
    this.description,
    this.avatarUrl,
  });
  final String creatorId;
  final String name;
  final List<String> memberIds;
  final String? description;
  final String? avatarUrl;
}

/// Параметры для закрепления чата
class PinChatParams {
  const PinChatParams({required this.chatId, required this.userId});
  final String chatId;
  final String userId;
}

/// Параметры для открепления чата
class UnpinChatParams {
  const UnpinChatParams({required this.chatId, required this.userId});
  final String chatId;
  final String userId;
}

/// Параметры для заглушения чата
class MuteChatParams {
  const MuteChatParams({required this.chatId, required this.userId});
  final String chatId;
  final String userId;
}

/// Параметры для разглушения чата
class UnmuteChatParams {
  const UnmuteChatParams({required this.chatId, required this.userId});
  final String chatId;
  final String userId;
}

/// Параметры для архивирования чата
class ArchiveChatParams {
  const ArchiveChatParams({required this.chatId, required this.userId});
  final String chatId;
  final String userId;
}

/// Параметры для разархивирования чата
class UnarchiveChatParams {
  const UnarchiveChatParams({required this.chatId, required this.userId});
  final String chatId;
  final String userId;
}

/// Параметры для поиска по чатам
class SearchChatsParams {
  const SearchChatsParams({required this.userId, required this.query});
  final String userId;
  final String query;
}

/// Параметры для поиска по сообщениям
class SearchMessagesParams {
  const SearchMessagesParams({required this.chatId, required this.query});
  final String chatId;
  final String query;
}
