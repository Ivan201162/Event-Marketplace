import 'package:event_marketplace_app/services/test_data_service.dart';
import 'package:flutter/material.dart';

/// Экран для управления тестовыми данными
class TestDataManagementScreen extends StatefulWidget {
  const TestDataManagementScreen({super.key});

  @override
  State<TestDataManagementScreen> createState() =>
      _TestDataManagementScreenState();
}

class _TestDataManagementScreenState extends State<TestDataManagementScreen> {
  final TestDataService _testDataService = TestDataService();
  Map<String, int> _stats = {};
  bool _isLoading = false;
  bool _hasTestData = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _testDataService.getTestDataStats();
      final hasData = await _testDataService.hasTestData();

      setState(() {
        _stats = stats;
        _hasTestData = hasData;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка при загрузке статистики: $e');
    }
  }

  Future<void> _createTestData() async {
    setState(() => _isLoading = true);

    try {
      await _testDataService.populateAll();
      await _loadStats();
      _showSuccessSnackBar('Тестовые данные созданы успешно!');
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка при создании данных: $e');
    }
  }

  Future<void> _clearTestData() async {
    final confirmed = await _showConfirmDialog(
      'Очистка данных',
      'Вы уверены, что хотите удалить все тестовые данные? Это действие нельзя отменить.',
    );

    if (!confirmed) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _testDataService.clearAllTestData();
      await _loadStats();
      _showSuccessSnackBar('Тестовые данные удалены успешно!');
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка при удалении данных: $e');
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSuccessSnackBar(String message) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),);

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Управление тестовыми данными'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Статус
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Статус тестовых данных',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _hasTestData
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color:
                                      _hasTestData ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _hasTestData
                                      ? 'Данные существуют'
                                      : 'Данные отсутствуют',
                                  style: TextStyle(
                                    color: _hasTestData
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Статистика
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Статистика',
                                style: Theme.of(context).textTheme.titleLarge,),
                            const SizedBox(height: 8),
                            if (_stats.isEmpty)
                              const Text('Нет данных')
                            else
                              ..._stats.entries.map(
                                (entry) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          _getCollectionDisplayName(entry.key),),
                                      Text(
                                        entry.value.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Кнопки управления
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Управление',
                                style: Theme.of(context).textTheme.titleLarge,),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _hasTestData ? null : _createTestData,
                              icon: const Icon(Icons.add),
                              label: const Text('Создать тестовые данные'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _hasTestData ? _clearTestData : null,
                              icon: const Icon(Icons.delete),
                              label: const Text('Удалить тестовые данные'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _loadStats,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Обновить статистику'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );

  String _getCollectionDisplayName(String key) {
    switch (key) {
      case 'specialists':
        return 'Специалисты';
      case 'chats':
        return 'Чаты';
      case 'bookings':
        return 'Бронирования';
      case 'posts':
        return 'Посты';
      case 'ideas':
        return 'Идеи';
      case 'notifications':
        return 'Уведомления';
      case 'promotions':
        return 'Промоакции';
      case 'reviews':
        return 'Отзывы';
      case 'total':
        return 'Всего';
      default:
        return key;
    }
  }
}
