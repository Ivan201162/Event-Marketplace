import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'chat_data_generator.dart';
import 'test_data_generator.dart';

/// Виджет для запуска генерации тестовых данных через UI
class TestDataGeneratorApp extends StatelessWidget {
  const TestDataGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Event Marketplace - Test Data Generator',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const TestDataGeneratorScreen(),
      );
}

class TestDataGeneratorScreen extends StatefulWidget {
  const TestDataGeneratorScreen({super.key});

  @override
  State<TestDataGeneratorScreen> createState() => _TestDataGeneratorScreenState();
}

class _TestDataGeneratorScreenState extends State<TestDataGeneratorScreen> {
  bool _isGenerating = false;
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });

    // Автоматическая прокрутка вниз
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _generateTestData() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _logs.clear();
    });

    try {
      _addLog('🚀 Инициализация Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _addLog('✅ Firebase инициализирован');

      final generator = TestDataGenerator();
      final chatGenerator = ChatDataGenerator();

      _addLog('📊 ЭТАП 1: Генерация основных данных');

      _addLog('👥 Генерация специалистов...');
      final specialists = await generator.generateSpecialists();
      _addLog('✅ Сгенерировано ${specialists.length} специалистов');

      _addLog('👤 Генерация заказчиков...');
      final customers = await generator.generateCustomers();
      _addLog('✅ Сгенерировано ${customers.length} заказчиков');

      _addLog('📅 Генерация бронирований...');
      final bookings = await generator.generateBookings(customers, specialists);
      _addLog('✅ Сгенерировано ${bookings.length} бронирований');

      _addLog('⭐ Генерация отзывов...');
      final reviews = await generator.generateReviews(bookings, customers, specialists);
      _addLog('✅ Сгенерировано ${reviews.length} отзывов');

      _addLog('💡 Генерация идей...');
      final ideas = await generator.generateEventIdeas();
      _addLog('✅ Сгенерировано ${ideas.length} идей');

      _addLog('📤 ЭТАП 2: Загрузка данных в Firestore');

      _addLog('📤 Загрузка специалистов...');
      await generator.uploadSpecialists(specialists);
      _addLog('✅ Специалисты загружены');

      _addLog('📤 Загрузка заказчиков...');
      await generator.uploadCustomers(customers);
      _addLog('✅ Заказчики загружены');

      _addLog('📤 Загрузка бронирований...');
      await generator.uploadBookings(bookings);
      _addLog('✅ Бронирования загружены');

      _addLog('📤 Загрузка отзывов...');
      await generator.uploadReviews(reviews);
      _addLog('✅ Отзывы загружены');

      _addLog('📤 Загрузка идей...');
      await generator.uploadIdeas(ideas);
      _addLog('✅ Идеи загружены');

      _addLog('💬 ЭТАП 3: Генерация чатов и уведомлений');

      _addLog('💬 Создание чатов...');
      await chatGenerator.generateChats(customers, specialists, bookings);
      _addLog('✅ Чаты созданы');

      _addLog('🔔 Создание уведомлений...');
      await chatGenerator.generateNotifications(
        customers,
        specialists,
        bookings,
      );
      _addLog('✅ Уведомления созданы');

      _addLog('🔍 ЭТАП 4: Проверка данных');
      await generator.verifyTestData();

      _addLog('🎉 ГЕНЕРАЦИЯ ЗАВЕРШЕНА УСПЕШНО!');
      _addLog('📋 Данные готовы для использования в приложении');
    } catch (e, stackTrace) {
      _addLog('❌ ОШИБКА: $e');
      _addLog('📍 Stack trace: ${stackTrace.toString()}');

      // Показываем диалог с ошибкой
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ошибка генерации'),
            content: Text('Произошла ошибка: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Event Marketplace - Генератор тестовых данных'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информационная карточка
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Генератор тестовых данных',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Этот инструмент создаст полную базу тестовых данных для Event Marketplace:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ≥2000 специалистов по всей России'),
                          Text('• ≥500 заказчиков'),
                          Text('• ≥5000 бронирований'),
                          Text('• ≥3000 отзывов'),
                          Text('• ≥1000 идей для мероприятий'),
                          Text('• ≥1000 чатов с переписками'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Процесс может занять 10-30 минут. Убедитесь в стабильном подключении к интернету.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Кнопка запуска
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateTestData,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    _isGenerating ? 'Генерация в процессе...' : 'Запустить генерацию данных',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isGenerating ? Colors.grey : Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Область логов
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.terminal),
                            const SizedBox(width: 8),
                            Text(
                              'Лог генерации',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            if (_logs.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  setState(_logs.clear);
                                },
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Очистить'),
                              ),
                          ],
                        ),
                        const Divider(),
                        Expanded(
                          child: _logs.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Нажмите "Запустить генерацию данных" для начала',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  itemCount: _logs.length,
                                  itemBuilder: (context, index) {
                                    final log = _logs[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        log,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                          color: log.contains('❌')
                                              ? Colors.red
                                              : log.contains('✅')
                                                  ? Colors.green
                                                  : log.contains('🎉')
                                                      ? Colors.purple
                                                      : Colors.black87,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Точка входа для запуска генератора данных через UI
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TestDataGeneratorApp());
}
