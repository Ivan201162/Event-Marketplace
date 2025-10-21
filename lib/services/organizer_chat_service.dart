import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/organizer_chat.dart';
import '../models/specialist.dart';

/// Сервис для управления чатами с организатором
class OrganizerChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatsCollection = 'organizer_chats';
  static const String _messagesCollection = 'organizer_messages';

  /// Создать новый чат с организатором
  Future<String> createChat({
    required String customerId,
    required String customerName,
    required String organizerId,
    required String organizerName,
    required String eventTitle,
    String? eventDescription,
    required DateTime eventDate,
  }) async {
    try {
      final chatId = '${customerId}_${organizerId}_${DateTime.now().millisecondsSinceEpoch}';

      final chat = OrganizerChat(
        id: chatId,
        customerId: customerId,
        customerName: customerName,
        organizerId: organizerId,
        organizerName: organizerName,
        eventTitle: eventTitle,
        eventDescription: eventDescription,
        eventDate: eventDate,
        status: OrganizerChatStatus.active,
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection(_chatsCollection).doc(chatId).set(chat.toMap());

      // Отправляем приветственное сообщение
      await sendMessage(
        chatId: chatId,
        senderId: customerId,
        senderName: customerName,
        senderType: 'customer',
        type: OrganizerMessageType.text,
        text:
            'Здравствуйте! Меня интересует организация мероприятия "$eventTitle". Можете ли вы помочь?',
      );

      return chatId;
    } on Exception catch (e) {
      debugPrint('Ошибка создания чата с организатором: $e');
      rethrow;
    }
  }

  /// Получить чаты заказчика
  Future<List<OrganizerChat>> getCustomerChats(String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_chatsCollection)
          .where('customerId', isEqualTo: customerId)
          .orderBy('lastMessageAt', descending: true)
          .get();

      return querySnapshot.docs.map(OrganizerChat.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения чатов заказчика: $e');
      return [];
    }
  }

  /// Получить чаты организатора
  Future<List<OrganizerChat>> getOrganizerChats(String organizerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_chatsCollection)
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('lastMessageAt', descending: true)
          .get();

      return querySnapshot.docs.map(OrganizerChat.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения чатов организатора: $e');
      return [];
    }
  }

  /// Поток чатов заказчика
  Stream<List<OrganizerChat>> getCustomerChatsStream(String customerId) => _firestore
      .collection(_chatsCollection)
      .where('customerId', isEqualTo: customerId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(OrganizerChat.fromDocument).toList());

  /// Поток чатов организатора
  Stream<List<OrganizerChat>> getOrganizerChatsStream(String organizerId) => _firestore
      .collection(_chatsCollection)
      .where('organizerId', isEqualTo: organizerId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(OrganizerChat.fromDocument).toList());

  /// Получить чат по ID
  Future<OrganizerChat?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (doc.exists) {
        return OrganizerChat.fromDocument(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка получения чата: $e');
      return null;
    }
  }

  /// Поток чата по ID
  Stream<OrganizerChat?> getChatStream(String chatId) => _firestore
      .collection(_chatsCollection)
      .doc(chatId)
      .snapshots()
      .map((doc) => doc.exists ? OrganizerChat.fromDocument(doc) : null);

  /// Отправить сообщение
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required OrganizerMessageType type,
    required String text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageId = '${chatId}_${DateTime.now().millisecondsSinceEpoch}';

      final message = OrganizerMessage(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        type: type,
        text: text,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      // Добавляем сообщение в коллекцию сообщений
      await _firestore.collection(_messagesCollection).doc(messageId).set(message.toMap());

      // Обновляем чат
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        'lastMessageText': text,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'hasUnreadMessages': senderType == 'customer', // Организатор не прочитал
        'unreadCount': senderType == 'customer' ? FieldValue.increment(1) : 0,
      });
    } on Exception catch (e) {
      debugPrint('Ошибка отправки сообщения: $e');
      rethrow;
    }
  }

  /// Предложить специалиста
  Future<void> proposeSpecialist({
    required String chatId,
    required String organizerId,
    required String organizerName,
    required Specialist specialist,
    String? message,
  }) async {
    try {
      final proposal = SpecialistProposal(
        specialistId: specialist.id,
        specialistName: specialist.name,
        specialistCategory: specialist.category.displayName,
        hourlyRate: specialist.hourlyRate,
        specialistPhoto: specialist.avatarUrl,
        description: specialist.description,
        services: specialist.services,
        rating: specialist.rating,
        reviewCount: specialist.reviewCount,
        isAvailable: specialist.isAvailable,
      );

      await sendMessage(
        chatId: chatId,
        senderId: organizerId,
        senderName: organizerName,
        senderType: 'organizer',
        type: OrganizerMessageType.specialistProposal,
        text: message ?? 'Предлагаю вам этого специалиста для вашего мероприятия',
        metadata: proposal.toMap(),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка предложения специалиста: $e');
      rethrow;
    }
  }

  /// Отклонить специалиста
  Future<void> rejectSpecialist({
    required String chatId,
    required String customerId,
    required String customerName,
    required String specialistId,
    String? reason,
  }) async {
    try {
      await sendMessage(
        chatId: chatId,
        senderId: customerId,
        senderName: customerName,
        senderType: 'customer',
        type: OrganizerMessageType.specialistRejection,
        text: reason ?? 'Спасибо за предложение, но этот специалист мне не подходит',
        metadata: {'specialistId': specialistId},
      );
    } on Exception catch (e) {
      debugPrint('Ошибка отклонения специалиста: $e');
      rethrow;
    }
  }

  /// Принять специалиста
  Future<void> acceptSpecialist({
    required String chatId,
    required String customerId,
    required String customerName,
    required String specialistId,
    String? message,
  }) async {
    try {
      await sendMessage(
        chatId: chatId,
        senderId: customerId,
        senderName: customerName,
        senderType: 'customer',
        type: OrganizerMessageType.bookingRequest,
        text: message ?? 'Отлично! Хочу забронировать этого специалиста',
        metadata: {'specialistId': specialistId, 'action': 'accept'},
      );
    } on Exception catch (e) {
      debugPrint('Ошибка принятия специалиста: $e');
      rethrow;
    }
  }

  /// Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Получаем все непрочитанные сообщения от другого пользователя
      final messagesSnapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in messagesSnapshot.docs) {
        final message = OrganizerMessage.fromMap(doc.data());
        if (message.senderId != userId) {
          batch.update(doc.reference, {
            'isRead': true,
            'readAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      await batch.commit();

      // Обновляем чат
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'hasUnreadMessages': false,
        'unreadCount': 0,
      });
    } on Exception catch (e) {
      debugPrint('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  /// Обновить статус чата
  Future<void> updateChatStatus(String chatId, OrganizerChatStatus status) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления статуса чата: $e');
      rethrow;
    }
  }

  /// Получить сообщения чата
  Future<List<OrganizerMessage>> getChatMessages(String chatId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) => OrganizerMessage.fromMap(doc.data())).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения сообщений чата: $e');
      return [];
    }
  }

  /// Поток сообщений чата
  Stream<List<OrganizerMessage>> getChatMessagesStream(String chatId) => _firestore
      .collection(_messagesCollection)
      .where('chatId', isEqualTo: chatId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => OrganizerMessage.fromMap(doc.data())).toList());

  /// Удалить чат
  Future<void> deleteChat(String chatId) async {
    try {
      // Удаляем все сообщения чата
      final messagesSnapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем сам чат
      batch.delete(_firestore.collection(_chatsCollection).doc(chatId));

      await batch.commit();
    } on Exception catch (e) {
      debugPrint('Ошибка удаления чата: $e');
      rethrow;
    }
  }

  /// Получить количество непрочитанных чатов
  Future<int> getUnreadChatsCount(String userId, String userType) async {
    try {
      final field = userType == 'customer' ? 'customerId' : 'organizerId';
      final querySnapshot = await _firestore
          .collection(_chatsCollection)
          .where(field, isEqualTo: userId)
          .where('hasUnreadMessages', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } on Exception catch (e) {
      debugPrint('Ошибка получения количества непрочитанных чатов: $e');
      return 0;
    }
  }

  /// Поток количества непрочитанных чатов
  Stream<int> getUnreadChatsCountStream(String userId, String userType) {
    final field = userType == 'customer' ? 'customerId' : 'organizerId';
    return _firestore
        .collection(_chatsCollection)
        .where(field, isEqualTo: userId)
        .where('hasUnreadMessages', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
