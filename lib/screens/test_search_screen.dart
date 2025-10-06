import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/back_utils.dart';
import '../test_data/specialist_test_data.dart';

class TestSearchScreen extends ConsumerStatefulWidget {
  const TestSearchScreen({super.key});

  @override
  ConsumerState<TestSearchScreen> createState() => _TestSearchScreenState();
}

class _TestSearchScreenState extends ConsumerState<TestSearchScreen> {
  bool _isLoading = false;
  String _status = '';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BackUtils.buildAppBar(
          context,
          title: 'Тестирование поиска',
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Управление тестовыми данными',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createTestData,
                icon: const Icon(Icons.add),
                label: const Text('Создать тестовых специалистов'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _clearTestData,
                icon: const Icon(Icons.clear),
                label: const Text('Очистить тестовые данные'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getStats,
                icon: const Icon(Icons.analytics),
                label: const Text('Получить статистику'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/search');
                },
                icon: const Icon(Icons.search),
                label: const Text('Открыть поиск специалистов'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _createTestData() async {
    setState(() {
      _isLoading = true;
      _status = 'Создание тестовых данных...';
    });

    try {
      await SpecialistTestData.createTestSpecialists();
      setState(() {
        _status = '✅ Тестовые данные успешно созданы!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Ошибка создания данных: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isLoading = true;
      _status = 'Очистка тестовых данных...';
    });

    try {
      await SpecialistTestData.clearTestData();
      setState(() {
        _status = '✅ Тестовые данные очищены!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Ошибка очистки данных: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getStats() async {
    setState(() {
      _isLoading = true;
      _status = 'Получение статистики...';
    });

    try {
      final stats = await SpecialistTestData.getTestDataStats();
      setState(() {
        _status = '''
📊 Статистика:
Всего специалистов: ${stats['totalCount']}
Средний рейтинг: ${(stats['averageRating'] as double).toStringAsFixed(1)}
Средняя цена: ${(stats['averagePrice'] as double).toInt()}₽
Верифицированных: ${stats['verifiedCount']}
Онлайн: ${stats['onlineCount']}

🏷️ Категории:
${(stats['categories'] as Map<String, int>).entries.map((e) => '${e.key}: ${e.value}').join('\n')}

🏙️ Города:
${(stats['cities'] as Map<String, int>).entries.map((e) => '${e.key}: ${e.value}').join('\n')}
        ''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Ошибка получения статистики: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
