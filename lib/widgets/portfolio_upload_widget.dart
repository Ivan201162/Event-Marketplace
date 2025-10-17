import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist_profile.dart';
import '../providers/portfolio_providers.dart';

/// Виджет для загрузки портфолио
class PortfolioUploadWidget extends ConsumerStatefulWidget {
  const PortfolioUploadWidget({
    super.key,
    required this.userId,
    this.onUploaded,
  });

  final String userId;
  final VoidCallback? onUploaded;

  @override
  ConsumerState<PortfolioUploadWidget> createState() => _PortfolioUploadWidgetState();
}

class _PortfolioUploadWidgetState extends ConsumerState<PortfolioUploadWidget> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch<PortfolioUploadState>(portfolioUploadStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Загрузка портфолио',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (uploadState.isUploading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Кнопки выбора типа файла
            _buildUploadButtons(),
            const SizedBox(height: 16),

            // Поля для описания
            if (uploadState.isUploading) ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Введите название работы',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Описание работы (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
            ],

            // Прогресс загрузки
            if (uploadState.isUploading) ...[
              LinearProgressIndicator(
                value: uploadState.uploadProgress as double?,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Загрузка... ${(uploadState.uploadProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],

            // Ошибка
            if (uploadState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        uploadState.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        ref
                            .read<PortfolioUploadNotifier>(portfolioUploadStateProvider.notifier)
                            .clearError();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Загруженные элементы
            if (uploadState.uploadedItems.isNotEmpty) ...[
              Text(
                'Загружено:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...uploadState.uploadedItems.map(_buildUploadedItem),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButtons() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildUploadButton(
            icon: Icons.photo,
            label: 'Фото',
            onPressed: _showImagePicker,
          ),
          _buildUploadButton(
            icon: Icons.videocam,
            label: 'Видео',
            onPressed: _showVideoPicker,
          ),
          _buildUploadButton(
            icon: Icons.description,
            label: 'Документ',
            onPressed: _showFilePicker,
          ),
        ],
      );

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) =>
      ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );

  Widget _buildUploadedItem(PortfolioItem item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            Icon(
              _getItemIcon(item.type),
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? 'Без названия',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                ref
                    .read<PortfolioUploadNotifier>(portfolioUploadStateProvider.notifier)
                    .removePortfolioItem(
                      widget.userId,
                      item.id,
                    );
              },
            ),
          ],
        ),
      );

  IconData _getItemIcon(String type) {
    switch (type) {
      case 'photo':
        return Icons.photo;
      case 'video':
        return Icons.videocam;
      case 'document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showImagePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                _takePhotoWithCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickVideoFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilePicker() {
    _pickFile();
  }

  Future<void> _pickImageFromGallery() async {
    final file = await ref.read<Future<File?>>(pickImageFromGalleryProvider.future);
    if (file != null) {
      await _uploadImage(file);
    }
  }

  Future<void> _takePhotoWithCamera() async {
    final file = await ref.read<Future<File?>>(takePhotoWithCameraProvider.future);
    if (file != null) {
      await _uploadImage(file);
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final file = await ref.read<Future<File?>>(pickVideoFromGalleryProvider.future);
    if (file != null) {
      await _uploadVideo(file);
    }
  }

  Future<void> _pickFile() async {
    final file = await ref.read<Future<File?>>(pickFileProvider.future);
    if (file != null) {
      await _uploadDocument(file);
    }
  }

  Future<void> _uploadImage(File file) async {
    await ref.read<PortfolioUploadNotifier>(portfolioUploadStateProvider.notifier).uploadImage(
          userId: widget.userId,
          imageFile: file,
          title: _titleController.text.isNotEmpty ? _titleController.text : null,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        );

    _clearFields();
    widget.onUploaded?.call();
  }

  Future<void> _uploadVideo(File file) async {
    await ref.read<PortfolioUploadNotifier>(portfolioUploadStateProvider.notifier).uploadVideo(
          userId: widget.userId,
          videoFile: file,
          title: _titleController.text.isNotEmpty ? _titleController.text : null,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        );

    _clearFields();
    widget.onUploaded?.call();
  }

  Future<void> _uploadDocument(File file) async {
    await ref.read<PortfolioUploadNotifier>(portfolioUploadStateProvider.notifier).uploadDocument(
          userId: widget.userId,
          documentFile: file,
          title: _titleController.text.isNotEmpty ? _titleController.text : null,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        );

    _clearFields();
    widget.onUploaded?.call();
  }

  void _clearFields() {
    _titleController.clear();
    _descriptionController.clear();
  }
}
