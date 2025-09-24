import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart' as chat_model;
import '../models/chat_message.dart' as message_model;

/// Сервис для работы с чатами
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить чаты пользователя
  Future<List<chat_model.Chat>> getUserChats(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageAt', descending: true)
          .get();

      return querySnapshot.docs.map(chat_model.Chat.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения чатов: $e');
    }
  }

  /// Получить чат по ID
  Stream<chat_model.Chat?> getChat(String chatId) =>
      _firestore.collection('chats').doc(chatId).snapshots().map((snapshot) =>
          snapshot.exists ? chat_model.Chat.fromDocument(snapshot) : null);

  /// Получить сообщения чата
  Stream<List<message_model.ChatMessage>> getChatMessages(String chatId) =>
      _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(message_model.ChatMessage.fromDocument)
                .toList(),
          );

  /// Отправить сообщение
  Future<void> sendMessage(
    String chatId,
    message_model.ChatMessage message,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Обновить время последнего сообщения в чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.content,
        'lastMessageAt': Timestamp.fromDate(message.timestamp),
        'lastMessageBy': message.senderId,
      });
    } catch (e) {
      throw Exception('Ошибка отправки сообщения: $e');
    }
  }

  /// Создать новый чат
  Future<String> createChat(Map<String, dynamic> chatData) async {
    try {
      final docRef = await _firestore.collection('chats').add(chatData);
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания чата: $e');
    }
  }

  /// Обновить статус сообщения
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления статуса сообщения: $e');
    }
  }

  /// Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('status', isNotEqualTo: message_model.MessageStatus.read.name)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': message_model.MessageStatus.read.name,
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка отметки сообщений как прочитанных: $e');
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

  /// Получить количество непрочитанных сообщений
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      var totalUnread = 0;
      for (final chatDoc in querySnapshot.docs) {
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where(
              'status',
              isNotEqualTo: message_model.MessageStatus.read.name,
            )
            .get();
        totalUnread += messagesSnapshot.docs.length;
      }
      return totalUnread;
    } catch (e) {
      throw Exception(
        'Ошибка получения количества непрочитанных сообщений: $e',
      );
    }
  }
}
