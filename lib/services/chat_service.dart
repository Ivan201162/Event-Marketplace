import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/upload_service.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';

/// Сервис для работы с чатом
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final UploadService _uploadService = UploadService();

  // Коллекции
  static const String _chatsCollection = 'chats';
  static const String _messagesCollection = 'messages';
  static const String _usersCollection = 'users';

  /// Создать чат
  Future<Chat> createChat({
    required String name,
    String? description,
    required List<String> participantIds,
    String? avatar,
    bool isGroup = false,
  }) async {
    try {
      SafeLog.info('ChatService: Creating chat with ${participantIds.length} participants');

      // Проверяем, существует ли уже чат между этими участниками (для личных чатов)
      if (!isGroup && participantIds.length == 2) {
        final existingChat = await _findExistingPrivateChat(participantIds);
        if (existingChat != null) {
          SafeLog.info('ChatService: Existing private chat found: ${existingChat.id}');
          return existingChat;
        }
      }

      // Получаем имена участников
      final participantNames = <String, String>{};
      final participantAvatars = <String, String>{};

      for (final participantId in participantIds) {
        try {
          final userDoc = await _firestore
              .collection(_usersCollection)
              .doc(participantId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            participantNames[participantId] = userData['name'] ?? 'Неизвестный пользователь';
            participantAvatars[participantId] = userData['photoUrl'];
          }
        } catch (e) {
          SafeLog.warning('ChatService: Could not fetch user data for $participantId: $e');
          participantNames[participantId] = 'Неизвестный пользователь';
        }
      }

      // Создаем чат
      final chatData = {
        'name': name,
        'description': description,
        'avatar': avatar,
        'participants': participantIds,
        'participantNames': participantNames,
        'participantAvatars': participantAvatars,
        'isGroup': isGroup,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      };

      final chatRef = await _firestore.collection(_chatsCollection).add(chatData);
      
      SafeLog.info('ChatService: Chat created successfully: ${chatRef.id}');

      return Chat(
        id: chatRef.id,
        name: name,
        description: description,
        avatar: avatar,
        participants: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        isGroup: isGroup,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error creating chat', e, stackTrace);
      rethrow;
    }
  }

  /// Найти существующий личный чат
  Future<Chat?> _findExistingPrivateChat(List<String> participantIds) async {
    try {
      final query = await _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: participantIds[0])
          .where('isGroup', isEqualTo: false)
          .get();

      for (final doc in query.docs) {
        final chat = Chat.fromDocument(doc);
        if (chat.participants.length == 2 && 
            chat.participants.contains(participantIds[0]) &&
            chat.participants.contains(participantIds[1])) {
          return chat;
        }
      }
      
      return null;
    } catch (e) {
      SafeLog.warning('ChatService: Error finding existing private chat: $e');
      return null;
    }
  }

  /// Получить чаты пользователя
  Stream<List<Chat>> getUserChats(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chat.fromDocument(doc)).toList();
    });
  }

  /// Получить сообщения чата
  Stream<List<ChatMessage>> getChatMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromDocument(doc))
          .toList()
          .reversed
          .toList();
    });
  }

  /// Отправить текстовое сообщение
  Future<ChatMessage> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    String? senderAvatar,
    String? replyToMessageId,
  }) async {
    try {
      SafeLog.info('ChatService: Sending text message to chat $chatId');

      final message = ChatMessage(
        id: '', // Будет установлен Firestore
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        type: MessageType.text,
        content: content,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
      );

      final messageRef = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .add(message.toMap());

      // Обновляем статус сообщения
      await messageRef.update({
        'id': messageRef.id,
        'status': MessageStatus.sent.name,
      });

      // Обновляем информацию о последнем сообщении в чате
      await _updateChatLastMessage(chatId, messageRef.id, content, MessageType.text, senderId);

      SafeLog.info('ChatService: Text message sent successfully: ${messageRef.id}');

      return message.copyWith(
        id: messageRef.id,
        status: MessageStatus.sent,
      );
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error sending text message', e, stackTrace);
      rethrow;
    }
  }

  /// Отправить сообщение с вложением
  Future<ChatMessage> sendAttachmentMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required File file,
    required MessageType messageType,
    String? senderAvatar,
    String? replyToMessageId,
    String? caption,
  }) async {
    try {
      SafeLog.info('ChatService: Sending attachment message to chat $chatId');

      // Загружаем файл
      final uploadResult = await _uploadService.uploadFile(
        file,
        fileType: _getFileTypeFromMessageType(messageType),
        customPath: 'chat/$chatId/${DateTime.now().millisecondsSinceEpoch}',
      );

      final message = ChatMessage(
        id: '', // Будет установлен Firestore
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        type: messageType,
        content: caption ?? '',
        fileUrl: uploadResult.url,
        fileName: uploadResult.fileName,
        fileSize: uploadResult.fileSize,
        thumbnailUrl: uploadResult.thumbnailUrl,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
        metadata: uploadResult.metadata,
      );

      final messageRef = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .add(message.toMap());

      // Обновляем статус сообщения
      await messageRef.update({
        'id': messageRef.id,
        'status': MessageStatus.sent.name,
      });

      // Обновляем информацию о последнем сообщении в чате
      final lastMessageContent = caption ?? message.typeName;
      await _updateChatLastMessage(chatId, messageRef.id, lastMessageContent, messageType, senderId);

      SafeLog.info('ChatService: Attachment message sent successfully: ${messageRef.id}');

      return message.copyWith(
        id: messageRef.id,
        status: MessageStatus.sent,
      );
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error sending attachment message', e, stackTrace);
      rethrow;
    }
  }

  /// Отправить сообщение с вложением из байтов
  Future<ChatMessage> sendAttachmentMessageFromBytes({
    required String chatId,
    required String senderId,
    required String senderName,
    required List<int> bytes,
    required String fileName,
    required MessageType messageType,
    String? senderAvatar,
    String? replyToMessageId,
    String? caption,
  }) async {
    try {
      SafeLog.info('ChatService: Sending attachment message from bytes to chat $chatId');

      // Загружаем файл
      final uploadResult = await _uploadService.uploadFileFromBytes(
        bytes,
        fileName,
        _getFileTypeFromMessageType(messageType),
        customPath: 'chat/$chatId/${DateTime.now().millisecondsSinceEpoch}',
      );

      final message = ChatMessage(
        id: '', // Будет установлен Firestore
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        type: messageType,
        content: caption ?? '',
        fileUrl: uploadResult.url,
        fileName: uploadResult.fileName,
        fileSize: uploadResult.fileSize,
        thumbnailUrl: uploadResult.thumbnailUrl,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
        metadata: uploadResult.metadata,
      );

      final messageRef = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .add(message.toMap());

      // Обновляем статус сообщения
      await messageRef.update({
        'id': messageRef.id,
        'status': MessageStatus.sent.name,
      });

      // Обновляем информацию о последнем сообщении в чате
      final lastMessageContent = caption ?? message.typeName;
      await _updateChatLastMessage(chatId, messageRef.id, lastMessageContent, messageType, senderId);

      SafeLog.info('ChatService: Attachment message from bytes sent successfully: ${messageRef.id}');

      return message.copyWith(
        id: messageRef.id,
        status: MessageStatus.sent,
      );
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error sending attachment message from bytes', e, stackTrace);
      rethrow;
    }
  }

  /// Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String chatId, String userId, List<String> messageIds) async {
    try {
      SafeLog.info('ChatService: Marking ${messageIds.length} messages as read in chat $chatId');

      final batch = _firestore.batch();

      for (final messageId in messageIds) {
        final messageRef = _firestore
            .collection(_chatsCollection)
            .doc(chatId)
            .collection(_messagesCollection)
            .doc(messageId);

        batch.update(messageRef, {
          'readBy': FieldValue.arrayUnion([userId]),
          'status': MessageStatus.read.name,
        });
      }

      await batch.commit();

      // Обновляем счетчик непрочитанных сообщений
      await _updateUnreadCount(chatId, userId, 0);

      SafeLog.info('ChatService: Messages marked as read successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error marking messages as read', e, stackTrace);
      rethrow;
    }
  }

  /// Редактировать сообщение
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    try {
      SafeLog.info('ChatService: Editing message $messageId in chat $chatId');

      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'content': newContent,
        'editedAt': FieldValue.serverTimestamp(),
      });

      SafeLog.info('ChatService: Message edited successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error editing message', e, stackTrace);
      rethrow;
    }
  }

  /// Удалить сообщение
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      SafeLog.info('ChatService: Deleting message $messageId in chat $chatId');

      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'isDeleted': true,
        'content': 'Сообщение удалено',
      });

      SafeLog.info('ChatService: Message deleted successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error deleting message', e, stackTrace);
      rethrow;
    }
  }

  /// Обновить информацию о последнем сообщении в чате
  Future<void> _updateChatLastMessage(
    String chatId,
    String messageId,
    String content,
    MessageType type,
    String senderId,
  ) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessageId': messageId,
        'lastMessageContent': content,
        'lastMessageType': type.name,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      SafeLog.warning('ChatService: Error updating chat last message: $e');
    }
  }

  /// Обновить счетчик непрочитанных сообщений
  Future<void> _updateUnreadCount(String chatId, String userId, int count) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'unreadCount': count,
      });
    } catch (e) {
      SafeLog.warning('ChatService: Error updating unread count: $e');
    }
  }

  /// Преобразовать тип сообщения в тип файла
  FileType _getFileTypeFromMessageType(MessageType messageType) {
    switch (messageType) {
      case MessageType.image:
        return FileType.image;
      case MessageType.video:
        return FileType.video;
      case MessageType.audio:
        return FileType.audio;
      case MessageType.file:
        return FileType.document;
      default:
        return FileType.other;
    }
  }

  /// Получить чат по ID
  Future<Chat?> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (doc.exists) {
        return Chat.fromDocument(doc);
      }
      return null;
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error getting chat', e, stackTrace);
      return null;
    }
  }

  /// Добавить участника в чат
  Future<void> addParticipant(String chatId, String userId, String userName, String? userAvatar) async {
    try {
      SafeLog.info('ChatService: Adding participant $userId to chat $chatId');

      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'participantNames.$userId': userName,
        'participantAvatars.$userId': userAvatar,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      SafeLog.info('ChatService: Participant added successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error adding participant', e, stackTrace);
      rethrow;
    }
  }

  /// Удалить участника из чата
  Future<void> removeParticipant(String chatId, String userId) async {
    try {
      SafeLog.info('ChatService: Removing participant $userId from chat $chatId');

      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'participantNames.$userId': FieldValue.delete(),
        'participantAvatars.$userId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      SafeLog.info('ChatService: Participant removed successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error removing participant', e, stackTrace);
      rethrow;
    }
  }

  /// Обновить настройки чата
  Future<void> updateChatSettings(String chatId, Map<String, dynamic> settings) async {
    try {
      SafeLog.info('ChatService: Updating chat settings for $chatId');

      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'settings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      SafeLog.info('ChatService: Chat settings updated successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ChatService: Error updating chat settings', e, stackTrace);
      rethrow;
    }
  }

  /// Поиск сообщений в чате
  Stream<List<ChatMessage>> searchMessages(String chatId, String query) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesCollection)
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThan: query + '\uf8ff')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromDocument(doc))
          .toList();
    });
  }
}