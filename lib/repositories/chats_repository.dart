import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Репозиторий для работы с чатами в Firestore
class ChatsRepository {
  factory ChatsRepository() => _instance;
  ChatsRepository._internal();
  static final ChatsRepository _instance = ChatsRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получение чатов пользователя
  Stream<List<Map<String, dynamic>>> streamList(String userId) {
    try {
      debugPrint('ChatsRepository.streamList: userId=$userId');

      return _firestore
          .collection('chats')
          .where('members', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            debugPrint('ChatsRepository.streamList: получено ${snapshot.docs.length} чатов');

            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return {'id': doc.id, ...data};
            }).toList();
          });
    } catch (e) {
      debugPrint('ChatsRepository.streamList: ошибка запроса: $e');
      return Stream.value([]);
    }
  }

  /// Получение конкретного чата
  Future<Map<String, dynamic>?> getById(String chatId) async {
    try {
      debugPrint('ChatsRepository.getById: chatId=$chatId');

      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        debugPrint('ChatsRepository.getById: чат найден, поля: ${data.keys.toList()}');
        return {'id': doc.id, ...data};
      }
      debugPrint('ChatsRepository.getById: чат не найден');
      return null;
    } catch (e) {
      debugPrint('ChatsRepository.getById: ошибка получения чата: $e');
      return null;
    }
  }

  /// Создание нового чата
  Future<String?> create(Map<String, dynamic> chatData) async {
    try {
      debugPrint('ChatsRepository.create: создание чата с данными: ${chatData.keys.toList()}');

      final docRef = await _firestore.collection('chats').add(chatData);
      debugPrint('ChatsRepository.create: чат создан с ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('ChatsRepository.create: ошибка создания чата: $e');
      return null;
    }
  }

  /// Обновление чата
  Future<bool> update(String chatId, Map<String, dynamic> updates) async {
    try {
      debugPrint(
        'ChatsRepository.update: обновление чата $chatId с полями: ${updates.keys.toList()}',
      );

      await _firestore.collection('chats').doc(chatId).update(updates);
      debugPrint('ChatsRepository.update: чат обновлен успешно');
      return true;
    } catch (e) {
      debugPrint('ChatsRepository.update: ошибка обновления чата: $e');
      return false;
    }
  }

  /// Удаление чата
  Future<bool> delete(String chatId) async {
    try {
      debugPrint('ChatsRepository.delete: удаление чата $chatId');

      await _firestore.collection('chats').doc(chatId).delete();
      debugPrint('ChatsRepository.delete: чат удален успешно');
      return true;
    } catch (e) {
      debugPrint('ChatsRepository.delete: ошибка удаления чата: $e');
      return false;
    }
  }

  /// Получение сообщений чата
  Stream<List<Map<String, dynamic>>> getMessages(String chatId, {int limit = 50}) {
    try {
      debugPrint('ChatsRepository.getMessages: chatId=$chatId, limit=$limit');

      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            debugPrint('ChatsRepository.getMessages: получено ${snapshot.docs.length} сообщений');

            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return {'id': doc.id, ...data};
            }).toList();
          });
    } catch (e) {
      debugPrint('ChatsRepository.getMessages: ошибка получения сообщений: $e');
      return Stream.value([]);
    }
  }

  /// Отправка сообщения
  Future<bool> sendMessage(String chatId, Map<String, dynamic> messageData) async {
    try {
      debugPrint('ChatsRepository.sendMessage: отправка сообщения в чат $chatId');

      // Добавляем сообщение
      await _firestore.collection('chats').doc(chatId).collection('messages').add(messageData);

      // Обновляем последнее сообщение в чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': messageData['text'] ?? 'Медиа сообщение',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('ChatsRepository.sendMessage: сообщение отправлено успешно');
      return true;
    } catch (e) {
      debugPrint('ChatsRepository.sendMessage: ошибка отправки сообщения: $e');
      return false;
    }
  }

  /// Поиск или создание чата между двумя пользователями
  Future<String?> findOrCreateChat(String userId1, String userId2) async {
    try {
      debugPrint('ChatsRepository.findOrCreateChat: userId1=$userId1, userId2=$userId2');

      // Ищем существующий чат
      final existingChats = await _firestore
          .collection('chats')
          .where('members', arrayContains: userId1)
          .get();

      for (final doc in existingChats.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final members = (data['members'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

        if (members.contains(userId2)) {
          debugPrint('ChatsRepository.findOrCreateChat: найден существующий чат ${doc.id}');
          return doc.id;
        }
      }

      // Создаем новый чат
      final chatData = {
        'members': [userId1, userId2],
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final chatId = await create(chatData);
      debugPrint('ChatsRepository.findOrCreateChat: создан новый чат $chatId');
      return chatId;
    } catch (e) {
      debugPrint('ChatsRepository.findOrCreateChat: ошибка поиска/создания чата: $e');
      return null;
    }
  }
}
