import 'dart:async';
import 'package:flutter/material.dart';
import '../models/smart_specialist.dart';
import '../models/specialist.dart';
import 'smart_search_service.dart';

/// Сервис AI-помощника для подбора специалистов
class AIAssistantService {
  factory AIAssistantService() => _instance;
  AIAssistantService._internal();
  static final AIAssistantService _instance = AIAssistantService._internal();

  final SmartSearchService _smartSearchService = SmartSearchService();
  final List<AIConversation> _conversations = [];
  final Map<String, List<AIMessage>> _conversationHistory = {};

  /// Начать новую беседу с AI-помощником
  Future<AIConversation> startConversation({String? userId}) async {
    final conversation = AIConversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      messages: [],
      context: {},
      createdAt: DateTime.now(),
    );

    _conversations.add(conversation);

    // Добавляем приветственное сообщение
    final welcomeMessage = AIMessage(
      id: 'welcome_${conversation.id}',
      text:
          'Привет! Я помогу вам найти идеального специалиста для вашего мероприятия. Расскажите, что вы планируете?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );

    conversation.messages.add(welcomeMessage);
    _conversationHistory[conversation.id] = [welcomeMessage];

    return conversation;
  }

  /// Отправить сообщение AI-помощнику
  Future<AIMessage> sendMessage({
    required String conversationId,
    required String message,
    String? userId,
  }) async {
    final conversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );

