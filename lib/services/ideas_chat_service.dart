import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/event_idea.dart';

/// Типы сообщений с идеями
enum IdeaMessageType {
  ideaShare, // Поделиться идеей
  ideaRequest, // Запрос идеи
  ideaComment, // Комментарий к идее
  ideaLike, // Лайк идеи
}

/// Модель сообщения с идеей
class IdeaMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String ideaId;
  final IdeaMessageType type;
  final String? text;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  const IdeaMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.ideaId,
    required this.type,
    this.text,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  factory IdeaMessage.fromMap(Map<String, dynamic> data) => IdeaMessage(
        id: data['id'] as String? ?? '',
        chatId: data['chatId'] as String? ?? '',
        senderId: data['senderId'] as String? ?? '',
        receiverId: data['receiverId'] as String? ?? '',
        ideaId: data['ideaId'] as String? ?? '',
        type: IdeaMessageType.values.firstWhere(
          (e) => e.name == (data['type'] as String?),
          orElse: () => IdeaMessageType.ideaShare,
        ),
        text: data['text'] as String?,
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        isRead: data['isRead'] as bool? ?? false,
        metadata: data['metadata'] != null 
            ? Map<String, dynamic>.from(data['metadata'])
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'ideaId': ideaId,
        'type': type.name,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'metadata': metadata,
      };
}

