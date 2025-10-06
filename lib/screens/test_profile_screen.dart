import 'package:flutter/material.dart';

import '../features/specialists/presentation/create_test_specialist_button.dart';
import '../services/test_data_service.dart';
import 'specialist_profile_instagram_screen.dart';

class TestProfileScreen extends StatefulWidget {
  const TestProfileScreen({super.key});

  @override
  State<TestProfileScreen> createState() => _TestProfileScreenState();
}

class _TestProfileScreenState extends State<TestProfileScreen> {
  final TestDataService _testDataService = TestDataService();
  bool _isLoading = false;
  String? _testSpecialistId;

  Future<void> _createTestSpecialist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _testDataService.createTestSpecialists();
      const specialistId = 'specialist_1'; // Используем ID из тестовых данных
      setState(() {
        _testSpecialistId = specialistId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тестовый специалист создан!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания тестового специалиста: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestSpecialist2() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _testDataService.createTestSpecialists();
      const specialistId = 'specialist_2'; // Используем ID из тестовых данных
      setState(() {
        _testSpecialistId = specialistId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Второй тестовый специалист создан!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания тестового специалиста: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _testDataService.clearAllTestData();
      setState(() {
        _testSpecialistId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тестовые данные очищены'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка очистки тестовых данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewTestProfile() {
    if (_testSpecialistId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => SpecialistProfileInstagramScreen(
            specialistId: _testSpecialistId!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тестирование профиля специалиста'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Тестирование Instagram/ВК-стиля профиля специалиста',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Функционал профиля:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Шапка профиля с фото и информацией'),
                      Text('• Сторис (горизонтальный список)'),
                      Text('• Сетка публикаций (3xN)'),
                      Text('• Прайс-лист услуг'),
                      Text('• Контакты специалиста'),
                      Text('• Полноэкранный просмотр постов'),
                      Text('• Просмотр историй в стиле Instagram'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Новая улучшенная кнопка создания тест-специалиста
                CreateTestSpecialistButton(
                  specialistType: 'photographer',
                  onSpecialistCreated: () {
                    setState(() {
                      _testSpecialistId = 'created_photographer';
                    });
                  },
                ),

                const SizedBox(height: 12),

                CreateTestSpecialistButton(
                  specialistType: 'videographer',
                  onSpecialistCreated: () {
                    setState(() {
                      _testSpecialistId = 'created_videographer';
                    });
                  },
                ),

                const SizedBox(height: 12),

                CreateTestSpecialistButton(
                  specialistType: 'dj',
                  onSpecialistCreated: () {
                    setState(() {
                      _testSpecialistId = 'created_dj';
                    });
                  },
                ),

                const SizedBox(height: 12),

                CreateTestSpecialistButton(
                  specialistType: 'host',
                  onSpecialistCreated: () {
                    setState(() {
                      _testSpecialistId = 'created_host';
                    });
                  },
                ),

                const SizedBox(height: 12),

                if (_testSpecialistId != null) ...[
                  ElevatedButton.icon(
                    onPressed: _viewTestProfile,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Посмотреть профиль'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                OutlinedButton.icon(
                  onPressed: _clearTestData,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Очистить тестовые данные'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Инструкция:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('1. Создайте тестового специалиста'),
                      Text('2. Нажмите "Посмотреть профиль"'),
                      Text('3. Протестируйте все функции'),
                      Text('4. Проверьте на Android и веб-версии'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
