import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_message.dart';
import '../models/specialist.dart';
import 'specialist_service.dart';

/// Сервис для AI-помощника
class AIAssistantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SpecialistService _specialistService = SpecialistService();

  /// Получить историю сообщений пользователя
  Stream<List<AIMessage>> getMessageHistory(String userId) => _db
      .collection('ai_chats')
      .doc(userId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(AIMessage.fromDocument).toList());

  /// Отправить сообщение пользователя и получить ответ AI
  Future<AIMessage> sendMessage(String userId, String message) async {
    try {
      // Сохраняем сообщение пользователя
      final userMessage = AIMessage(
        id: _generateMessageId(),
        type: AIMessageType.user,
        content: message,
        timestamp: DateTime.now(),
      );

      await _saveMessage(userId, userMessage);

      // Обрабатываем сообщение и генерируем ответ
      final aiResponse = await _processUserMessage(message);

      // Сохраняем ответ AI
      await _saveMessage(userId, aiResponse);

      return aiResponse;
    } catch (e) {
      print('Ошибка отправки сообщения: $e');
      // Возвращаем сообщение об ошибке
      return AIMessage(
        id: _generateMessageId(),
        type: AIMessageType.assistant,
        content: 'Извините, произошла ошибка. Попробуйте еще раз.',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Обработать сообщение пользователя и сгенерировать ответ
  Future<AIMessage> _processUserMessage(String message) async {
    final lowerMessage = message.toLowerCase();

    // Анализируем запрос пользователя
    final intent = _analyzeIntent(lowerMessage);

    switch (intent.type) {
      case AIIntentType.findSpecialist:
        return _handleFindSpecialistIntent(intent, message);
      case AIIntentType.budgetQuestion:
        return _handleBudgetQuestionIntent(intent, message);
      case AIIntentType.generalQuestion:
        return _handleGeneralQuestionIntent(message);
      case AIIntentType.greeting:
        return _handleGreetingIntent();
      default:
        return _handleUnknownIntent(message);
    }
  }

  /// Анализировать намерение пользователя
  AIIntent _analyzeIntent(String message) {
    // Ключевые слова для поиска специалистов
    final specialistKeywords = [
      'найди',
      'подбери',
      'нужен',
      'ищу',
      'хочу',
      'ведущий',
      'фотограф',
      'dj',
      'декоратор',
      'музыкант',
      'видеограф',
      'аниматор',
      'флорист',
      'свадьба',
      'день рождения',
      'корпоратив',
      'мероприятие',
    ];

    // Ключевые слова для вопросов о бюджете
    final budgetKeywords = [
      'бюджет',
      'стоимость',
      'цена',
      'сколько стоит',
      'дорого',
      'дешево',
      'расходы',
      'затраты',
      'потратить',
    ];

    // Ключевые слова для приветствий
    final greetingKeywords = [
      'привет',
      'здравствуй',
      'добро пожаловать',
      'помощь',
      'помоги',
    ];

    // Проверяем намерения
    if (specialistKeywords.any((keyword) => message.contains(keyword))) {
      return AIIntent(
        type: AIIntentType.findSpecialist,
        category: _extractCategory(message),
        location: _extractLocation(message),
        eventType: _extractEventType(message),
        budget: _extractBudget(message),
      );
    }

    if (budgetKeywords.any((keyword) => message.contains(keyword))) {
      return AIIntent(
        type: AIIntentType.budgetQuestion,
        category: _extractCategory(message),
        location: _extractLocation(message),
        eventType: _extractEventType(message),
        budget: _extractBudget(message),
      );
    }

    if (greetingKeywords.any((keyword) => message.contains(keyword))) {
      return const AIIntent(type: AIIntentType.greeting);
    }

    return const AIIntent(type: AIIntentType.generalQuestion);
  }

  /// Обработать запрос на поиск специалиста
  Future<AIMessage> _handleFindSpecialistIntent(
    AIIntent intent,
    String originalMessage,
  ) async {
    try {
      // Ищем специалистов по категории
      var specialists = <Specialist>[];

      if (intent.category != null) {
        specialists = await _specialistService.getSpecialistsByCategory(
          intent.category!,
          limit: 3,
        );
      } else {
        // Если категория не определена, ищем по тексту
        specialists = await _specialistService.searchSpecialists(
          query: originalMessage,
        );
      }

      if (specialists.isEmpty) {
        return AIMessage(
          id: _generateMessageId(),
          type: AIMessageType.assistant,
          content:
              'К сожалению, я не нашел подходящих специалистов. Попробуйте изменить критерии поиска или обратитесь к нашему каталогу специалистов.',
          timestamp: DateTime.now(),
        );
      }

      // Формируем ответ с предложениями специалистов
      final response =
          _buildSpecialistRecommendationResponse(specialists, intent);

      return AIMessage(
        id: _generateMessageId(),
        type: AIMessageType.assistant,
        content: response,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Ошибка поиска специалистов: $e');
      return AIMessage(
        id: _generateMessageId(),
        type: AIMessageType.assistant,
        content:
            'Произошла ошибка при поиске специалистов. Попробуйте еще раз.',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Обработать вопрос о бюджете
  Future<AIMessage> _handleBudgetQuestionIntent(
    AIIntent intent,
    String originalMessage,
  ) async {
    try {
      // Получаем средние цены по категории
      var specialists = <Specialist>[];

      if (intent.category != null) {
        specialists = await _specialistService.getSpecialistsByCategory(
          intent.category!,
          limit: 10,
        );
      } else {
        specialists = await _specialistService.getAllSpecialists(limit: 20);
      }

      if (specialists.isEmpty) {
        return AIMessage(
          id: _generateMessageId(),
          type: AIMessageType.assistant,
          content: 'К сожалению, у нас нет данных о ценах в этой категории.',
          timestamp: DateTime.now(),
        );
      }

      // Рассчитываем средние цены
      final avgPrice =
          specialists.map((s) => s.hourlyRate).reduce((a, b) => a + b) /
              specialists.length;
      final minPrice =
          specialists.map((s) => s.hourlyRate).reduce((a, b) => a < b ? a : b);
      final maxPrice =
          specialists.map((s) => s.hourlyRate).reduce((a, b) => a > b ? a : b);

      final response =
          _buildBudgetResponse(avgPrice, minPrice, maxPrice, intent);

      return AIMessage(
        id: _generateMessageId(),
        type: AIMessageType.assistant,
        content: response,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Ошибка расчета бюджета: $e');
      return AIMessage(
        id: _generateMessageId(),
        type: AIMessageType.assistant,
        content: 'Произошла ошибка при расчете бюджета. Попробуйте еще раз.',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Обработать общий вопрос
  Future<AIMessage> _handleGeneralQuestionIntent(String message) async =>
      AIMessage(
        id: _generateMessageId(),
        type: AIMessageType.assistant,
        content:
            'Я помогу вам найти специалистов для вашего мероприятия. Вы можете спросить:\n\n'
            '• "Подбери ведущего для свадьбы в Москве"\n'
            '• "Какой бюджет нужен на корпоратив для 50 человек?"\n'
            '• "Найди фотографа для дня рождения"\n\n'
            'Или просто опишите, что вам нужно!',
        timestamp: DateTime.now(),
      );

  /// Обработать приветствие
  AIMessage _handleGreetingIntent() => AIMessage(
        id: _generateMessageId(),
        type: AIMessageType.assistant,
        content: 'Привет! Я ваш AI-помощник по планированию мероприятий. 🎉\n\n'
            'Я помогу вам:\n'
            '• Найти подходящих специалистов\n'
            '• Рассчитать примерный бюджет\n'
            '• Дать советы по организации\n\n'
            'Просто опишите, какое мероприятие вы планируете!',
        timestamp: DateTime.now(),
      );

  /// Обработать неизвестный запрос
  AIMessage _handleUnknownIntent(String message) => AIMessage(
        id: _generateMessageId(),
        type: AIMessageType.assistant,
        content:
            'Я не совсем понял ваш запрос. Попробуйте переформулировать или задайте один из этих вопросов:\n\n'
            '• "Найди фотографа для свадьбы"\n'
            '• "Сколько стоит ведущий?"\n'
            '• "Подбери DJ для корпоратива"',
        timestamp: DateTime.now(),
      );

  /// Извлечь категорию из сообщения
  SpecialistCategory? _extractCategory(String message) {
    final categoryMap = {
      'фотограф': SpecialistCategory.photographer,
      'видеограф': SpecialistCategory.videographer,
      'dj': SpecialistCategory.dj,
      'ведущий': SpecialistCategory.host,
      'декоратор': SpecialistCategory.decorator,
      'музыкант': SpecialistCategory.musician,
      'аниматор': SpecialistCategory.animator,
      'флорист': SpecialistCategory.florist,
      'визажист': SpecialistCategory.makeup,
      'парикмахер': SpecialistCategory.hairstylist,
    };

    for (final entry in categoryMap.entries) {
      if (message.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Извлечь местоположение из сообщения
  String? _extractLocation(String message) {
    final locations = [
      'москва',
      'санкт-петербург',
      'екатеринбург',
      'новосибирск',
    ];
    for (final location in locations) {
      if (message.contains(location)) {
        return location;
      }
    }
    return null;
  }

  /// Извлечь тип мероприятия из сообщения
  String? _extractEventType(String message) {
    final eventTypes = [
      'свадьба',
      'день рождения',
      'корпоратив',
      'конференция',
    ];
    for (final eventType in eventTypes) {
      if (message.contains(eventType)) {
        return eventType;
      }
    }
    return null;
  }

  /// Извлечь бюджет из сообщения
  double? _extractBudget(String message) {
    final regex = RegExp(r'(\d+)\s*(тысяч|тыс|к|рублей|руб)');
    final match = regex.firstMatch(message);
    if (match != null) {
      final amount = double.tryParse(match.group(1) ?? '');
      if (amount != null) {
        return amount * 1000; // Конвертируем в рубли
      }
    }
    return null;
  }

  /// Построить ответ с рекомендациями специалистов
  String _buildSpecialistRecommendationResponse(
    List<Specialist> specialists,
    AIIntent intent,
  ) {
    final buffer = StringBuffer();

    if (intent.category != null) {
      buffer.writeln(
        'Вот подходящие ${intent.category!.displayName.toLowerCase()}ы для вашего мероприятия:\n',
      );
    } else {
      buffer.writeln('Вот подходящие специалисты:\n');
    }

    for (var i = 0; i < specialists.length; i++) {
      final specialist = specialists[i];
      buffer.writeln('${i + 1}. **${specialist.name}**');
      buffer.writeln('   ${specialist.categoryDisplayName}');
      buffer.writeln(
        '   ⭐ Рейтинг: ${specialist.rating.toStringAsFixed(1)} (${specialist.reviewCount} отзывов)',
      );
      buffer.writeln(
        '   💰 Цена: ${specialist.hourlyRate.toStringAsFixed(0)} ₽/час',
      );
      if (specialist.description != null &&
          specialist.description!.isNotEmpty) {
        buffer.writeln('   📝 ${specialist.description}');
      }
      buffer.writeln();
    }

    buffer.writeln(
      'Хотите узнать больше о каком-то специалисте или найти других?',
    );

    return buffer.toString();
  }

  /// Построить ответ о бюджете
  String _buildBudgetResponse(
    double avgPrice,
    double minPrice,
    double maxPrice,
    AIIntent intent,
  ) {
    final buffer = StringBuffer();

    if (intent.category != null) {
      buffer.writeln(
        'Примерные цены на ${intent.category!.displayName.toLowerCase()}ов:\n',
      );
    } else {
      buffer.writeln('Примерные цены на специалистов:\n');
    }

    buffer.writeln('💰 Средняя цена: ${avgPrice.toStringAsFixed(0)} ₽/час');
    buffer.writeln('📉 От: ${minPrice.toStringAsFixed(0)} ₽/час');
    buffer.writeln('📈 До: ${maxPrice.toStringAsFixed(0)} ₽/час\n');

    if (intent.eventType != null) {
      final hours = _getEstimatedHours(intent.eventType!);
      final totalMin = minPrice * hours;
      final totalMax = maxPrice * hours;
      final totalAvg = avgPrice * hours;

      buffer.writeln('Для ${intent.eventType} (примерно $hours часов):');
      buffer.writeln('💰 Общий бюджет: ${totalAvg.toStringAsFixed(0)} ₽');
      buffer.writeln('📉 От: ${totalMin.toStringAsFixed(0)} ₽');
      buffer.writeln('📈 До: ${totalMax.toStringAsFixed(0)} ₽\n');
    }

    buffer.writeln(
      '*Цены могут варьироваться в зависимости от опыта, локации и дополнительных услуг.*',
    );

    return buffer.toString();
  }

  /// Получить примерное количество часов для типа мероприятия
  int _getEstimatedHours(String eventType) {
    switch (eventType) {
      case 'свадьба':
        return 8;
      case 'день рождения':
        return 4;
      case 'корпоратив':
        return 6;
      case 'конференция':
        return 8;
      default:
        return 4;
    }
  }

  /// Сохранить сообщение в Firestore
  Future<void> _saveMessage(String userId, AIMessage message) async {
    await _db
        .collection('ai_chats')
        .doc(userId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  /// Генерация ID сообщения
  String _generateMessageId() =>
      'msg_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';

  /// Очистить историю сообщений пользователя
  Future<void> clearMessageHistory(String userId) async {
    final messages = await _db
        .collection('ai_chats')
        .doc(userId)
        .collection('messages')
        .get();

    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

/// Намерение пользователя
class AIIntent {
  const AIIntent({
    required this.type,
    this.category,
    this.location,
    this.eventType,
    this.budget,
  });

  final AIIntentType type;
  final SpecialistCategory? category;
  final String? location;
  final String? eventType;
  final double? budget;
}

/// Типы намерений
enum AIIntentType {
  findSpecialist, // Поиск специалиста
  budgetQuestion, // Вопрос о бюджете
  generalQuestion, // Общий вопрос
  greeting, // Приветствие
  unknown, // Неизвестное намерение
}
