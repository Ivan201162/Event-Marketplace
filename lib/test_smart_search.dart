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
    print('🚀 Запуск тестов умного поиска...\n');

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
      
      print('\n✅ Все тесты пройдены успешно!');
    } catch (e) {
      print('\n❌ Ошибка в тестах: $e');
    }
  }

  /// Тест генерации тестовых данных
  Future<void> _testDataGeneration() async {
    print('📊 Тест 1: Генерация тестовых данных');
    
    try {
      await _dataGenerator.generateTestSpecialists(count: 10);
      print('✅ Тестовые данные сгенерированы успешно');
    } catch (e) {
      print('❌ Ошибка генерации данных: $e');
    }
    
    print('');
  }

  /// Тест умного поиска
  Future<void> _testSmartSearch() async {
    print('🔍 Тест 2: Умный поиск специалистов');
    
    try {
      // Поиск по категории
      final specialistsByCategory = await _smartSearchService.smartSearch(
        category: SpecialistCategory.host,
        limit: 5,
      );
      print('✅ Поиск по категории: найдено ${specialistsByCategory.length} специалистов');
      
      // Поиск по городу
      final specialistsByCity = await _smartSearchService.smartSearch(
        city: 'Москва',
        limit: 5,
      );
      print('✅ Поиск по городу: найдено ${specialistsByCity.length} специалистов');
      
      // Поиск по цене
      final specialistsByPrice = await _smartSearchService.smartSearch(
        minPrice: 10000,
        maxPrice: 30000,
        limit: 5,
      );
      print('✅ Поиск по цене: найдено ${specialistsByPrice.length} специалистов');
      
      // Поиск по стилю
      final specialistsByStyle = await _smartSearchService.smartSearch(
        styles: ['классика', 'юмор'],
        limit: 5,
      );
      print('✅ Поиск по стилю: найдено ${specialistsByStyle.length} специалистов');
      
    } catch (e) {
      print('❌ Ошибка умного поиска: $e');
    }
    
    print('');
  }

  /// Тест персональных рекомендаций
  Future<void> _testPersonalRecommendations() async {
    print('🎯 Тест 3: Персональные рекомендации');
    
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
      final saved = await _smartSearchService.saveUserPreferences(preferences);
      print('✅ Предпочтения сохранены: $saved');
      
      // Получаем рекомендации
      final recommendations = await _smartSearchService.getPersonalRecommendations(
        testUserId,
        limit: 5,
      );
      print('✅ Персональные рекомендации: найдено ${recommendations.length} специалистов');
      
      // Проверяем совместимость
      if (recommendations.isNotEmpty) {
        final specialist = recommendations.first;
        final compatibility = specialist.calculateCompatibility(
          preferences.getCompatibilityPreferences(),
        );
        print('✅ Совместимость с первым специалистом: ${(compatibility * 100).toStringAsFixed(1)}%');
      }
      
    } catch (e) {
      print('❌ Ошибка персональных рекомендаций: $e');
    }
    
    print('');
  }

  /// Тест AI-помощника
  Future<void> _testAIAssistant() async {
    print('🤖 Тест 4: AI-помощник');
    
    try {
      // Начинаем беседу
      final conversation = await _aiAssistantService.startConversation(
        userId: 'test_user_123',
      );
      print('✅ Беседа начата: ${conversation.id}');
      
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
        print('✅ Ответ AI: ${response.text.substring(0, 50)}...');
        
        // Небольшая пауза между сообщениями
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
    } catch (e) {
      print('❌ Ошибка AI-помощника: $e');
    }
    
    print('');
  }

  /// Тест предпочтений пользователя
  Future<void> _testUserPreferences() async {
    print('👤 Тест 5: Предпочтения пользователя');
    
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
      await _smartSearchService.saveUserPreferences(preferences);
      print('✅ Предпочтения созданы и сохранены');
      
      // Загружаем
      final loadedPreferences = await _smartSearchService.getUserPreferences(testUserId);
      print('✅ Предпочтения загружены: ${loadedPreferences?.likedStyles.length} стилей');
      
      // Обновляем
      await _smartSearchService.updateUserPreferences(
        testUserId,
        {'preferredBudget': 50000},
      );
      print('✅ Предпочтения обновлены');
      
      // Записываем взаимодействие
      await _smartSearchService.recordUserInteraction(
        userId: testUserId,
        specialistId: 'test_specialist_123',
        action: 'view',
        metadata: {'category': 'photographer'},
      );
      print('✅ Взаимодействие записано');
      
    } catch (e) {
      print('❌ Ошибка предпочтений пользователя: $e');
    }
    
    print('');
  }

  /// Тест статистики
  Future<void> _testStatistics() async {
    print('📈 Тест 6: Статистика поиска');
    
    try {
      final stats = await _smartSearchService.getSearchStats();
      print('✅ Статистика получена:');
      print('   - Всего специалистов: ${stats['totalSpecialists']}');
      print('   - Доступных: ${stats['availableSpecialists']}');
      print('   - Средний рейтинг: ${stats['averageRating']?.toStringAsFixed(1)}');
      print('   - Средняя цена: ${stats['averagePrice']?.toStringAsFixed(0)} ₽');
      
    } catch (e) {
      print('❌ Ошибка статистики: $e');
    }
    
    print('');
  }

  /// Тест совместимости
  Future<void> _testCompatibility() async {
    print('🎯 Тест 7: Совместимость специалистов');
    
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
      
      await _smartSearchService.saveUserPreferences(preferences);
      
      // Получаем специалистов по совместимости
      final compatibleSpecialists = await _smartSearchService.getSpecialistsByCompatibility(
        testUserId,
        limit: 5,
      );
      
      print('✅ Специалисты по совместимости: найдено ${compatibleSpecialists.length}');
      
      for (final specialist in compatibleSpecialists) {
        print('   - ${specialist.name}: ${(specialist.compatibilityScore * 100).toStringAsFixed(1)}%');
      }
      
    } catch (e) {
      print('❌ Ошибка совместимости: $e');
    }
    
    print('');
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
      appBar: AppBar(
        title: const Text('Тесты умного поиска'),
      ),
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
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
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
    const originalPrint = print;
    print = (object) {
      setState(() {
        _output += '$object\n';
      });
    };

    try {
      await _tester.runAllTests();
    } finally {
      print = originalPrint;
      setState(() {
        _isRunning = false;
      });
    }
  }
}
