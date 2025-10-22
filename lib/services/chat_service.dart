import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';

/// Сервис для работы с чатами
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Получить список чатов пользователя
  Stream<List<Chat>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
    });
  }

  /// Получить сообщения чата
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  /// Создать новый чат
  Future<String> createChat({
    required List<String> participants,
    String? name,
    String? description,
    ChatType type = ChatType.direct,
  }) async {
    try {
      final chatData = {
        'name': name ?? _generateChatName(participants),
        'description': description,
        'type': type.value,
        'participants': participants,
        'lastMessageId': null,
        'lastMessageContent': null,
        'lastMessageSenderId': null,
        'lastMessageAt': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isActive': true,
        'unreadCounts': {},
      };

      final docRef = await _firestore.collection('chats').add(chatData);
      
      // Инициализируем счетчики непрочитанных сообщений
      for (final participantId in participants) {
        await _firestore
            .collection('chats')
            .doc(docRef.id)
            .update({
          'unreadCounts.$participantId': 0,
        });
      }

      debugPrint('✅ Chat created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating chat: $e');
      rethrow;
    }
  }

  /// Отправить сообщение
  Future<String> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageData = {
        'chatId': chatId,
        'senderId': user.uid,
        'content': content,
        'type': type.value,
        'status': MessageStatus.sent.value,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'metadata': metadata,
        'replyToMessageId': replyToMessageId,
        'isEdited': false,
      };

      // Добавляем сообщение в подколлекцию
      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Обновляем информацию о последнем сообщении в чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageId': messageRef.id,
        'lastMessageContent': content,
        'lastMessageSenderId': user.uid,
        'lastMessageAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Увеличиваем счетчики непрочитанных сообщений для других участников
      await _updateUnreadCounts(chatId, user.uid);

      debugPrint('✅ Message sent successfully: ${messageRef.id}');
      return messageRef.id;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$userId': 0,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Messages marked as read for user: $userId');
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
      rethrow;
    }
  }

  /// Редактировать сообщение
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
        'isEdited': true,
        'updatedAt': Timestamp.now(),
      });

      // Обновляем последнее сообщение в чате, если это было последнее сообщение
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();
      if (chatData?['lastMessageId'] == messageId) {
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessageContent': newContent,
          'updatedAt': Timestamp.now(),
        });
      }

      debugPrint('✅ Message edited successfully: $messageId');
    } catch (e) {
      debugPrint('❌ Error editing message: $e');
      rethrow;
    }
  }

  /// Удалить сообщение
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      debugPrint('✅ Message deleted successfully: $messageId');
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      rethrow;
    }
  }

  /// Получить или создать прямой чат между двумя пользователями
  Future<String> getOrCreateDirectChat(String otherUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Проверяем, существует ли уже чат между этими пользователями
      final existingChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .where('type', isEqualTo: ChatType.direct.value)
          .get();

      for (final doc in existingChats.docs) {
        final chat = Chat.fromFirestore(doc);
        if (chat.participants.contains(otherUserId) && 
            chat.participants.length == 2) {
          return doc.id;
        }
      }

      // Создаем новый чат
      return await createChat(
        participants: [user.uid, otherUserId],
        type: ChatType.direct,
      );
    } catch (e) {
      debugPrint('❌ Error getting or creating direct chat: $e');
      rethrow;
    }
  }

  /// Получить информацию о чате
  Future<Chat?> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return Chat.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting chat: $e');
      return null;
    }
  }

  /// Удалить чат
  Future<void> deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Chat deleted successfully: $chatId');
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');
      rethrow;
    }
  }

  /// Генерировать имя чата
  String _generateChatName(List<String> participants) {
    if (participants.length == 2) {
      return 'Прямой чат';
    } else {
      return 'Групповой чат (${participants.length})';
    }
  }

  /// Обновить счетчики непрочитанных сообщений
  Future<void> _updateUnreadCounts(String chatId, String senderId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chat = Chat.fromFirestore(chatDoc);

      final batch = _firestore.batch();
      final chatRef = _firestore.collection('chats').doc(chatId);

      for (final participantId in chat.participants) {
        if (participantId != senderId) {
          final currentCount = chat.unreadCounts[participantId] ?? 0;
          batch.update(chatRef, {
            'unreadCounts.$participantId': currentCount + 1,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ Error updating unread counts: $e');
    }
  }

  /// Получить количество непрочитанных сообщений для пользователя
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final chats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalUnread = 0;
      for (final doc in chats.docs) {
        final chat = Chat.fromFirestore(doc);
        totalUnread += chat.getUnreadCount(userId);
      }

      return totalUnread;
    } catch (e) {
      debugPrint('❌ Error getting total unread count: $e');
      return 0;
    }
  }
}
