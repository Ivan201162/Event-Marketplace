import 'package:flutter/material.dart';
import '../test_data/chat_test_data.dart';

/// Кнопка для создания тестовых данных чатов
class ChatTestDataButton extends StatefulWidget {
  const ChatTestDataButton({super.key});

  @override
  State<ChatTestDataButton> createState() => _ChatTestDataButtonState();
}

class _ChatTestDataButtonState extends State<ChatTestDataButton> {
  final ChatTestDataGenerator _dataGenerator = ChatTestDataGenerator();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateTestData,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chat),
            label: Text(_isLoading ? 'Создание...' : 'Создать тестовые чаты'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _clearTestData,
            icon: const Icon(Icons.delete),
            label: const Text('Очистить тестовые данные'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      );

  Future<void> _generateTestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dataGenerator.generateTestChatData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тестовые данные для чатов успешно созданы!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания тестовых данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text(
            'Вы уверены, что хотите удалить все тестовые данные чатов?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _dataGenerator.clearTestData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тестовые данные успешно удалены!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления тестовых данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
