import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/message.dart';
import 'chat_service.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  final Uuid _uuid = const Uuid();

  /// Send a text message
  Future<String> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = Message(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        text: text,
        type: MessageType.text,
        replyToMessageId: replyToMessageId,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update chat last message
      await _chatService.updateChatLastMessage(chatId, messageId, text, now);

      debugPrint('Text message sent: $messageId');
      return messageId;
    } catch (e) {
      debugPrint('Error sending text message: $e');
      throw Exception('Ошибка отправки сообщения: $e');
    }
  }

  /// Send a file message
  Future<String> sendFileMessage({
    required String chatId,
    required String senderId,
    required String fileUrl,
    required String fileName,
    required String fileType,
    required int fileSize,
    required MessageType type,
    String? text,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = Message(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        text: text,
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
        type: type,
        replyToMessageId: replyToMessageId,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update chat last message with file preview
      final previewText = message.previewText;
      await _chatService.updateChatLastMessage(chatId, messageId, previewText, now);

      debugPrint('File message sent: $messageId');
      return messageId;
    } catch (e) {
      debugPrint('Error sending file message: $e');
      throw Exception('Ошибка отправки файла: $e');
    }
  }

  /// Get messages for a chat
  Stream<List<Message>> getChatMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromDocument(doc))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first
    });
  }

  /// Get messages with pagination
  Future<List<Message>> getChatMessagesPaginated(
    String chatId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Message.fromDocument(doc))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('Error getting paginated messages: $e');
      return [];
    }
  }

  /// Edit a message
  Future<void> editMessage(String messageId, String newText) async {
    try {
      await _firestore
          .collection('chats')
          .doc(messageId.split('_')[0]) // Extract chatId from messageId if needed
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('Message edited: $messageId');
    } catch (e) {
      debugPrint('Error editing message: $e');
      throw Exception('Ошибка редактирования сообщения: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      debugPrint('Message deleted: $messageId');
    } catch (e) {
      debugPrint('Error deleting message: $e');
      throw Exception('Ошибка удаления сообщения: $e');
    }
  }

  /// Forward a message to another chat
  Future<String> forwardMessage({
    required String originalMessageId,
    required String originalChatId,
    required String targetChatId,
    required String senderId,
  }) async {
    try {
      // Get original message
      final originalDoc = await _firestore
          .collection('chats')
          .doc(originalChatId)
          .collection('messages')
          .doc(originalMessageId)
          .get();

      if (!originalDoc.exists) {
        throw Exception('Original message not found');
      }

      final originalMessage = Message.fromDocument(originalDoc);
      final messageId = _uuid.v4();
      final now = DateTime.now();

      // Create forwarded message
      final forwardedMessage = originalMessage.copyWith(
        id: messageId,
        chatId: targetChatId,
        senderId: senderId,
        forwardedTo: [...originalMessage.forwardedTo, targetChatId],
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('chats')
          .doc(targetChatId)
          .collection('messages')
          .doc(messageId)
          .set(forwardedMessage.toMap());

      // Update original message's forwardedTo list
      await _firestore
          .collection('chats')
          .doc(originalChatId)
          .collection('messages')
          .doc(originalMessageId)
          .update({
        'forwardedTo': forwardedMessage.forwardedTo,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update target chat's last message
      await _chatService.updateChatLastMessage(
        targetChatId,
        messageId,
        forwardedMessage.previewText,
        now,
      );

      debugPrint('Message forwarded: $messageId');
      return messageId;
    } catch (e) {
      debugPrint('Error forwarding message: $e');
      throw Exception('Ошибка пересылки сообщения: $e');
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String chatId, String messageId, String userId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy.$userId': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Get unread messages count for user in a chat
  Future<int> getUnreadMessagesCount(String chatId, String userId) async {
    try {
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .get();

      int unreadCount = 0;
      for (final doc in messagesQuery.docs) {
        final message = Message.fromDocument(doc);
        // Check if message is read by user
        final readBy = message.metadata['readBy'] as Map<String, dynamic>? ?? {};
        if (!readBy.containsKey(userId) || readBy[userId] != true) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      debugPrint('Error getting unread messages count: $e');
      return 0;
    }
  }

  /// Search messages in a chat
  Future<List<Message>> searchMessages(String chatId, String query) async {
    try {
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .get();

      return messagesQuery.docs
          .map((doc) => Message.fromDocument(doc))
          .where((message) {
            final searchText = '${message.text ?? ''} ${message.fileName ?? ''}'.toLowerCase();
            return searchText.contains(query.toLowerCase());
          })
          .toList();
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }

  /// Get message by ID
  Future<Message?> getMessage(String chatId, String messageId) async {
    try {
      final doc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!doc.exists) return null;
      return Message.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting message: $e');
      return null;
    }
  }

  /// Update message status
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating message status: $e');
    }
  }

  /// Get message statistics for a chat
  Future<Map<String, dynamic>> getMessageStatistics(String chatId) async {
    try {
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final messages = messagesQuery.docs.map((doc) => Message.fromDocument(doc)).toList();
      
      final stats = <String, dynamic>{
        'totalMessages': messages.length,
        'textMessages': messages.where((m) => m.type == MessageType.text).length,
        'imageMessages': messages.where((m) => m.type == MessageType.image).length,
        'videoMessages': messages.where((m) => m.type == MessageType.video).length,
        'fileMessages': messages.where((m) => m.type == MessageType.file).length,
        'botMessages': messages.where((m) => m.type == MessageType.bot).length,
        'systemMessages': messages.where((m) => m.type == MessageType.system).length,
      };

      return stats;
    } catch (e) {
      debugPrint('Error getting message statistics: $e');
      return {};
    }
  }
}
