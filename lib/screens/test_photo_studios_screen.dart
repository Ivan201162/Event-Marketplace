import 'package:flutter/material.dart';

import '../models/photo_studio.dart';
import '../services/photo_studio_service.dart';
import '../services/test_photo_studio_data.dart';
import '../widgets/photo_studio_card.dart';

class TestPhotoStudiosScreen extends StatefulWidget {
  const TestPhotoStudiosScreen({super.key});

  @override
  State<TestPhotoStudiosScreen> createState() => _TestPhotoStudiosScreenState();
}

class _TestPhotoStudiosScreenState extends State<TestPhotoStudiosScreen> {
  final PhotoStudioService _photoStudioService = PhotoStudioService();
  List<PhotoStudio> _photoStudios = [];
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPhotoStudios();
  }

  Future<void> _loadPhotoStudios() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Загрузка фотостудий...';
    });

    try {
      final photoStudios = await _photoStudioService.getAllPhotoStudios();
      setState(() {
        _photoStudios = photoStudios;
        _isLoading = false;
        _statusMessage = 'Найдено фотостудий: ${photoStudios.length}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка загрузки: $e';
      });
    }
  }

  Future<void> _createTestData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Создание тестовых данных...';
    });

    try {
      await TestPhotoStudioData.createTestPhotoStudios();
      await _loadPhotoStudios();
      setState(() {
        _statusMessage = 'Тестовые данные созданы успешно!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка создания тестовых данных: $e';
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Очистка тестовых данных...';
    });

    try {
      await TestPhotoStudioData.clearTestPhotoStudios();
      await _loadPhotoStudios();
      setState(() {
        _statusMessage = 'Тестовые данные очищены!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Ошибка очистки тестовых данных: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест фотостудий'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotoStudios,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Control panel
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createTestData,
                        icon: const Icon(Icons.add),
                        label: const Text('Создать тестовые данные'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _clearTestData,
                        icon: const Icon(Icons.clear),
                        label: const Text('Очистить данные'),
                        style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Загрузка...')],
        ),
      );
    }

    if (_photoStudios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Фотостудии не найдены', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Создайте тестовые данные для проверки функционала',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _photoStudios.length,
      itemBuilder: (context, index) {
        final photoStudio = _photoStudios[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PhotoStudioCard(
            photoStudio: photoStudio,
            onTap: () => _showPhotoStudioDetails(photoStudio),
          ),
        );
      },
    );
  }

  void _showPhotoStudioDetails(PhotoStudio photoStudio) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(photoStudio.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Описание: ${photoStudio.description}'),
              const SizedBox(height: 8),
              Text('Цена: ${photoStudio.pricePerHour} ₽/час'),
              const SizedBox(height: 8),
              Text('Рейтинг: ${photoStudio.rating}'),
              const SizedBox(height: 8),
              Text('Телефон: ${photoStudio.phone}'),
              const SizedBox(height: 8),
              Text('Email: ${photoStudio.email}'),
              const SizedBox(height: 8),
              Text('Адрес: ${photoStudio.address}'),
              const SizedBox(height: 8),
              Text('Проверено: ${photoStudio.isVerified ? "Да" : "Нет"}'),
              const SizedBox(height: 8),
              Text('Фотографий: ${photoStudio.photos.length}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть')),
        ],
      ),
    );
  }
}
