import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/app_user.dart';

/// Сервис для работы с чатами и сообщениями
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создание или получение чата между двумя пользователями
  Future<String> getOrCreateChat(String userId1, String userId2) async {
    try {
      // Создаем ID чата (сортируем ID пользователей для консистентности)
      final participants = [userId1, userId2]..sort();
      final chatId = '${participants[0]}_${participants[1]}';

      // Проверяем, существует ли чат
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Создаем новый чат
        final now = DateTime.now();
        final chat = Chat(
          id: chatId,
          participants: participants,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore.collection('chats').doc(chatId).set(chat.toFirestore());
        debugPrint('✅ Chat created: $chatId');
      }

      return chatId;
    } catch (e) {
      debugPrint('❌ Error creating/getting chat: $e');
      rethrow;
    }
  }

  /// Отправка сообщения
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
    String? senderName,
    String? senderAvatar,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      final messageId = _firestore.collection('chats').doc(chatId).collection('messages').doc().id;

      final message = Message(
        id: messageId,
        chatId: chatId,
        text: text,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        timestamp: now,
        type: type,
        metadata: metadata,
      );

      // Сохраняем сообщение
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Обновляем информацию о чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageSenderId': senderId,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Увеличиваем счетчик непрочитанных сообщений для других участников
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final chat = Chat.fromFirestore(chatDoc);
        final unreadCounts = Map<String, int>.from(chat.unreadCounts);
        
        for (final participantId in chat.participants) {
          if (participantId != senderId) {
            unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1;
          }
        }

        await _firestore.collection('chats').doc(chatId).update({
          'unreadCounts': unreadCounts,
        });
      }

      debugPrint('✅ Message sent: $messageId');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Получение сообщений чата в реальном времени
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  /// Получение чатов пользователя в реальном времени
  Stream<List<Chat>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
    });
  }

  /// Получение чатов пользователя с информацией о собеседниках
  Future<List<ChatWithUser>> getUserChatsWithUsers(String userId) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final List<ChatWithUser> chatsWithUsers = [];

      for (final chatDoc in chatsSnapshot.docs) {
        final chat = Chat.fromFirestore(chatDoc);
        final otherUserId = chat.getOtherParticipantId(userId);

        // Получаем информацию о собеседнике
        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final chatWithUser = ChatWithUser(
            chat: chat,
            otherUserId: otherUserId,
            otherUserName: userData['name'],
            otherUserAvatar: userData['avatarUrl'],
            isOnline: userData['isOnline'] ?? false,
          );
          chatsWithUsers.add(chatWithUser);
        }
      }

      return chatsWithUsers;
    } catch (e) {
      debugPrint('❌ Error getting user chats with users: $e');
      return [];
    }
  }

  /// Отметка сообщений как прочитанных
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Получаем все непрочитанные сообщения от других пользователей
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      // Обновляем каждое сообщение
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final messageDoc in messagesSnapshot.docs) {
        batch.update(messageDoc.reference, {
          'read': true,
          'readAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();

      // Обновляем счетчик непрочитанных сообщений в чате
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final chat = Chat.fromFirestore(chatDoc);
        final unreadCounts = Map<String, int>.from(chat.unreadCounts);
        unreadCounts[userId] = 0;

        await _firestore.collection('chats').doc(chatId).update({
          'unreadCounts': unreadCounts,
        });
      }

      debugPrint('✅ Messages marked as read for user: $userId');
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
      rethrow;
    }
  }

  /// Получение информации о чате
  Future<Chat?> getChat(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        return Chat.fromFirestore(chatDoc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting chat: $e');
      return null;
    }
  }

  /// Получение информации о пользователе
  Future<AppUser?> getUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return AppUser.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user: $e');
      return null;
    }
  }

  /// Удаление чата (только для администраторов)
  Future<void> deleteChat(String chatId) async {
    try {
      // Удаляем все сообщения
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }

      // Удаляем чат
      batch.delete(_firestore.collection('chats').doc(chatId));
      await batch.commit();

      debugPrint('✅ Chat deleted: $chatId');
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');
      rethrow;
    }
  }

  /// Получение общего количества непрочитанных сообщений пользователя
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (final chatDoc in chatsSnapshot.docs) {
        final chat = Chat.fromFirestore(chatDoc);
        totalUnread += chat.getUnreadCount(userId);
      }

      return totalUnread;
    } catch (e) {
      debugPrint('❌ Error getting total unread count: $e');
      return 0;
    }
  }

  /// Поиск чатов по имени собеседника
  Future<List<ChatWithUser>> searchChats(String userId, String query) async {
    try {
      final allChats = await getUserChatsWithUsers(userId);
      return allChats.where((chat) {
        final displayName = chat.displayName.toLowerCase();
        return displayName.contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      debugPrint('❌ Error searching chats: $e');
      return [];
    }
  }
}