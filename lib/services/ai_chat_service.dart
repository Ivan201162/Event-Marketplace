import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/ai_chat.dart';
import '../services/specialist_service.dart';

/// Сервис для работы с AI-чатом
class AiChatService {
  static const String _sessionsCollection = 'aiChatSessions';
  static const String _messagesCollection = 'aiChatMessages';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SpecialistService _specialistService = SpecialistService();

  /// Создать новую сессию чата
  Future<String?> createChatSession(String userId) async {
    try {
      final session = ChatSession(
        id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'Новый чат',
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        messageIds: [],
        context: const UserContext().toJson(),
      );

      await _firestore.collection(_sessionsCollection).doc(session.id).set(session.toFirestore());

      return session.id;
    } on Exception catch (e) {
      debugPrint('Ошибка создания сессии чата: $e');
      return null;
    }
  }

  /// Получить сессии пользователя
  Future<List<ChatSession>> getUserSessions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('lastMessageAt', descending: true)
          .get();

      return querySnapshot.docs.map(ChatSession.fromFirestore).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения сессий: $e');
      return [];
    }
  }

  /// Получить сообщения сессии
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp')
          .get();

      return querySnapshot.docs.map(ChatMessage.fromFirestore).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения сообщений: $e');
      return [];
    }
  }

  /// Отправить сообщение пользователя
  Future<ChatMessage?> sendUserMessage(
    String sessionId,
    String userId,
    String content,
  ) async {
    try {
      final message = ChatMessage(
        id: '${sessionId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
        messageType: MessageType.text.value,
      );

      await _firestore.collection(_messagesCollection).doc(message.id).set({
        ...message.toFirestore(),
        'sessionId': sessionId,
      });

      // Обновить время последнего сообщения в сессии
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'lastMessageAt': Timestamp.now(),
      });

      return message;
    } on Exception catch (e) {
      debugPrint('Ошибка отправки сообщения: $e');
      return null;
    }
  }

  /// Получить ответ от AI
  Future<ChatMessage?> getAiResponse(
    String sessionId,
    String userId,
    String userMessage,
  ) async {
    try {
      // Получаем контекст сессии
      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();

      if (!sessionDoc.exists) {
        return null;
      }

      final session = ChatSession.fromFirestore(sessionDoc);
      final context = UserContext.fromJson(session.context ?? {});

      // Обрабатываем сообщение пользователя
      final response = await _processUserMessage(userMessage, context);

      // Создаем ответное сообщение
      final aiMessage = ChatMessage(
        id: '${sessionId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        content: response['content'],
        isUser: false,
        timestamp: DateTime.now(),
        messageType: response['type'],
        metadata: response['metadata'],
      );

      await _firestore.collection(_messagesCollection).doc(aiMessage.id).set({
        ...aiMessage.toFirestore(),
        'sessionId': sessionId,
      });

      // Обновляем контекст сессии
      await _updateSessionContext(sessionId, response['newContext']);

      return aiMessage;
    } on Exception catch (e) {
      debugPrint('Ошибка получения ответа AI: $e');
      return null;
    }
  }

  /// Обработка сообщения пользователя
  Future<Map<String, dynamic>> _processUserMessage(
    String message,
    UserContext context,
  ) async {
    final lowerMessage = message.toLowerCase();

    // Приветствие
    if (_isGreeting(lowerMessage)) {
      return {
        'content':
            'Привет! Я AI-помощник Event Marketplace. Помогу подобрать специалистов для вашего мероприятия. Расскажите, какое событие планируете?',
        'type': MessageType.greeting.value,
        'metadata': {
          'quickReplies': [
            const QuickReply(
              text: 'Свадьба',
              value: 'wedding',
              icon: Icons.favorite,
            ).toJson(),
            const QuickReply(
              text: 'Корпоратив',
              value: 'corporate',
              icon: Icons.business,
            ).toJson(),
            const QuickReply(
              text: 'День рождения',
              value: 'birthday',
              icon: Icons.cake,
            ).toJson(),
            const QuickReply(text: 'Другое', value: 'other', icon: Icons.event).toJson(),
          ],
        },
        'newContext': context,
      };
    }

    // Определение типа события
    if (_isEventType(lowerMessage)) {
      final eventType = _extractEventType(lowerMessage);
      final newContext = context.copyWith(eventType: eventType);

      return {
        'content':
            'Отлично! ${_getEventTypeDescription(eventType)} В каком городе планируется мероприятие?',
        'type': MessageType.question.value,
        'metadata': {
          'quickReplies': [
            const QuickReply(text: 'Москва', value: 'moscow').toJson(),
            const QuickReply(text: 'Санкт-Петербург', value: 'spb').toJson(),
            const QuickReply(text: 'Другой город', value: 'other_city').toJson(),
          ],
        },
        'newContext': newContext,
      };
    }

    // Определение города
    if (_isCity(lowerMessage)) {
      final city = _extractCity(lowerMessage);
      final newContext = context.copyWith(city: city);

      return {
        'content': 'Понятно, мероприятие в $city. Когда планируется событие?',
        'type': MessageType.question.value,
        'metadata': {
          'quickReplies': [
            const QuickReply(text: 'В этом месяце', value: 'this_month').toJson(),
            const QuickReply(text: 'В следующем месяце', value: 'next_month').toJson(),
            const QuickReply(text: 'Через 3+ месяцев', value: 'later').toJson(),
          ],
        },
        'newContext': newContext,
      };
    }

    // Определение бюджета
    if (_isBudget(lowerMessage)) {
      final budget = _extractBudget(lowerMessage);
      final newContext = context.copyWith(budget: budget);

      return {
        'content': 'Бюджет $budget ₽ учтен. Теперь подберу подходящих специалистов...',
        'type': MessageType.text.value,
        'metadata': {},
        'newContext': newContext,
      };
    }

    // Поиск специалистов
    if (_isSearchRequest(lowerMessage) || context.eventType != null) {
      return _searchSpecialists(context);
    }

    // Общие вопросы
    if (_isGeneralQuestion(lowerMessage)) {
      return {
        'content': _getGeneralAnswer(lowerMessage),
        'type': MessageType.text.value,
        'metadata': {},
        'newContext': context,
      };
    }

    // Непонятное сообщение
    return {
      'content':
          'Извините, не совсем понял. Можете уточнить? Я помогу подобрать специалистов для вашего мероприятия.',
      'type': MessageType.question.value,
      'metadata': {
        'quickReplies': [
          const QuickReply(text: 'Подобрать специалистов', value: 'search').toJson(),
          const QuickReply(text: 'Помощь', value: 'help').toJson(),
        ],
      },
      'newContext': context,
    };
  }

  /// Поиск специалистов на основе контекста
  Future<Map<String, dynamic>> _searchSpecialists(UserContext context) async {
    try {
      final specialists = await _specialistService.getAllSpecialists();

      // Фильтруем специалистов по контексту
      final filteredSpecialists = specialists.where((specialist) {
        var matches = true;

        if (context.city != null && specialist.city != context.city) {
          matches = false;
        }

        if (context.budget != null && specialist.price > context.budget!) {
          matches = false;
        }

        if (context.eventType != null) {
          // Простая логика сопоставления типа события и категории специалиста
          final eventType = context.eventType!;
          final category = specialist.category.name;

          if (eventType == 'wedding' &&
              !['photographer', 'videographer', 'host', 'dj'].contains(category)) {
            matches = false;
          } else if (eventType == 'corporate' && !['host', 'dj', 'caterer'].contains(category)) {
            matches = false;
          } else if (eventType == 'birthday' &&
              !['photographer', 'host', 'dj'].contains(category)) {
            matches = false;
          }
        }

        return matches;
      }).toList();

      // Сортируем по рейтингу
      filteredSpecialists.sort((a, b) => b.rating.compareTo(a.rating));

      // Берем топ-3
      final topSpecialists = filteredSpecialists.take(3).toList();

      if (topSpecialists.isEmpty) {
        return {
          'content':
              'К сожалению, не нашел подходящих специалистов по вашим критериям. Попробуйте изменить параметры поиска.',
          'type': MessageType.text.value,
          'metadata': {
            'quickReplies': [
              const QuickReply(
                text: 'Изменить критерии',
                value: 'change_criteria',
              ).toJson(),
              const QuickReply(text: 'Показать всех', value: 'show_all').toJson(),
            ],
          },
          'newContext': context,
        };
      }

      return {
        'content': 'Нашел ${topSpecialists.length} подходящих специалистов:',
        'type': MessageType.specialistCard.value,
        'metadata': {
          'specialists': topSpecialists
              .map(
                (s) => {
                  'id': s.id,
                  'name': s.name,
                  'category': s.category.displayName,
                  'rating': s.rating,
                  'price': s.price,
                  'city': s.city,
                  'photoUrl': s.photoUrl,
                },
              )
              .toList(),
          'quickReplies': [
            const QuickReply(text: 'Показать больше', value: 'show_more').toJson(),
            const QuickReply(text: 'Новый поиск', value: 'new_search').toJson(),
          ],
        },
        'newContext': context,
      };
    } on Exception catch (e) {
      debugPrint('Ошибка поиска специалистов: $e');
      return {
        'content': 'Произошла ошибка при поиске специалистов. Попробуйте позже.',
        'type': MessageType.text.value,
        'metadata': {},
        'newContext': context,
      };
    }
  }

  /// Обновить контекст сессии
  Future<void> _updateSessionContext(
    String sessionId,
    UserContext? newContext,
  ) async {
    if (newContext == null) return;

    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'context': newContext.toJson(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления контекста: $e');
    }
  }

  // Вспомогательные методы для анализа сообщений

  bool _isGreeting(String message) {
    final greetings = [
      'привет',
      'здравствуйте',
      'добрый день',
      'добрый вечер',
      'доброе утро',
      'hi',
      'hello',
    ];
    return greetings.any((greeting) => message.contains(greeting));
  }

  bool _isEventType(String message) {
    final eventTypes = [
      'свадьба',
      'корпоратив',
      'день рождения',
      'юбилей',
      'праздник',
      'мероприятие',
    ];
    return eventTypes.any((type) => message.contains(type));
  }

  String _extractEventType(String message) {
    if (message.contains('свадьб')) return 'wedding';
    if (message.contains('корпоратив')) return 'corporate';
    if (message.contains('день рождения') || message.contains('др')) {
      return 'birthday';
    }
    if (message.contains('юбилей')) return 'anniversary';
    return 'other';
  }

  String _getEventTypeDescription(String eventType) {
    switch (eventType) {
      case 'wedding':
        return 'Свадьба - это особенный день!';
      case 'corporate':
        return 'Корпоративное мероприятие - отличный выбор!';
      case 'birthday':
        return 'День рождения - замечательный повод для праздника!';
      case 'anniversary':
        return 'Юбилей - важное событие!';
      default:
        return 'Интересное мероприятие!';
    }
  }

  bool _isCity(String message) {
    final cities = [
      'москва',
      'санкт-петербург',
      'спб',
      'екатеринбург',
      'новосибирск',
    ];
    return cities.any((city) => message.contains(city));
  }

  String _extractCity(String message) {
    if (message.contains('москв')) return 'Москва';
    if (message.contains('санкт-петербург') || message.contains('спб')) {
      return 'Санкт-Петербург';
    }
    if (message.contains('екатеринбург')) return 'Екатеринбург';
    if (message.contains('новосибирск')) return 'Новосибирск';
    return 'Другой город';
  }

  bool _isBudget(String message) =>
      message.contains('бюджет') ||
      message.contains('₽') ||
      message.contains('руб') ||
      RegExp(r'\d+').hasMatch(message);

  int _extractBudget(String message) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 50000; // Дефолтный бюджет
  }

  bool _isSearchRequest(String message) {
    final searchWords = ['найти', 'подобрать', 'поиск', 'специалист', 'помощь'];
    return searchWords.any((word) => message.contains(word));
  }

  bool _isGeneralQuestion(String message) {
    final questions = ['что', 'как', 'где', 'когда', 'почему', 'зачем'];
    return questions.any((question) => message.contains(question));
  }

  String _getGeneralAnswer(String message) {
    if (message.contains('что такое') || message.contains('что это')) {
      return 'Event Marketplace - это платформа для поиска и бронирования специалистов для мероприятий. Я помогу найти фотографов, ведущих, DJ, декораторов и других профессионалов.';
    }
    if (message.contains('как работает') || message.contains('как пользоваться')) {
      return 'Просто расскажите мне о вашем мероприятии: тип события, город, дату и бюджет. Я подберу подходящих специалистов и помогу с бронированием.';
    }
    if (message.contains('сколько стоит') || message.contains('цена')) {
      return 'Цены зависят от типа услуги и специалиста. Обычно фотографы стоят от 15 000 ₽, ведущие от 20 000 ₽, DJ от 10 000 ₽. Расскажите о вашем бюджете, и я подберу оптимальные варианты.';
    }
    return 'Я готов помочь с организацией вашего мероприятия! Расскажите подробнее о том, что планируете.';
  }
}