    // Создаем сообщение пользователя
    final userMessage = AIMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: message,
      isFromUser: true,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );

    conversation.messages.add(userMessage);
    _conversationHistory[conversationId]?.add(userMessage);

    // Обрабатываем сообщение и генерируем ответ
    final aiResponse = await _processUserMessage(conversation, message, userId);

    conversation.messages.add(aiResponse);
    _conversationHistory[conversationId]?.add(aiResponse);

    return aiResponse;
  }

  /// Обработать сообщение пользователя
  Future<AIMessage> _processUserMessage(
    AIConversation conversation,
    String message,
    String? userId,
  ) async {
    final messageLower = message.toLowerCase();

    // Анализируем сообщение и обновляем контекст
    _updateConversationContext(conversation, message);

    // Определяем тип ответа
    if (_isGreeting(messageLower)) {
      return _generateGreetingResponse(conversation);
    } else if (_isAskingForHelp(messageLower)) {
      return _generateHelpResponse(conversation);
    } else if (_isProvidingEventInfo(messageLower)) {
      return _generateEventInfoResponse(conversation);
    } else if (_isProvidingBudget(messageLower)) {
      return _generateBudgetResponse(conversation);
    } else if (_isProvidingDate(messageLower)) {
      return _generateDateResponse(conversation);
    } else if (_isProvidingLocation(messageLower)) {
      return _generateLocationResponse(conversation);
    } else if (_isAskingForRecommendations(messageLower)) {
      return _generateRecommendationsResponse(conversation, userId);
    } else if (_isAskingForMoreInfo(messageLower)) {
      return _generateMoreInfoResponse(conversation);
    } else {
      return _generateDefaultResponse(conversation);
    }
  }

  /// Обновить контекст беседы
  void _updateConversationContext(AIConversation conversation, String message) {
    final messageLower = message.toLowerCase();

    // Извлекаем информацию о мероприятии
    if (_containsEventType(messageLower)) {
      final eventType = _extractEventType(messageLower);
      if (eventType != null) {
        conversation.context['eventType'] = eventType;
      }
    }

    // Извлекаем информацию о бюджете
    if (_containsBudget(messageLower)) {
      final budget = _extractBudget(messageLower);
      if (budget != null) {
        conversation.context['budget'] = budget;
      }
    }

    // Извлекаем информацию о дате
    if (_containsDate(messageLower)) {
      final date = _extractDate(messageLower);
      if (date != null) {
        conversation.context['eventDate'] = date;
      }
    }

    // Извлекаем информацию о локации
    if (_containsLocation(messageLower)) {
      final location = _extractLocation(messageLower);
      if (location != null) {
        conversation.context['location'] = location;
      }
    }

    // Извлекаем информацию о стиле
    if (_containsStyle(messageLower)) {
      final style = _extractStyle(messageLower);
      if (style != null) {
        conversation.context['style'] = style;
      }
    }
  }

  /// Проверить, является ли сообщение приветствием
  bool _isGreeting(String message) {
    final greetings = [
      'привет',
      'здравствуйте',
      'добрый день',
      'добрый вечер',
      'доброе утро'
    ];
    return greetings.any((greeting) => message.contains(greeting));
  }

  /// Проверить, просит ли пользователь помощи
  bool _isAskingForHelp(String message) {
    final helpWords = ['помощь', 'помоги', 'как', 'что', 'расскажи'];
    return helpWords.any((word) => message.contains(word));
  }

  /// Проверить, предоставляет ли пользователь информацию о мероприятии
  bool _isProvidingEventInfo(String message) {
    final eventWords = [
      'свадьба',
      'день рождения',
      'корпоратив',
      'юбилей',
      'вечеринка',
      'мероприятие'
    ];
    return eventWords.any((word) => message.contains(word));
  }

  /// Проверить, предоставляет ли пользователь информацию о бюджете
  bool _isProvidingBudget(String message) {
    final budgetWords = ['бюджет', 'стоимость', 'цена', 'рублей', 'руб', '₽'];
    return budgetWords.any((word) => message.contains(word));
  }

  /// Проверить, предоставляет ли пользователь информацию о дате
  bool _isProvidingDate(String message) {
    final dateWords = ['дата', 'число', 'месяц', 'год', 'день'];
    return dateWords.any((word) => message.contains(word));
  }

  /// Проверить, предоставляет ли пользователь информацию о локации
  bool _isProvidingLocation(String message) {
    final locationWords = ['город', 'место', 'адрес', 'локация'];
    return locationWords.any((word) => message.contains(word));
  }

  /// Проверить, просит ли пользователь рекомендации
  bool _isAskingForRecommendations(String message) {
    final recommendationWords = [
      'найди',
      'подбери',
      'рекомендуй',
      'покажи',
      'дай'
    ];
    return recommendationWords.any((word) => message.contains(word));
  }

  /// Проверить, просит ли пользователь дополнительную информацию
  bool _isAskingForMoreInfo(String message) {
    final infoWords = ['расскажи', 'подробнее', 'больше', 'еще'];
    return infoWords.any((word) => message.contains(word));
  }

  /// Содержит ли сообщение тип мероприятия
  bool _containsEventType(String message) {
    final eventTypes = [
      'свадьба',
      'день рождения',
      'корпоратив',
      'юбилей',
      'вечеринка',
      'фотосессия'
    ];
    return eventTypes.any((type) => message.contains(type));
  }

  /// Содержит ли сообщение информацию о бюджете
  bool _containsBudget(String message) {
    final budgetPattern = RegExp(r'\d+.*(?:руб|₽|тысяч|тыс)');
    return budgetPattern.hasMatch(message);
  }

  /// Содержит ли сообщение информацию о дате
  bool _containsDate(String message) {
    final datePattern = RegExp(r'\d{1,2}[./]\d{1,2}[./]\d{2,4}');
    return datePattern.hasMatch(message);
  }

  /// Содержит ли сообщение информацию о локации
  bool _containsLocation(String message) {
    final cities = [
      'москва',
      'санкт-петербург',
      'екатеринбург',
      'новосибирск',
      'казань',
      'нижний новгород'
    ];
    return cities.any((city) => message.contains(city));
  }

  /// Содержит ли сообщение информацию о стиле
  bool _containsStyle(String message) {
    final styles = [
      'классика',
      'современный',
      'юмор',
      'интерактив',
      'романтичный',
      'официальный'
    ];
    return styles.any((style) => message.contains(style));
  }

  /// Извлечь тип мероприятия
  String? _extractEventType(String message) {
    final eventTypes = {
      'свадьба': 'свадьба',
      'день рождения': 'день рождения',
      'корпоратив': 'корпоратив',
      'юбилей': 'юбилей',
      'вечеринка': 'вечеринка',
      'фотосессия': 'фотосессия',
    };

    for (final entry in eventTypes.entries) {
      if (message.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Извлечь бюджет
  double? _extractBudget(String message) {
    final budgetPattern = RegExp(r'(\d+).*(?:руб|₽|тысяч|тыс)');
    final match = budgetPattern.firstMatch(message);
    if (match != null) {
      var amount = double.tryParse(match.group(1) ?? '');
      if (amount != null) {
        // Если упоминаются тысячи, умножаем на 1000
        if (message.contains('тысяч') || message.contains('тыс')) {
          amount *= 1000;
        }
        return amount;
      }
    }
    return null;
  }

  /// Извлечь дату
  DateTime? _extractDate(String message) {
    final datePattern = RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{2,4})');
    final match = datePattern.firstMatch(message);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      final year = int.tryParse(match.group(3) ?? '');

      if (day != null && month != null && year != null) {
        final fullYear = year < 100 ? 2000 + year : year;
        return DateTime(fullYear, month, day);
      }
    }
    return null;
  }

  /// Извлечь локацию
  String? _extractLocation(String message) {
    final cities = [
      'москва',
      'санкт-петербург',
      'екатеринбург',
      'новосибирск',
      'казань',
      'нижний новгород'
    ];
    for (final city in cities) {
      if (message.contains(city)) {
        return city;
      }
    }
    return null;
  }

  /// Извлечь стиль
  String? _extractStyle(String message) {
    final styles = [
      'классика',
      'современный',
      'юмор',
      'интерактив',
      'романтичный',
      'официальный'
    ];
    for (final style in styles) {
      if (message.contains(style)) {
        return style;
      }
    }
    return null;
  }

  /// Сгенерировать ответ на приветствие
  AIMessage _generateGreetingResponse(AIConversation conversation) {
    final responses = [
      'Отлично! Давайте найдем идеального специалиста для вашего мероприятия. Какой тип события вы планируете?',
      'Приятно познакомиться! Расскажите, что у вас за мероприятие?',
      'Здравствуйте! Я помогу подобрать специалиста. Что вы организуете?',
    ];

    final response = responses[DateTime.now().millisecond % responses.length];

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: response,
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// Сгенерировать ответ с помощью
  AIMessage _generateHelpResponse(AIConversation conversation) => AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Я помогу вам найти специалиста! Расскажите мне:\n\n'
            '• Какой тип мероприятия вы планируете?\n'
            '• В каком городе?\n'
            '• На какую дату?\n'
            '• Какой у вас бюджет?\n'
            '• Какой стиль предпочитаете?\n\n'
            'Чем больше деталей, тем точнее подбор!',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );

  /// Сгенерировать ответ на информацию о мероприятии
  AIMessage _generateEventInfoResponse(AIConversation conversation) {
    final eventType = conversation.context['eventType'] as String?;

    if (eventType != null) {
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'Понятно, у вас $eventType! Отличный выбор. Теперь расскажите, в каком городе будет проходить мероприятие?',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text:
          'Интересно! А какой это будет тип мероприятия? Свадьба, день рождения, корпоратив?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// Сгенерировать ответ на информацию о бюджете
  AIMessage _generateBudgetResponse(AIConversation conversation) {
    final budget = conversation.context['budget'] as double?;

    if (budget != null) {
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'Отлично, бюджет ${budget.toStringAsFixed(0)} ₽. Теперь скажите, на какую дату планируете мероприятие?',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Хорошо! А какой у вас примерный бюджет на специалиста?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// Сгенерировать ответ на информацию о дате
  AIMessage _generateDateResponse(AIConversation conversation) {
    final date = conversation.context['eventDate'] as DateTime?;

    if (date != null) {
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'Понятно, ${date.day}.${date.month}.${date.year}. Теперь расскажите, какой стиль мероприятия вы предпочитаете? Классический, современный, с юмором?',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Хорошо! А на какую дату планируете мероприятие?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// Сгенерировать ответ на информацию о локации
  AIMessage _generateLocationResponse(AIConversation conversation) {
    final location = conversation.context['location'] as String?;

    if (location != null) {
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'Отлично, $location! Теперь скажите, какой у вас бюджет на специалиста?',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Хорошо! А в каком городе будет проходить мероприятие?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// Сгенерировать ответ с рекомендациями
  Future<AIMessage> _generateRecommendationsResponse(
    AIConversation conversation,
    String? userId,
  ) async {
    try {
      // Получаем контекст беседы
      final eventType = conversation.context['eventType'] as String?;
      final budget = conversation.context['budget'] as double?;
      final date = conversation.context['eventDate'] as DateTime?;
      final location = conversation.context['location'] as String?;
      final style = conversation.context['style'] as String?;

      // Определяем категорию специалиста на основе типа мероприятия
      SpecialistCategory? category;
      if (eventType != null) {
        switch (eventType) {
          case 'свадьба':
            category = SpecialistCategory.host;
            break;
          case 'день рождения':
            category = SpecialistCategory.host;
            break;
          case 'корпоратив':
            category = SpecialistCategory.host;
            break;
          case 'фотосессия':
            category = SpecialistCategory.photographer;
            break;
          default:
            category = SpecialistCategory.host;
        }
      }

      // Ищем специалистов
      final specialists = await _smartSearchService.smartSearch(
        category: category,
        city: location,
        minPrice: budget != null ? budget * 0.8 : null,
        maxPrice: budget != null ? budget * 1.2 : null,
        eventDate: date,
        styles: style != null ? [style] : null,
        userId: userId,
      );

      if (specialists.isNotEmpty) {
        final topSpecialists = specialists.take(3).toList();

        final responseText =
            'Отлично! Я нашел для вас ${specialists.length} подходящих специалистов. Вот топ-3:\n\n${topSpecialists.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final specialist = entry.value;
          return '$index. ${specialist.name} - ${specialist.category.displayName}\n'
              '   ⭐ Рейтинг: ${specialist.rating.toStringAsFixed(1)}\n'
              '   💰 Цена: ${specialist.priceRangeString}\n'
              '   📍 Город: ${specialist.city ?? 'Не указан'}\n'
              '   🎯 Совместимость: ${(specialist.compatibilityScore * 100).toStringAsFixed(0)}%';
        }).join('\n\n')}\n\nХотите посмотреть подробнее или найти других специалистов?';

        return AIMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: responseText,
          isFromUser: false,
          timestamp: DateTime.now(),
          messageType: AIMessageType.recommendations,
          recommendations: topSpecialists,
        );
      } else {
        return AIMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text:
              'К сожалению, по вашим критериям не найдено подходящих специалистов. Попробуйте изменить параметры поиска или расскажите больше о ваших предпочтениях.',
          isFromUser: false,
          timestamp: DateTime.now(),
          messageType: AIMessageType.text,
        );
      }
    } on Exception catch (e) {
      debugPrint('Ошибка генерации рекомендаций: $e');
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Произошла ошибка при поиске специалистов. Попробуйте еще раз.',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }
  }

  /// Сгенерировать ответ с дополнительной информацией
  AIMessage _generateMoreInfoResponse(AIConversation conversation) => AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'Конечно! Расскажите подробнее о вашем мероприятии. Чем больше деталей, тем точнее я смогу подобрать специалиста.',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );

  /// Сгенерировать ответ по умолчанию
  AIMessage _generateDefaultResponse(AIConversation conversation) {
    final responses = [
      'Понятно! Расскажите еще что-нибудь о вашем мероприятии.',
      'Интересно! А что еще вы можете рассказать?',
      'Хорошо! Давайте продолжим. Что еще важно учесть?',
    ];

    final response = responses[DateTime.now().millisecond % responses.length];

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: response,
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// Получить беседу по ID
  AIConversation? getConversation(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } on Exception {
      return null;
    }
  }

  /// Получить историю сообщений
  List<AIMessage> getConversationHistory(String conversationId) =>
      _conversationHistory[conversationId] ?? [];

  /// Очистить историю беседы
  void clearConversationHistory(String conversationId) {
    _conversationHistory.remove(conversationId);
    _conversations.removeWhere((c) => c.id == conversationId);
  }
}

/// Модель беседы с AI-помощником
class AIConversation {
  const AIConversation({
    required this.id,
    this.userId,
    required this.messages,
    required this.context,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final List<AIMessage> messages;
  final Map<String, dynamic> context;
  final DateTime createdAt;
}

/// Модель сообщения AI-помощника
class AIMessage {
  const AIMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    required this.messageType,
    this.recommendations,
    this.metadata,
  });

  final String id;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final AIMessageType messageType;
  final List<SmartSpecialist>? recommendations;
  final Map<String, dynamic>? metadata;
}

/// Типы сообщений AI-помощника
enum AIMessageType {
  text,
  recommendations,
  options,
  error,
}
