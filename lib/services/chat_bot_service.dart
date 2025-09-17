import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/support_ticket.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';

/// Сервис бота-помощника в чате поддержки
class ChatBotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Обработать сообщение пользователя и дать ответ
  Future<BotResponse> processUserMessage({
    required String userId,
    required String message,
    required String chatId,
  }) async {
    if (!FeatureFlags.chatBotEnabled) {
      return BotResponse(
        type: BotResponseType.text,
        content: 'Бот-помощник временно недоступен',
        suggestions: [],
      );
    }

    try {
      // Анализируем сообщение
      final analysis = _analyzeMessage(message);

      // Ищем подходящие FAQ
      final faqSuggestions = await _findRelevantFAQ(analysis.keywords);

      // Определяем тип ответа
      if (faqSuggestions.isNotEmpty) {
        return BotResponse(
          type: BotResponseType.faqSuggestions,
          content: 'Я нашел несколько статей, которые могут помочь:',
          suggestions: faqSuggestions,
          faqItems: faqSuggestions,
        );
      } else if (analysis.needsHumanSupport) {
        return BotResponse(
          type: BotResponseType.escalateToHuman,
          content:
              'Понимаю, что у вас сложная проблема. Сейчас передам ваш запрос специалисту поддержки.',
          suggestions: [
            'Дождаться ответа специалиста',
            'Оставить дополнительную информацию'
          ],
        );
      } else {
        return BotResponse(
          type: BotResponseType.text,
          content: _generateGenericResponse(analysis),
          suggestions: _getGenericSuggestions(),
        );
      }
    } catch (e) {
      return BotResponse(
        type: BotResponseType.text,
        content:
            'Извините, произошла ошибка. Попробуйте переформулировать вопрос.',
        suggestions: ['Повторить вопрос', 'Обратиться к специалисту'],
      );
    }
  }

  /// Анализировать сообщение пользователя
  MessageAnalysis _analyzeMessage(String message) {
    final lowerMessage = message.toLowerCase();
    final keywords = <String>[];
    bool needsHumanSupport = false;

    // Ключевые слова для разных категорий
    final categories = {
      'payment': [
        'оплата',
        'платеж',
        'деньги',
        'возврат',
        'списание',
        'карта',
        'банк'
      ],
      'booking': [
        'бронирование',
        'заявка',
        'отмена',
        'изменение',
        'дата',
        'время'
      ],
      'account': [
        'аккаунт',
        'профиль',
        'регистрация',
        'вход',
        'пароль',
        'email'
      ],
      'technical': [
        'ошибка',
        'не работает',
        'глюк',
        'баг',
        'зависает',
        'медленно'
      ],
      'refund': ['возврат', 'отмена', 'деньги назад', 'компенсация'],
      'urgent': ['срочно', 'сейчас', 'немедленно', 'критично', 'не могу'],
    };

    // Анализируем категории
    for (final entry in categories.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          keywords.add(entry.key);
          break;
        }
      }
    }

    // Определяем, нужна ли поддержка человека
    needsHumanSupport = keywords.contains('urgent') ||
        keywords.contains('refund') ||
        lowerMessage.contains('специалист') ||
        lowerMessage.contains('человек');

    return MessageAnalysis(
      keywords: keywords,
      needsHumanSupport: needsHumanSupport,
      sentiment: _analyzeSentiment(lowerMessage),
    );
  }

  /// Анализировать тональность сообщения
  Sentiment _analyzeSentiment(String message) {
    final positiveWords = [
      'спасибо',
      'хорошо',
      'отлично',
      'понятно',
      'помогло'
    ];
    final negativeWords = [
      'плохо',
      'ужасно',
      'не работает',
      'проблема',
      'ошибка',
      'злой'
    ];

    int positiveCount =
        positiveWords.where((word) => message.contains(word)).length;
    int negativeCount =
        negativeWords.where((word) => message.contains(word)).length;

    if (positiveCount > negativeCount) {
      return Sentiment.positive;
    } else if (negativeCount > positiveCount) {
      return Sentiment.negative;
    } else {
      return Sentiment.neutral;
    }
  }

  /// Найти релевантные FAQ
  Future<List<FAQItem>> _findRelevantFAQ(List<String> keywords) async {
    try {
      if (keywords.isEmpty) return [];

      final snapshot = await _firestore
          .collection('faq')
          .where('tags', arrayContainsAny: keywords)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) => FAQItem.fromDocument(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Сгенерировать общий ответ
  String _generateGenericResponse(MessageAnalysis analysis) {
    if (analysis.sentiment == Sentiment.negative) {
      return 'Понимаю, что у вас возникли трудности. Давайте разберемся с вашей проблемой. Можете описать подробнее, что именно не работает?';
    } else if (analysis.sentiment == Sentiment.positive) {
      return 'Рад, что смог помочь! Если у вас есть еще вопросы, не стесняйтесь спрашивать.';
    } else {
      return 'Я готов помочь вам с вашим вопросом. Можете описать проблему подробнее?';
    }
  }

  /// Получить общие предложения
  List<String> _getGenericSuggestions() {
    return [
      'Посмотреть FAQ',
      'Обратиться к специалисту',
      'Оставить отзыв',
    ];
  }

  /// Создать тикет поддержки
  Future<String> createSupportTicket({
    required String userId,
    required String description,
    required String chatId,
    List<String> keywords = const [],
  }) async {
    try {
      final ticket = SupportTicket(
        id: '',
        userId: userId,
        title: _generateTicketTitle(description),
        description: description,
        category: _determineCategory(keywords),
        priority: _determinePriority(description),
        status: SupportTicketStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assignedTo: null,
        chatId: chatId,
        tags: keywords,
      );

      final docRef =
          await _firestore.collection('support_tickets').add(ticket.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания тикета поддержки: $e');
    }
  }

  /// Сгенерировать заголовок тикета
  String _generateTicketTitle(String description) {
    final words = description.split(' ');
    if (words.length <= 5) {
      return description;
    } else {
      return '${words.take(5).join(' ')}...';
    }
  }

  /// Определить категорию тикета
  SupportCategory _determineCategory(List<String> keywords) {
    if (keywords.contains('payment')) return SupportCategory.payment;
    if (keywords.contains('booking')) return SupportCategory.booking;
    if (keywords.contains('account')) return SupportCategory.account;
    if (keywords.contains('technical')) return SupportCategory.technical;
    return SupportCategory.general;
  }

  /// Определить приоритет тикета
  SupportPriority _determinePriority(String description) {
    final lowerDescription = description.toLowerCase();
    if (lowerDescription.contains('срочно') ||
        lowerDescription.contains('критично')) {
      return SupportPriority.high;
    } else if (lowerDescription.contains('важно')) {
      return SupportPriority.medium;
    } else {
      return SupportPriority.low;
    }
  }

  /// Получить популярные вопросы
  Future<List<FAQItem>> getPopularQuestions() async {
    try {
      final snapshot = await _firestore
          .collection('faq')
          .orderBy('views', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) => FAQItem.fromDocument(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить приветственное сообщение
  BotResponse getWelcomeMessage() {
    return BotResponse(
      type: BotResponseType.text,
      content: 'Привет! Я бот-помощник службы поддержки. Чем могу помочь?',
      suggestions: [
        'Проблемы с оплатой',
        'Вопросы по бронированию',
        'Технические проблемы',
        'Общие вопросы',
      ],
    );
  }
}

/// Анализ сообщения пользователя
class MessageAnalysis {
  final List<String> keywords;
  final bool needsHumanSupport;
  final Sentiment sentiment;

  const MessageAnalysis({
    required this.keywords,
    required this.needsHumanSupport,
    required this.sentiment,
  });
}

/// Тональность сообщения
enum Sentiment {
  positive,
  negative,
  neutral,
}

/// Ответ бота
class BotResponse {
  final BotResponseType type;
  final String content;
  final List<String> suggestions;
  final List<FAQItem>? faqItems;
  final String? ticketId;

  const BotResponse({
    required this.type,
    required this.content,
    required this.suggestions,
    this.faqItems,
    this.ticketId,
  });
}

/// Типы ответов бота
enum BotResponseType {
  text,
  faqSuggestions,
  escalateToHuman,
  ticketCreated,
}
