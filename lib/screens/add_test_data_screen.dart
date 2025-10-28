import 'package:event_marketplace_app/services/test_data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран для добавления тестовых данных
class AddTestDataScreen extends ConsumerStatefulWidget {
  const AddTestDataScreen({super.key});

  @override
  ConsumerState<AddTestDataScreen> createState() => _AddTestDataScreenState();
}

class _AddTestDataScreenState extends ConsumerState<AddTestDataScreen> {
  final _testDataService = TestDataService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Добавить тестовые данные'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Добавление тестовых данных в Firestore',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Добавление данных...'),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    // Кнопка добавления всех данных
                    ElevatedButton.icon(
                      onPressed: _addAllTestData,
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Добавить все тестовые данные'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Кнопка очистки данных
                    ElevatedButton.icon(
                      onPressed: _clearTestData,
                      icon: const Icon(Icons.delete),
                      label: const Text('Очистить тестовые данные'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Информация о данных
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Что будет добавлено:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold,),
                            ),
                            const SizedBox(height: 8),
                            const Text('👥 5 тестовых пользователей'),
                            const Text('📢 10 постов в ленту'),
                            const Text('📝 8 заявок'),
                            const Text('💬 5 чатов с сообщениями'),
                            const Text('💡 8 идей'),
                            const SizedBox(height: 8),
                            Text(
                              'Все данные помечены флагом isTest: true',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600],),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

  /// Добавить все тестовые данные
  Future<void> _addAllTestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _testDataService.addAllTestDataToFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Все тестовые данные успешно добавлены!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red,),);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Очистить тестовые данные
  Future<void> _clearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content:
            const Text('Вы уверены, что хотите удалить все тестовые данные?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _testDataService.clearTestDataFromFirestore();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Тестовые данные очищены!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(
              content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red,),);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
