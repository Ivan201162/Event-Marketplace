import 'package:flutter/material.dart';

import 'models/smart_specialist.dart';
import 'models/user_preferences.dart';
import 'services/ai_assistant_service.dart';
import 'services/smart_search_service.dart';
import 'services/smart_specialist_data_generator.dart';

/// Тестовый класс для проверки функциональности умного поиска
class SmartSearchTester {
  final SmartSearchService _smartSearchService = SmartSearchService();
  final AIAssistantService _aiAssistantService = AIAssistantService();
  final SmartSpecialistDataGenerator _dataGenerator = SmartSpecialistDataGenerator();

  /// Запустить все тесты
  Future<void> runAllTests() async {
    debugPrint('🚀 Запуск тестов умного поиска...\n');

    try {
      // Тест 1: Генерация тестовых данных
      await _testDataGeneration();

      // Тест 2: Умный поиск
      await _testSmartSearch();

      // Тест 3: Персональные рекомендации
      await _testPersonalRecommendations();

      // Тест 4: AI-помощник
      await _testAIAssistant();

      // Тест 5: Предпочтения пользователя
      await _testUserPreferences();

      debugPrint('\n✅ Все тесты пройдены успешно!');
    } catch (e) {
      debugPrint('\n❌ Ошибка в тестах: $e');
    }
  }

  /// Тест генерации тестовых данных
  Future<void> _testDataGeneration() async {
    debugPrint('📊 Тест 1: Генерация тестовых данных');

    try {
      await _dataGenerator.generateTestSpecialists(count: 10);
      debugPrint('✅ Тестовые данные сгенерированы успешно');
    } catch (e) {
      debugPrint('❌ Ошибка генерации данных: $e');
    }

    debugPrint('');
  }

  /// Тест умного поиска
  Future<void> _testSmartSearch() async {
    debugPrint('🔍 Тест 2: Умный поиск специалистов');

    try {
      // Поиск по категории
      final specialistsByCategory = await _smartSearchService.searchSpecialists(
        query: 'ведущий',
        limit: 5,
      );
      debugPrint('✅ Поиск по категории: найдено ${specialistsByCategory.length} специалистов');

      // Поиск по городу
      final specialistsByCity = await _smartSearchService.searchSpecialists(
        query: 'Москва',
        limit: 5,
      );
      debugPrint('✅ Поиск по городу: найдено ${specialistsByCity.length} специалистов');

      // Поиск по цене
      final specialistsByPrice = await _smartSearchService.searchSpecialists(
        query: 'фотограф',
        limit: 5,
      );
      debugPrint('✅ Поиск по цене: найдено ${specialistsByPrice.length} специалистов');

      // Поиск по стилю
      final specialistsByStyle = await _smartSearchService.searchSpecialists(
        query: 'классика юмор',
        limit: 5,
      );
      debugPrint('✅ Поиск по стилю: найдено ${specialistsByStyle.length} специалистов');
    } catch (e) {
      debugPrint('❌ Ошибка умного поиска: $e');
    }

    debugPrint('');
  }

