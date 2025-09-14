import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';

/// Сервис для управления чатами и сообщениями
class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Создать чат
  Future<Chat> createChat({
    required String customerId,
    required String specialistId,
    String? bookingId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Проверяем, существует ли уже чат между этими пользователями
      final existingChat = await getChatBetweenUsers(customerId, specialistId);
      if (existingChat != null) {
        return existingChat;
      }

      final chat = Chat(
        id: _generateChatId(),
        customerId: customerId,
        specialistId: specialistId,
        bookingId: bookingId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: metadata,
      );

      await _db.collection('chats').doc(chat.id).set(chat.toMap());
      return chat;
    } catch (e) {
      print('Ошибка создания чата: $e');
      throw Exception('Не удалось создать чат: $e');
    }
  }

  /// Получить чат между пользователями
  Future<Chat?> getChatBetweenUsers(String customerId, String specialistId) async {
    try {
      final querySnapshot = await _db
          .collection('chats')
          .where('customerId', isEqualTo: customerId)
          .where('specialistId', isEqualTo: specialistId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Chat.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Ошибка получения чата между пользователями: $e');
      return null;
    }
  }

  /// Получить чат по ID
  Future<Chat?> getChat(String chatId) async {
    try {
      final doc = await _db.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return Chat.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения чата: $e');
      return null;
    }
  }

  /// Поток чатов для пользователя
  Stream<List<Chat>> getChatsForUserStream(String userId, {bool isSpecialist = false}) {
    final field = isSpecialist ? 'specialistId' : 'customerId';
    
    return _db
        .collection('chats')
        .where(field, isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Chat.fromDocument(doc))
            .toList());
  }

  /// Отправить сообщение
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? receiverId,
    String? replyToMessageId,
    List<String> attachments = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = ChatMessage(
        id: _generateMessageId(),
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        type: type,
        content: content,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        replyToMessageId: replyToMessageId,
        attachments: attachments,
        metadata: metadata,
      );

      // Сохраняем сообщение
      await _db.collection('messages').doc(message.id).set(message.toMap());

      // Обновляем чат
      await _updateChatLastMessage(chatId, message);

      return message;
    } catch (e) {
      print('Ошибка отправки сообщения: $e');
      throw Exception('Не удалось отправить сообщение: $e');
    }
  }

  /// Получить сообщения чата
  Future<List<ChatMessage>> getChatMessages(String chatId, {int limit = 50}) async {
    try {
      final querySnapshot = await _db
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatMessage.fromDocument(doc))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      print('Ошибка получения сообщений: $e');
      return [];
    }
  }

  /// Поток сообщений чата
  Stream<List<ChatMessage>> getChatMessagesStream(String chatId, {int limit = 50}) {
    return _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromDocument(doc))
            .toList()
            .reversed
            .toList());
  }

  /// Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final batch = _db.batch();
      
      // Получаем непрочитанные сообщения
      final querySnapshot = await _db
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: MessageStatus.delivered.name)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.read.name,
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();

      // Обновляем счетчик непрочитанных сообщений в чате
      await _updateChatUnreadCount(chatId, userId, 0);
    } catch (e) {
      print('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  /// Отметить сообщение как доставленное
  Future<void> markMessageAsDelivered(String messageId) async {
    try {
      await _db.collection('messages').doc(messageId).update({
        'status': MessageStatus.delivered.name,
      });
    } catch (e) {
      print('Ошибка отметки сообщения как доставленного: $e');
    }
  }

  /// Отметить сообщение как неудачное
  Future<void> markMessageAsFailed(String messageId) async {
    try {
      await _db.collection('messages').doc(messageId).update({
        'status': MessageStatus.failed.name,
      });
    } catch (e) {
      print('Ошибка отметки сообщения как неудачного: $e');
    }
  }

  /// Удалить сообщение
  Future<void> deleteMessage(String messageId) async {
    try {
      await _db.collection('messages').doc(messageId).delete();
    } catch (e) {
      print('Ошибка удаления сообщения: $e');
      throw Exception('Не удалось удалить сообщение: $e');
    }
  }

  /// Удалить чат
  Future<void> deleteChat(String chatId) async {
    try {
      // Помечаем чат как неактивный
      await _db.collection('chats').doc(chatId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка удаления чата: $e');
      throw Exception('Не удалось удалить чат: $e');
    }
  }

  /// Создать системное сообщение
  Future<ChatMessage> createSystemMessage({
    required String chatId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    return await sendMessage(
      chatId: chatId,
      senderId: 'system',
      content: content,
      type: MessageType.system,
      metadata: metadata,
    );
  }

  /// Создать сообщение об обновлении заявки
  Future<ChatMessage> createBookingUpdateMessage({
    required String chatId,
    required String bookingId,
    required String status,
    required String customerId,
    required String specialistId,
  }) async {
    final content = _getBookingUpdateMessage(status);
    return await sendMessage(
      chatId: chatId,
      senderId: 'system',
      content: content,
      type: MessageType.booking_update,
      receiverId: status == 'confirmed' ? customerId : specialistId,
      metadata: {
        'bookingId': bookingId,
        'status': status,
        'type': 'booking_update',
      },
    );
  }

  /// Создать сообщение об обновлении платежа
  Future<ChatMessage> createPaymentUpdateMessage({
    required String chatId,
    required String paymentId,
    required String status,
    required String customerId,
    required String specialistId,
  }) async {
    final content = _getPaymentUpdateMessage(status);
    return await sendMessage(
      chatId: chatId,
      senderId: 'system',
      content: content,
      type: MessageType.payment_update,
      receiverId: status == 'completed' ? specialistId : customerId,
      metadata: {
        'paymentId': paymentId,
        'status': status,
        'type': 'payment_update',
      },
    );
  }

  /// Обновить последнее сообщение в чате
  Future<void> _updateChatLastMessage(String chatId, ChatMessage message) async {
    try {
      await _db.collection('chats').doc(chatId).update({
        'lastMessage': message.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка обновления последнего сообщения в чате: $e');
    }
  }

  /// Обновить счетчик непрочитанных сообщений
  Future<void> _updateChatUnreadCount(String chatId, String userId, int count) async {
    try {
      final chat = await getChat(chatId);
      if (chat == null) return;

      final isSpecialist = chat.specialistId == userId;
      final field = isSpecialist ? 'specialistUnreadCount' : 'customerUnreadCount';

      await _db.collection('chats').doc(chatId).update({
        field: count,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка обновления счетчика непрочитанных сообщений: $e');
    }
  }

  /// Получить сообщение об обновлении заявки
  String _getBookingUpdateMessage(String status) {
    switch (status) {
      case 'confirmed':
        return '✅ Заявка подтверждена специалистом';
      case 'rejected':
        return '❌ Заявка отклонена специалистом';
      case 'cancelled':
        return '🚫 Заявка отменена';
      case 'completed':
        return '🎉 Заявка выполнена';
      default:
        return '📋 Статус заявки изменен на: $status';
    }
  }

  /// Получить сообщение об обновлении платежа
  String _getPaymentUpdateMessage(String status) {
    switch (status) {
      case 'completed':
        return '💰 Платеж успешно завершен';
      case 'failed':
        return '⚠️ Платеж не удался';
      case 'cancelled':
        return '🚫 Платеж отменен';
      default:
        return '💳 Статус платежа изменен на: $status';
    }
  }

  /// Генерировать ID чата
  String _generateChatId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'CHAT_${timestamp}_$random';
  }

  /// Генерировать ID сообщения
  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'MSG_${timestamp}_$random';
  }
}
