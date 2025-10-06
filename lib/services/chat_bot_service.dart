import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logger.dart';
import '../models/chat_bot.dart';

/// Сервис для работы с бот-помощником в чатах
class ChatBotService {
  factory ChatBotService() => _instance;
  ChatBotService._internal();
  static final ChatBotService _instance = ChatBotService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Обработать сообщение пользователя
  Future<ChatBotMessage?> processUserMessage({
    required String chatId,
    required String userId,
    required String message,
  }) async {
    try {
      AppLogger.logI(
        'Обработка сообщения пользователя: $message',
        'chat_bot_service',
      );

      // Получаем или создаем контекст разговора
      final conversation = await _getOrCreateConversation(chatId, userId);

      // Анализируем сообщение и определяем намерение
      final intent = _analyzeIntent(message);

      // Генерируем ответ на основе намерения и контекста
      final response = await _generateResponse(intent, conversation, message);

      if (response != null) {
        // Сохраняем ответ бота
        await _saveBotMessage(response);

        // Обновляем контекст разговора
        await _updateConversationContext(conversation.id, intent, message);
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка обработки сообщения пользователя',
        'chat_bot_service',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Получить приветственное сообщение
  Future<ChatBotMessage> getWelcomeMessage(String chatId) async {
    final messageId = 'bot_${DateTime.now().millisecondsSinceEpoch}';

    return ChatBotMessage(
      id: messageId,
      chatId: chatId,
      message: 'Привет! Я бот-помощник Event Marketplace. Чем могу помочь?',
      type: BotMessageType.text,
      quickReplies: [
        BotQuickReply(
          title: 'Часто задаваемые вопросы',
          payload: 'faq',
          actionType: BotActionType.sendMessage,
        ),
        BotQuickReply(
          title: 'Техническая поддержка',
          payload: 'support',
          actionType: BotActionType.sendMessage,
        ),
        BotQuickReply(
          title: 'Связаться с оператором',
          payload: 'human',
          actionType: BotActionType.transferToHuman,
        ),
      ],
      createdAt: DateTime.now(),
      isFromBot: true,
    );
  }

  /// Анализировать намерение пользователя
  String _analyzeIntent(String message) {
    final lowerMessage = message.toLowerCase();

    // Ключевые слова для определения намерений
    if (lowerMessage.contains('помощь') || lowerMessage.contains('help')) {
      return 'help';
    } else if (lowerMessage.contains('вопрос') ||
        lowerMessage.contains('faq')) {
      return 'faq';
    } else if (lowerMessage.contains('проблема') ||
        lowerMessage.contains('ошибка') ||
        lowerMessage.contains('не работает')) {
      return 'problem';
    } else if (lowerMessage.contains('оператор') ||
        lowerMessage.contains('человек') ||
        lowerMessage.contains('поддержка')) {
      return 'human';
    } else if (lowerMessage.contains('бронирование') ||
        lowerMessage.contains('заказ')) {
      return 'booking';
    } else if (lowerMessage.contains('оплата') ||
        lowerMessage.contains('платеж')) {
      return 'payment';
    } else if (lowerMessage.contains('отмена') ||
        lowerMessage.contains('возврат')) {
      return 'cancellation';
    } else {
      return 'general';
    }
  }

  /// Генерировать ответ на основе намерения
  Future<ChatBotMessage?> _generateResponse(
    String intent,
    BotConversation conversation,
    String userMessage,
  ) async {
    final messageId = 'bot_${DateTime.now().millisecondsSinceEpoch}';

    switch (intent) {
      case 'help':
        return ChatBotMessage(
          id: messageId,
          chatId: conversation.chatId,
          message:
              'Я могу помочь вам с:\n\n• Часто задаваемыми вопросами\n• Техническими проблемами\n• Бронированием услуг\n• Оплатой\n• Связью с оператором',
          type: BotMessageType.text,
          quickReplies: [
            BotQuickReply(
              title: 'FAQ',
              payload: 'faq',
              actionType: BotActionType.sendMessage,
            ),
            BotQuickReply(
              title: 'Проблема',
              payload: 'problem',
              actionType: BotActionType.sendMessage,
            ),
            BotQuickReply(
              title: 'Оператор',
              payload: 'human',
              actionType: BotActionType.transferToHuman,
            ),
          ],
          createdAt: DateTime.now(),
          isFromBot: true,
        );

      case 'faq':
        return ChatBotMessage(
          id: messageId,
          chatId: conversation.chatId,
          message: 'Вот ответы на часто задаваемые вопросы:',
          type: BotMessageType.list,
          listItems: [
            BotListItem(
              title: 'Как забронировать услугу?',
              subtitle: 'Выберите специалиста и нажмите "Забронировать"',
              button: BotButton(
                title: 'Подробнее',
                actionType: BotActionType.sendMessage,
                actionData: {'message': 'Как забронировать услугу?'},
              ),
            ),
            BotListItem(
              title: 'Как отменить бронирование?',
              subtitle: 'Отмена возможна за 24 часа до мероприятия',
              button: BotButton(
                title: 'Подробнее',
                actionType: BotActionType.sendMessage,
                actionData: {'message': 'Как отменить бронирование?'},
              ),
            ),
            BotListItem(
              title: 'Способы оплаты',
              subtitle: 'Мы принимаем карты, электронные кошельки',
              button: BotButton(
                title: 'Подробнее',
                actionType: BotActionType.sendMessage,
                actionData: {'message': 'Способы оплаты'},
              ),
            ),
          ],
          createdAt: DateTime.now(),
          isFromBot: true,
        );

      case 'problem':
        return ChatBotMessage(
          id: messageId,
          chatId: conversation.chatId,
          message:
              'Расскажите подробнее о проблеме. Это поможет мне лучше понять ситуацию.',
          type: BotMessageType.text,
          quickReplies: [
            BotQuickReply(
              title: 'Не загружается страница',
              payload: 'page_load',
              actionType: BotActionType.sendMessage,
            ),
            BotQuickReply(
              title: 'Проблема с оплатой',
              payload: 'payment_issue',
              actionType: BotActionType.sendMessage,
            ),
            BotQuickReply(
              title: 'Не приходят уведомления',
              payload: 'notifications',
              actionType: BotActionType.sendMessage,
            ),
            BotQuickReply(
              title: 'Другая проблема',
              payload: 'other',
              actionType: BotActionType.sendMessage,
            ),
          ],
          createdAt: DateTime.now(),
          isFromBot: true,
        );

      case 'human':
        return ChatBotMessage(
          id: messageId,
          chatId: conversation.chatId,
          message:
              'Сейчас я передам вас оператору. Пожалуйста, опишите вашу проблему, и мы постараемся помочь как можно быстрее.',
          type: BotMessageType.text,
          metadata: {
            'transferToHuman': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
          createdAt: DateTime.now(),
          isFromBot: true,
        );

      default:
        return ChatBotMessage(
          id: messageId,
          chatId: conversation.chatId,
          message:
              'Извините, я не совсем понял ваш вопрос. Можете переформулировать или выбрать один из вариантов ниже?',
          type: BotMessageType.text,
          quickReplies: [
            BotQuickReply(
              title: 'Помощь',
              payload: 'help',
              actionType: BotActionType.sendMessage,
            ),
            BotQuickReply(
              title: 'FAQ',
              payload: 'faq',
              actionType: BotActionType.sendMessage,
            ),
            BotQuickReply(
              title: 'Оператор',
              payload: 'human',
              actionType: BotActionType.transferToHuman,
            ),
          ],
          createdAt: DateTime.now(),
          isFromBot: true,
        );
    }
  }

  /// Обработать быстрый ответ
  Future<ChatBotMessage?> _handleQuickReply(
    String payload,
    BotConversation conversation,
  ) async {
    // Обрабатываем различные типы быстрых ответов
    switch (payload) {
      case 'faq':
        return _generateResponse('faq', conversation, '');
      case 'support':
        return _generateResponse('problem', conversation, '');
      case 'human':
        return _generateResponse('human', conversation, '');
      default:
        return _generateResponse('general', conversation, payload);
    }
  }

  /// Получить или создать контекст разговора
  Future<BotConversation> _getOrCreateConversation(
    String chatId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('bot_conversations')
          .where('chatId', isEqualTo: chatId)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return BotConversation.fromMap(doc.data(), doc.id);
      } else {
        // Создаем новый контекст разговора
        final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
        final conversation = BotConversation(
          id: conversationId,
          chatId: chatId,
          userId: userId,
          context: {},
          currentStep: 'start',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );

        await _firestore
            .collection('bot_conversations')
            .doc(conversationId)
            .set(conversation.toMap());

        return conversation;
      }
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка получения контекста разговора',
        'chat_bot_service',
        e,
        stackTrace,
      );
      // Возвращаем базовый контекст в случае ошибки
      return BotConversation(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        userId: userId,
        context: {},
        currentStep: 'start',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
    }
  }

  /// Сохранить сообщение бота
  Future<void> _saveBotMessage(ChatBotMessage message) async {
    try {
      await _firestore
          .collection('chat_messages')
          .doc(message.id)
          .set(message.toMap());
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка сохранения сообщения бота',
        'chat_bot_service',
        e,
        stackTrace,
      );
    }
  }

  /// Обновить контекст разговора
  Future<void> _updateConversationContext(
    String conversationId,
    String intent,
    String userMessage,
  ) async {
    try {
      await _firestore
          .collection('bot_conversations')
          .doc(conversationId)
          .update({
        'context.lastIntent': intent,
        'context.lastMessage': userMessage,
        'context.messageCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка обновления контекста разговора',
        'chat_bot_service',
        e,
        stackTrace,
      );
    }
  }

  /// Завершить разговор с ботом
  Future<void> endConversation(String chatId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bot_conversations')
          .where('chatId', isEqualTo: chatId)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.update({
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      AppLogger.logI('Разговор с ботом завершен: $chatId', 'chat_bot_service');
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка завершения разговора с ботом',
        'chat_bot_service',
        e,
        stackTrace,
      );
    }
  }
}