/// Сервис для интеграции идей с чатами
class IdeasChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Отправить идею в чат
  Future<void> shareIdeaInChat({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String ideaId,
    String? message,
  }) async {
    try {
      final ideaMessage = IdeaMessage(
        id: '', // Будет установлен Firestore
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        ideaId: ideaId,
        type: IdeaMessageType.ideaShare,
        text: message,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('ideaMessages').add(ideaMessage.toMap());
      
      // Обновляем последнее сообщение в чате
      await _updateChatLastMessage(chatId, ideaMessage);
      
      debugPrint('Idea shared in chat: $chatId');
    } catch (e) {
      debugPrint('Error sharing idea in chat: $e');
      throw Exception('Ошибка отправки идеи в чат: $e');
    }
  }

  /// Запросить идею у специалиста
  Future<void> requestIdeaFromSpecialist({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String ideaId,
    String? requestText,
  }) async {
    try {
      final ideaMessage = IdeaMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        ideaId: ideaId,
        type: IdeaMessageType.ideaRequest,
        text: requestText ?? 'Можете ли вы реализовать эту идею?',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('ideaMessages').add(ideaMessage.toMap());
      
      // Обновляем последнее сообщение в чате
      await _updateChatLastMessage(chatId, ideaMessage);
      
      debugPrint('Idea requested from specialist: $chatId');
    } catch (e) {
      debugPrint('Error requesting idea from specialist: $e');
      throw Exception('Ошибка запроса идеи у специалиста: $e');
    }
  }

  /// Добавить комментарий к идее в чате
  Future<void> commentOnIdea({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String ideaId,
    required String comment,
  }) async {
    try {
      final ideaMessage = IdeaMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        ideaId: ideaId,
        type: IdeaMessageType.ideaComment,
        text: comment,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('ideaMessages').add(ideaMessage.toMap());
      
      // Обновляем последнее сообщение в чате
      await _updateChatLastMessage(chatId, ideaMessage);
      
      debugPrint('Idea commented in chat: $chatId');
    } catch (e) {
      debugPrint('Error commenting on idea in chat: $e');
      throw Exception('Ошибка комментария к идее: $e');
    }
  }

  /// Получить сообщения с идеями для чата
  Stream<List<IdeaMessage>> getIdeaMessagesForChat(String chatId) {
    return _firestore
        .collection('ideaMessages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return IdeaMessage.fromMap(data);
      }).toList();
    });
  }

  /// Получить все сообщения с идеями пользователя
  Stream<List<IdeaMessage>> getUserIdeaMessages(String userId) {
    return _firestore
        .collection('ideaMessages')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return IdeaMessage.fromMap(data);
      }).toList();
    });
  }

  /// Отметить сообщение как прочитанное
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('ideaMessages').doc(messageId).update({
        'isRead': true,
      });
      
      debugPrint('Message marked as read: $messageId');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Получить количество непрочитанных сообщений с идеями
  Future<int> getUnreadIdeaMessagesCount(String userId) async {
    try {
      final query = await _firestore
          .collection('ideaMessages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return query.docs.length;
    } catch (e) {
      debugPrint('Error getting unread messages count: $e');
      return 0;
    }
  }

  /// Обновить последнее сообщение в чате
  Future<void> _updateChatLastMessage(String chatId, IdeaMessage message) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': {
          'type': 'idea',
          'ideaId': message.ideaId,
          'text': message.text ?? 'Идея мероприятия',
          'senderId': message.senderId,
          'createdAt': Timestamp.fromDate(message.createdAt),
        },
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
    }
  }

  /// Получить идеи, которыми поделились в чате
  Future<List<EventIdea>> getSharedIdeasInChat(String chatId) async {
    try {
      final messagesQuery = await _firestore
          .collection('ideaMessages')
          .where('chatId', isEqualTo: chatId)
          .where('type', isEqualTo: IdeaMessageType.ideaShare.name)
          .get();

      if (messagesQuery.docs.isEmpty) return [];

      final ideaIds = messagesQuery.docs
          .map((doc) => doc.data()['ideaId'] as String)
          .toSet()
          .toList();

      final ideas = <EventIdea>[];
      for (final ideaId in ideaIds) {
        final ideaDoc = await _firestore.collection('eventIdeas').doc(ideaId).get();
        if (ideaDoc.exists) {
          ideas.add(EventIdea.fromDocument(ideaDoc));
        }
      }

      return ideas;
    } catch (e) {
      debugPrint('Error getting shared ideas in chat: $e');
      return [];
    }
  }

  /// Создать чат для обсуждения идеи
  Future<String> createIdeaChat({
    required String customerId,
    required String specialistId,
    required String ideaId,
    String? initialMessage,
  }) async {
    try {
      final chatData = {
        'participants': [customerId, specialistId],
        'type': 'idea_discussion',
        'ideaId': ideaId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'lastMessage': {
          'type': 'idea',
          'ideaId': ideaId,
          'text': initialMessage ?? 'Обсуждение идеи мероприятия',
          'senderId': customerId,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        },
      };

      final chatRef = await _firestore.collection('chats').add(chatData);
      
      // Отправляем первое сообщение с идеей
      if (initialMessage != null) {
        await shareIdeaInChat(
          chatId: chatRef.id,
          senderId: customerId,
          receiverId: specialistId,
          ideaId: ideaId,
          message: initialMessage,
        );
      }
      
      debugPrint('Idea chat created: ${chatRef.id}');
      return chatRef.id;
    } catch (e) {
      debugPrint('Error creating idea chat: $e');
      throw Exception('Ошибка создания чата для обсуждения идеи: $e');
    }
  }

  /// Получить чаты, связанные с идеями
  Stream<List<Map<String, dynamic>>> getIdeaChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('type', isEqualTo: 'idea_discussion')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Удалить сообщение с идеей
  Future<void> deleteIdeaMessage(String messageId) async {
    try {
      await _firestore.collection('ideaMessages').doc(messageId).delete();
      debugPrint('Idea message deleted: $messageId');
    } catch (e) {
      debugPrint('Error deleting idea message: $e');
      throw Exception('Ошибка удаления сообщения: $e');
    }
  }

  /// Получить статистику сообщений с идеями
  Future<Map<String, dynamic>> getIdeaMessagesStats(String userId) async {
    try {
      final sentQuery = await _firestore
          .collection('ideaMessages')
          .where('senderId', isEqualTo: userId)
          .get();

      final receivedQuery = await _firestore
          .collection('ideaMessages')
          .where('receiverId', isEqualTo: userId)
          .get();

      final unreadQuery = await _firestore
          .collection('ideaMessages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return {
        'sentCount': sentQuery.docs.length,
        'receivedCount': receivedQuery.docs.length,
        'unreadCount': unreadQuery.docs.length,
        'totalChats': await _getTotalIdeaChatsCount(userId),
      };
    } catch (e) {
      debugPrint('Error getting idea messages stats: $e');
      return {};
    }
  }

  /// Получить общее количество чатов с идеями
  Future<int> _getTotalIdeaChatsCount(String userId) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .where('type', isEqualTo: 'idea_discussion')
          .get();
      
      return query.docs.length;
    } catch (e) {
      debugPrint('Error getting total idea chats count: $e');
      return 0;
    }
  }
}