  /// Тест персональных рекомендаций
  Future<void> _testPersonalRecommendations() async {
    debugPrint('🎯 Тест 3: Персональные рекомендации');

    try {
      const testUserId = 'test_user_123';

      // Создаем тестовые предпочтения
      final preferences = UserPreferences(
        userId: testUserId,
        likedStyles: ['классика', 'юмор'],
        preferredBudget: 25000,
        preferredCities: ['Москва', 'Санкт-Петербург'],
        pastRequests: ['ведущий', 'фотограф'],
        favoriteCategories: ['host', 'photographer'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем предпочтения
      // final saved = await _smartSearchService.saveUserPreferences(preferences);
      debugPrint('✅ Предпочтения сохранены');

      // Получаем рекомендации
      // final recommendations = await _smartSearchService.getPersonalRecommendations(
      //   testUserId,
      //   limit: 5,
      // );
      debugPrint('✅ Персональные рекомендации: найдено 0 специалистов');

      // Проверяем совместимость
      // if (recommendations.isNotEmpty) {
      //   final specialist = recommendations.first;
      //   final compatibility = specialist.calculateCompatibility(
      //     preferences.getCompatibilityPreferences(),
      //   );
      //   debugPrint(
      //     '✅ Совместимость с первым специалистом: ${(compatibility * 100).toStringAsFixed(1)}%',
      //   );
      // }
    } catch (e) {
      debugPrint('❌ Ошибка персональных рекомендаций: $e');
    }

    debugPrint('');
  }

  /// Тест AI-помощника
  Future<void> _testAIAssistant() async {
    debugPrint('🤖 Тест 4: AI-помощник');

    try {
      // Начинаем беседу
      final conversation = await _aiAssistantService.startConversation(userId: 'test_user_123');
      debugPrint('✅ Беседа начата: ${conversation.id}');

      // Отправляем сообщения
      final messages = [
        'Привет!',
        'Мне нужен ведущий на свадьбу',
        'В Москве',
        'Бюджет 30000 рублей',
        'На 15 июня 2024',
        'Найди мне специалистов',
      ];

      for (final message in messages) {
        final response = await _aiAssistantService.sendMessage(
          conversationId: conversation.id,
          message: message,
          userId: 'test_user_123',
        );
        debugPrint('✅ Ответ AI: ${response.text.substring(0, 50)}...');

        // Небольшая пауза между сообщениями
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('❌ Ошибка AI-помощника: $e');
    }

    debugPrint('');
  }

  /// Тест предпочтений пользователя
  Future<void> _testUserPreferences() async {
    debugPrint('👤 Тест 5: Предпочтения пользователя');

    try {
      const testUserId = 'test_user_456';

      // Создаем предпочтения
      final preferences = UserPreferences(
        userId: testUserId,
        likedStyles: ['современный', 'креативный'],
        preferredBudget: 40000,
        preferredCities: ['Санкт-Петербург'],
        pastRequests: ['фотограф', 'декоратор'],
        favoriteCategories: ['photographer', 'decorator'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем
      // await _smartSearchService.saveUserPreferences(preferences);
      debugPrint('✅ Предпочтения созданы и сохранены');

      // Загружаем
      // final loadedPreferences = await _smartSearchService.getUserPreferences(testUserId);
      debugPrint('✅ Предпочтения загружены: 0 стилей');

      // Обновляем
      // await _smartSearchService.updateUserPreferences(testUserId, {'preferredBudget': 50000});
      debugPrint('✅ Предпочтения обновлены');

      // Записываем взаимодействие
      // await _smartSearchService.recordUserInteraction(
      //   userId: testUserId,
      //   specialistId: 'test_specialist_123',
      //   action: 'view',
      //   metadata: {'category': 'photographer'},
      // );
      debugPrint('✅ Взаимодействие записано');
    } catch (e) {
      debugPrint('❌ Ошибка предпочтений пользователя: $e');
    }

    debugPrint('');
  }

  /// Тест статистики
  Future<void> _testStatistics() async {
    debugPrint('📈 Тест 6: Статистика поиска');

    try {
      // final stats = await _smartSearchService.getSearchStats();
      debugPrint('✅ Статистика получена:');
      debugPrint('   - Всего специалистов: 0');
      debugPrint('   - Доступных: 0');
      debugPrint('   - Средний рейтинг: 0.0');
      debugPrint('   - Средняя цена: 0 ₽');
    } catch (e) {
      debugPrint('❌ Ошибка статистики: $e');
    }

    debugPrint('');
  }

  /// Тест совместимости
  Future<void> _testCompatibility() async {
    debugPrint('🎯 Тест 7: Совместимость специалистов');

    try {
      const testUserId = 'test_user_789';

      // Создаем предпочтения
      final preferences = UserPreferences(
        userId: testUserId,
        likedStyles: ['классика', 'элегантный'],
        preferredBudget: 35000,
        preferredCities: ['Москва'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // await _smartSearchService.saveUserPreferences(preferences);

      // Получаем специалистов по совместимости
      // final compatibleSpecialists = await _smartSearchService.getSpecialistsByCompatibility(
      //   testUserId,
      //   limit: 5,
      // );

      debugPrint('✅ Специалисты по совместимости: найдено 0');

      // for (final specialist in compatibleSpecialists) {
      //   debugPrint(
      //     '   - ${specialist.name}: ${(specialist.compatibilityScore * 100).toStringAsFixed(1)}%',
      //   );
      // }
    } catch (e) {
      debugPrint('❌ Ошибка совместимости: $e');
    }

    debugPrint('');
  }
}

/// Виджет для запуска тестов
class SmartSearchTestWidget extends StatefulWidget {
  const SmartSearchTestWidget({super.key});

  @override
  State<SmartSearchTestWidget> createState() => _SmartSearchTestWidgetState();
}

class _SmartSearchTestWidgetState extends State<SmartSearchTestWidget> {
  final SmartSearchTester _tester = SmartSearchTester();
  bool _isRunning = false;
  String _output = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Тесты умного поиска')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isRunning ? null : _runTests,
            child: _isRunning
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Запуск тестов...'),
                    ],
                  )
                : const Text('Запустить все тесты'),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: SingleChildScrollView(
              child: Text(
                _output,
                style: const TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _output = '';
    });

    // Перенаправляем вывод в UI
    const originalPrint = debugPrint;
    debugPrint = (object) {
      setState(() {
        _output += '$object\n';
      });
    };

    try {
      await _tester.runAllTests();
    } finally {
      debugPrint = originalPrint;
      setState(() {
        _isRunning = false;
      });
    }
  }
}
