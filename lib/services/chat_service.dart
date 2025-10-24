import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';

/// Сервис для работы с чатами
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить чаты пользователя
  Future<List<Chat>> getChats() async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: 'current_user_id') // TODO: Получить ID текущего пользователя
          .orderBy('lastMessageAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Chat.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки чатов: $e');
    }
  }

  /// Загрузить больше чатов
  Future<List<Chat>> getMoreChats(int offset) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: 'current_user_id')
          .orderBy('lastMessageAt', descending: true)
          .startAfter([offset])
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Chat.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки дополнительных чатов: $e');
    }
  }

  /// Поиск чатов
  Future<List<Chat>> searchChats(String query) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('members', arrayContains: 'current_user_id')
          .where('lastMessage', isGreaterThanOrEqualTo: query)
          .where('lastMessage', isLessThan: query + '\uf8ff')
          .orderBy('lastMessage')
          .orderBy('lastMessageAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Chat.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка поиска чатов: $e');
    }
  }

  /// Фильтрация чатов
  Future<List<Chat>> filterChats(String filter) async {
    try {
      Query query = _firestore
          .collection('chats')
          .where('members', arrayContains: 'current_user_id');

      switch (filter) {
        case 'unread':
          query = query.where('unreadCount', isGreaterThan: 0);
          break;
        case 'media':
          query = query.where('hasMedia', isEqualTo: true);
          break;
        default:
          // Все чаты
          break;
      }

      query = query.orderBy('lastMessageAt', descending: true);
      final snapshot = await query.limit(20).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Chat.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка фильтрации чатов: $e');
    }
  }

  /// Создать чат
  Future<String> createChat(String otherUserId, String otherUserName, String? otherUserAvatar) async {
    try {
      final chatData = {
        'type': 'private',
        'members': ['current_user_id', otherUserId], // TODO: Получить ID текущего пользователя
        'memberNames': ['Текущий пользователь', otherUserName], // TODO: Получить имя текущего пользователя
        'memberAvatars': [null, otherUserAvatar],
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'hasMedia': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('chats').add(chatData);
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания чата: $e');
    }
  }

  /// Удалить чат
  Future<void> deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления чата: $e');
    }
  }

  /// Получить сообщения чата
  Future<List<ChatMessage>> getMessages(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки сообщений: $e');
    }
  }

  /// Загрузить больше сообщений
  Future<List<ChatMessage>> getMoreMessages(String chatId, int offset) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .startAfter([offset])
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки дополнительных сообщений: $e');
    }
  }

  /// Отправить сообщение
  Future<void> sendMessage(String chatId, String text, {List<String>? attachments}) async {
    try {
      final messageData = {
        'text': text,
        'senderId': 'current_user_id', // TODO: Получить ID текущего пользователя
        'senderName': 'Текущий пользователь', // TODO: Получить имя текущего пользователя
        'attachments': attachments ?? [],
        'type': 'text',
        'isEdited': false,
        'editedAt': null,
        'reactions': {},
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Обновить информацию о чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка отправки сообщения: $e');
    }
  }

  /// Редактировать сообщение
  Future<void> editMessage(String chatId, String messageId, String newText) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка редактирования сообщения: $e');
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
    } catch (e) {
      throw Exception('Ошибка удаления сообщения: $e');
    }
  }

  /// Отметить как прочитанное
  Future<void> markAsRead(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка отметки как прочитанное: $e');
    }
  }
}