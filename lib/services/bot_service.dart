import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/bot_message.dart';
import '../models/message.dart';
import 'message_service.dart';

class BotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MessageService _messageService = MessageService();
  final Uuid _uuid = const Uuid();

  /// Send bot message to chat
  Future<String> sendBotMessage({
    required String chatId,
    required BotMessageType type,
    required String text,
    List<BotAction>? actions,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final botMessageId = _uuid.v4();
      final now = DateTime.now();

      final botMessage = BotMessage(
        id: botMessageId,
        chatId: chatId,
        type: type,
        text: text,
        actions: actions ?? [],
        metadata: metadata ?? {},
        isInteractive: actions != null && actions.isNotEmpty,
        createdAt: now,
        updatedAt: now,
      );

      // Save bot message to botMessages collection
      await _firestore
          .collection('botMessages')
          .doc(botMessageId)
          .set(botMessage.toMap());

      // Create regular message for chat
      final messageId = await _messageService.sendTextMessage(
        chatId: chatId,
        senderId: 'bot',
        text: text,
      );

      // Update message with bot metadata
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'type': MessageType.bot.toString().split('.').last,
        'metadata': {
          'botMessageId': botMessageId,
          'botMessageType': type.toString().split('.').last,
          'actions': actions?.map((action) => action.toMap()).toList() ?? [],
          'isInteractive': botMessage.isInteractive,
          ...metadata ?? {},
        },
        'updatedAt': Timestamp.fromDate(now),
      });

      debugPrint('Bot message sent: $botMessageId');
      return botMessageId;
    } catch (e) {
      debugPrint('Error sending bot message: $e');
      throw Exception('Ошибка отправки сообщения бота: $e');
    }
  }

  /// Handle user interaction with bot
  Future<void> handleBotInteraction({
    required String chatId,
    required String userId,
    required String actionId,
    required String payload,
  }) async {
    try {
      // Log interaction
      await _firestore.collection('botInteractions').add({
        'chatId': chatId,
        'userId': userId,
        'actionId': actionId,
        'payload': payload,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });

      // Handle different payloads
      switch (payload) {
        case 'find_specialists':
          await _handleFindSpecialists(chatId);
          break;
        case 'faq':
          await _handleFAQ(chatId);
          break;
        case 'support':
          await _handleSupport(chatId);
          break;
        case 'booking_help':
          await _handleBookingHelp(chatId);
          break;
        case 'faq_1':
          await _handleFAQ1(chatId);
          break;
        case 'faq_2':
          await _handleFAQ2(chatId);
          break;
        case 'faq_3':
          await _handleFAQ3(chatId);
          break;
        case 'faq_4':
          await _handleFAQ4(chatId);
          break;
        case 'faq_5':
          await _handleFAQ5(chatId);
          break;
        case 'support_technical':
          await _handleSupportTechnical(chatId);
          break;
        case 'support_payment':
          await _handleSupportPayment(chatId);
          break;
        case 'support_booking':
          await _handleSupportBooking(chatId);
          break;
        case 'support_other':
          await _handleSupportOther(chatId);
          break;
        default:
          await _handleUnknownPayload(chatId, payload);
      }
    } catch (e) {
      debugPrint('Error handling bot interaction: $e');
    }
  }

  /// Send welcome message to new user
  Future<void> sendWelcomeMessage(String chatId) async {
    try {
      final welcomeMessage = BotMessageTemplates.welcomeMessage(chatId);
      await sendBotMessage(
        chatId: chatId,
        type: welcomeMessage.type,
        text: welcomeMessage.text,
        actions: welcomeMessage.actions,
      );
    } catch (e) {
      debugPrint('Error sending welcome message: $e');
    }
  }

  /// Send FAQ message
  Future<void> sendFAQMessage(String chatId) async {
    try {
      final faqMessage = BotMessageTemplates.faqMessage(chatId);
      await sendBotMessage(
        chatId: chatId,
        type: faqMessage.type,
        text: faqMessage.text,
        actions: faqMessage.actions,
      );
    } catch (e) {
      debugPrint('Error sending FAQ message: $e');
    }
  }

  /// Send support message
  Future<void> sendSupportMessage(String chatId) async {
    try {
      final supportMessage = BotMessageTemplates.supportMessage(chatId);
      await sendBotMessage(
        chatId: chatId,
        type: supportMessage.type,
        text: supportMessage.text,
        actions: supportMessage.actions,
      );
    } catch (e) {
      debugPrint('Error sending support message: $e');
    }
  }

  /// Handle find specialists request
  Future<void> _handleFindSpecialists(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.help,
      text: '🔍 Поиск специалистов\n\n'
          'Для поиска специалистов:\n'
          '1. Перейдите в раздел "Поиск"\n'
          '2. Выберите категорию услуг\n'
          '3. Укажите ваш город\n'
          '4. Примените фильтры (цена, рейтинг, дата)\n'
          '5. Просмотрите профили специалистов\n\n'
          'Нужна помощь с поиском?',
      actions: [
        BotAction(
          id: 'search_help',
          title: 'Помощь с поиском',
          payload: 'search_help',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_main',
          title: 'Назад в главное меню',
          payload: 'back_to_main',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle FAQ request
  Future<void> _handleFAQ(String chatId) async {
    await sendFAQMessage(chatId);
  }

  /// Handle support request
  Future<void> _handleSupport(String chatId) async {
    await sendSupportMessage(chatId);
  }

  /// Handle booking help request
  Future<void> _handleBookingHelp(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.help,
      text: '📅 Помощь с бронированием\n\n'
          'Процесс бронирования:\n'
          '1. Выберите специалиста\n'
          '2. Укажите дату и время\n'
          '3. Опишите детали мероприятия\n'
          '4. Подтвердите бронирование\n'
          '5. Внесите предоплату (30%)\n'
          '6. Получите подтверждение\n\n'
          'Остались вопросы?',
      actions: [
        BotAction(
          id: 'booking_details',
          title: 'Детали бронирования',
          payload: 'booking_details',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'payment_help',
          title: 'Помощь с оплатой',
          payload: 'payment_help',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_main',
          title: 'Назад в главное меню',
          payload: 'back_to_main',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle FAQ 1 - Search specialists
  Future<void> _handleFAQ1(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.faq,
      text: '1️⃣ Как найти специалиста?\n\n'
          '• Используйте поиск по категориям\n'
          '• Фильтруйте по цене и рейтингу\n'
          '• Читайте отзывы клиентов\n'
          '• Проверяйте портфолио\n'
          '• Связывайтесь напрямую\n\n'
          'Нужна помощь с поиском?',
      actions: [
        BotAction(
          id: 'search_tips',
          title: 'Советы по поиску',
          payload: 'search_tips',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_faq',
          title: 'Назад к FAQ',
          payload: 'faq',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle FAQ 2 - Booking
  Future<void> _handleFAQ2(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.faq,
      text: '2️⃣ Как забронировать услугу?\n\n'
          '• Выберите специалиста\n'
          '• Укажите дату и время\n'
          '• Опишите детали\n'
          '• Внесите предоплату\n'
          '• Получите подтверждение\n\n'
          'Нужна помощь с бронированием?',
      actions: [
        BotAction(
          id: 'booking_process',
          title: 'Процесс бронирования',
          payload: 'booking_process',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_faq',
          title: 'Назад к FAQ',
          payload: 'faq',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle FAQ 3 - Cancel booking
  Future<void> _handleFAQ3(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.faq,
      text: '3️⃣ Как отменить бронирование?\n\n'
          '• Отмена возможна за 24 часа\n'
          '• Предоплата возвращается\n'
          '• Уведомите специалиста\n'
          '• Обратитесь в поддержку\n\n'
          'Нужна помощь с отменой?',
      actions: [
        BotAction(
          id: 'cancel_help',
          title: 'Помощь с отменой',
          payload: 'cancel_help',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_faq',
          title: 'Назад к FAQ',
          payload: 'faq',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle FAQ 4 - Support
  Future<void> _handleFAQ4(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.faq,
      text: '4️⃣ Как связаться с поддержкой?\n\n'
          '• Чат с ботом (24/7)\n'
          '• Email: support@eventmarketplace.ru\n'
          '• Телефон: +7 (800) 123-45-67\n'
          '• Время работы: 9:00 - 21:00\n\n'
          'Нужна помощь?',
      actions: [
        BotAction(
          id: 'contact_support',
          title: 'Связаться с поддержкой',
          payload: 'support',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_faq',
          title: 'Назад к FAQ',
          payload: 'faq',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle FAQ 5 - Reviews
  Future<void> _handleFAQ5(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.faq,
      text: '5️⃣ Как оставить отзыв?\n\n'
          '• После завершения услуги\n'
          '• Оцените по 5-балльной шкале\n'
          '• Напишите комментарий\n'
          '• Добавьте фотографии\n'
          '• Помогите другим клиентам\n\n'
          'Нужна помощь с отзывами?',
      actions: [
        BotAction(
          id: 'review_help',
          title: 'Помощь с отзывами',
          payload: 'review_help',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_faq',
          title: 'Назад к FAQ',
          payload: 'faq',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle support technical
  Future<void> _handleSupportTechnical(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.support,
      text: '🔧 Техническая проблема\n\n'
          'Опишите проблему:\n'
          '• Что не работает?\n'
          '• На каком устройстве?\n'
          '• Когда возникла проблема?\n'
          '• Есть ли сообщения об ошибках?\n\n'
          'Мы поможем решить проблему!',
      actions: [
        BotAction(
          id: 'escalate_technical',
          title: 'Передать в техподдержку',
          payload: 'escalate_technical',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_support',
          title: 'Назад к поддержке',
          payload: 'support',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle support payment
  Future<void> _handleSupportPayment(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.support,
      text: '💳 Проблема с оплатой\n\n'
          'Опишите проблему:\n'
          '• Не прошла оплата?\n'
          '• Неверная сумма?\n'
          '• Проблема с возвратом?\n'
          '• Другая проблема?\n\n'
          'Мы поможем с оплатой!',
      actions: [
        BotAction(
          id: 'escalate_payment',
          title: 'Передать в поддержку',
          payload: 'escalate_payment',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_support',
          title: 'Назад к поддержке',
          payload: 'support',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle support booking
  Future<void> _handleSupportBooking(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.support,
      text: '📅 Проблема с бронированием\n\n'
          'Опишите проблему:\n'
          '• Не удается забронировать?\n'
          '• Неверная дата/время?\n'
          '• Проблема с отменой?\n'
          '• Другая проблема?\n\n'
          'Мы поможем с бронированием!',
      actions: [
        BotAction(
          id: 'escalate_booking',
          title: 'Передать в поддержку',
          payload: 'escalate_booking',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_support',
          title: 'Назад к поддержке',
          payload: 'support',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle support other
  Future<void> _handleSupportOther(String chatId) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.support,
      text: '❓ Другая проблема\n\n'
          'Опишите вашу проблему:\n'
          '• Что случилось?\n'
          '• Когда это произошло?\n'
          '• Что вы ожидали?\n'
          '• Дополнительные детали?\n\n'
          'Мы поможем решить проблему!',
      actions: [
        BotAction(
          id: 'escalate_other',
          title: 'Передать в поддержку',
          payload: 'escalate_other',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'back_to_support',
          title: 'Назад к поддержке',
          payload: 'support',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Handle unknown payload
  Future<void> _handleUnknownPayload(String chatId, String payload) async {
    await sendBotMessage(
      chatId: chatId,
      type: BotMessageType.help,
      text: 'Извините, я не понял ваш запрос.\n\n'
          'Попробуйте выбрать один из вариантов ниже:',
      actions: [
        BotAction(
          id: 'back_to_main',
          title: 'Главное меню',
          payload: 'back_to_main',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'faq',
          title: 'FAQ',
          payload: 'faq',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'support',
          title: 'Поддержка',
          payload: 'support',
          type: BotActionType.quickReply,
        ),
      ],
    );
  }

  /// Get bot message by ID
  Future<BotMessage?> getBotMessage(String botMessageId) async {
    try {
      final doc = await _firestore.collection('botMessages').doc(botMessageId).get();
      if (!doc.exists) return null;
      return BotMessage.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting bot message: $e');
      return null;
    }
  }

  /// Get bot interactions for analytics
  Future<List<Map<String, dynamic>>> getBotInteractions({
    String? chatId,
    String? userId,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('botInteractions');
      
      if (chatId != null) {
        query = query.where('chatId', isEqualTo: chatId);
      }
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      query = query.orderBy('timestamp', descending: true).limit(limit);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting bot interactions: $e');
      return [];
    }
  }
}
