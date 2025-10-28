import 'package:event_marketplace_app/core/navigation/back_utils.dart';
import 'package:event_marketplace_app/services/dev_seed_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Экран для управления тестовыми данными (только в debug режиме)
class DevSeedScreen extends StatefulWidget {
  const DevSeedScreen({super.key});

  @override
  State<DevSeedScreen> createState() => _DevSeedScreenState();
}

class _DevSeedScreenState extends State<DevSeedScreen> {
  final DevSeedService _seedService = DevSeedService();

  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  Widget build(BuildContext context) {
    // Проверяем, доступен ли экран (только в debug режиме)
    if (!kDebugMode) {
      return Scaffold(
        appBar: BackUtils.buildAppBar(context, title: 'Тестовые данные'),
        body: const Center(
          child: Text('Этот экран доступен только в debug режиме',
              style: TextStyle(fontSize: 16),),
        ),
      );
    }

    return Scaffold(
      appBar:
          BackUtils.buildAppBar(context, title: 'Управление тестовыми данными'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Информационная карточка
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Информация',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Этот экран позволяет создавать и управлять тестовыми данными для разработки и тестирования приложения.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Доступно только в debug режиме',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Статус сообщение
            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _isError
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _isError ? Colors.red : Colors.green),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(color: _isError ? Colors.red : Colors.green),
                ),
              ),

            // Кнопки управления
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Создание тестовых данных
              ElevatedButton.icon(
                onPressed: _createTestData,
                icon: const Icon(Icons.add_circle),
                label: const Text('Создать тестовые данные'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 12),

              // Очистка тестовых данных
              ElevatedButton.icon(
                onPressed: _clearTestData,
                icon: const Icon(Icons.clear_all),
                label: const Text('Очистить тестовые данные'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 12),

              // Проверка статуса
              OutlinedButton.icon(
                onPressed: _checkStatus,
                icon: const Icon(Icons.info_outline),
                label: const Text('Проверить статус'),
                style:
                    OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ],

            const SizedBox(height: 24),

            // Информация о созданных данных
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Что создается:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDataItem('👥', '10 специалистов разных категорий'),
                    _buildDataItem('📝', '3 тестовых поста'),
                    _buildDataItem('📸', '3 тестовые сторис'),
                    _buildDataItem('⭐', '3 тестовых отзыва'),
                    _buildDataItem('📅', '3 тестовых бронирования'),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Предупреждение
            Card(
              color: Colors.orange.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Внимание: Тестовые данные создаются в реальной базе данных Firebase',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );

  Future<void> _createTestData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      await _seedService.seedTestData();
      setState(() {
        _statusMessage = '✅ Тестовые данные успешно созданы!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка создания тестовых данных: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text(
          'Вы уверены, что хотите удалить все тестовые данные? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      await _seedService.clearTestData();
      setState(() {
        _statusMessage = '✅ Тестовые данные успешно очищены!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка очистки тестовых данных: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      // В реальном приложении здесь бы была проверка существования данных
      // final hasData = await _seedService._checkExistingTestData();
      const hasData = false; // Заглушка для теста
      setState(() {
        _statusMessage = hasData
            ? '✅ Тестовые данные уже созданы'
            : 'ℹ️ Тестовые данные не созданы';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка проверки статуса: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
