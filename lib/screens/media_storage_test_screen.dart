import 'package:flutter/material.dart';

import '../widgets/media_gallery_widget.dart';
import '../widgets/media_upload_widget.dart';

/// Тестовый экран для проверки функциональности хранения медиафайлов
class MediaStorageTestScreen extends StatefulWidget {
  const MediaStorageTestScreen({super.key});

  @override
  State<MediaStorageTestScreen> createState() => _MediaStorageTestScreenState();
}

class _MediaStorageTestScreenState extends State<MediaStorageTestScreen> {
  final String _testBookingId = 'test_booking_123';
  final String _testSpecialistId = 'test_specialist_456';

  bool _showUploadWidget = true;
  bool _showGalleryWidget = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тест хранения медиафайлов'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildTestInfo(),
              const SizedBox(height: 16),
              _buildToggleButtons(),
              const SizedBox(height: 16),
              if (_showUploadWidget) _buildUploadSection(),
              if (_showGalleryWidget) _buildGallerySection(),
            ],
          ),
        ),
      );

  Widget _buildTestInfo() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Информация о тесте',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Booking ID: $_testBookingId',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Specialist ID: $_testSpecialistId',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Этот экран позволяет протестировать функциональность загрузки и просмотра медиафайлов мероприятий.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildToggleButtons() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showUploadWidget = !_showUploadWidget),
                icon: Icon(
                  _showUploadWidget ? Icons.visibility_off : Icons.visibility,
                ),
                label: Text(
                  _showUploadWidget ? 'Скрыть загрузку' : 'Показать загрузку',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showUploadWidget ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showGalleryWidget = !_showGalleryWidget),
                icon: Icon(
                  _showGalleryWidget ? Icons.visibility_off : Icons.visibility,
                ),
                label: Text(
                  _showGalleryWidget ? 'Скрыть галерею' : 'Показать галерею',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showGalleryWidget ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildUploadSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_upload, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Виджет загрузки медиафайлов',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          MediaUploadWidget(
            bookingId: _testBookingId,
            specialistId: _testSpecialistId,
            onUploadComplete: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Загрузка завершена!'),
                  backgroundColor: Colors.green,
                ),
              );
              // Обновляем галерею
              setState(() {});
            },
            onUploadError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка загрузки: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ],
      );

  Widget _buildGallerySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.photo_library, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Виджет галереи медиафайлов',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          MediaGalleryWidget(
            bookingId: _testBookingId,
            specialistId: _testSpecialistId,
          ),
        ],
      );
}
