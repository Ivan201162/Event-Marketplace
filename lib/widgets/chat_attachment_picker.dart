import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/media_upload_service.dart';

/// Виджет для выбора и прикрепления файлов в чате
class ChatAttachmentPicker extends StatelessWidget {
  const ChatAttachmentPicker({
    super.key,
    required this.onFileSelected,
    required this.onImageSelected,
    required this.onVideoSelected,
    required this.onDocumentSelected,
    required this.onAudioSelected,
  });

  final Function(MediaUploadResult) onFileSelected;
  final Function(MediaUploadResult) onImageSelected;
  final Function(MediaUploadResult) onVideoSelected;
  final Function(MediaUploadResult) onDocumentSelected;
  final Function(MediaUploadResult) onAudioSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 200,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      children: [
        // Ручка для перетаскивания
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Заголовок
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Прикрепить файл',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // Опции прикрепления
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildAttachmentOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'Фото',
                  color: Colors.blue,
                  onTap: () => _pickImage(context),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.videocam,
                  label: 'Видео',
                  color: Colors.red,
                  onTap: () => _pickVideo(context),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.audiotrack,
                  label: 'Аудио',
                  color: Colors.green,
                  onTap: () => _pickAudio(context),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.description,
                  label: 'Документ',
                  color: Colors.orange,
                  onTap: () => _pickDocument(context),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Камера',
                  color: Colors.purple,
                  onTap: () => _takePhoto(context),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.videocam_outlined,
                  label: 'Запись',
                  color: Colors.teal,
                  onTap: () => _recordVideo(context),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.attach_file,
                  label: 'Файл',
                  color: Colors.grey,
                  onTap: () => _pickFile(context),
                ),
                _buildAttachmentOption(
                  context,
                  icon: Icons.location_on,
                  label: 'Местоположение',
                  color: Colors.brown,
                  onTap: () => _shareLocation(context),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Future<void> _pickImage(BuildContext context) async {
    try {
      final result = await MediaUploadService.pickAndUploadImage(
        chatId: 'temp_chat', // Будет заменен на реальный ID
        userId: 'temp_user', // Будет заменен на реальный ID
      );

      if (result != null) {
        onImageSelected(result);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Ошибка выбора изображения: $e');
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final result = await MediaUploadService.pickAndUploadVideo(
        chatId: 'temp_chat', // Будет заменен на реальный ID
        userId: 'temp_user', // Будет заменен на реальный ID
      );

      if (result != null) {
        onVideoSelected(result);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Ошибка выбора видео: $e');
    }
  }

  Future<void> _pickAudio(BuildContext context) async {
    try {
      final result = await MediaUploadService.pickAndUploadAudio(
        chatId: 'temp_chat', // Будет заменен на реальный ID
        userId: 'temp_user', // Будет заменен на реальный ID
      );

      if (result != null) {
        onAudioSelected(result);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Ошибка выбора аудио: $e');
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    try {
      final result = await MediaUploadService.pickAndUploadDocument(
        chatId: 'temp_chat', // Будет заменен на реальный ID
        userId: 'temp_user', // Будет заменен на реальный ID
      );

      if (result != null) {
        onDocumentSelected(result);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Ошибка выбора документа: $e');
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    try {
      final result = await MediaUploadService.pickAndUploadImage(
        chatId: 'temp_chat', // Будет заменен на реальный ID
        userId: 'temp_user', // Будет заменен на реальный ID
        source: ImageSource.camera,
      );

      if (result != null) {
        onImageSelected(result);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Ошибка съемки фото: $e');
    }
  }

  Future<void> _recordVideo(BuildContext context) async {
    try {
      final result = await MediaUploadService.pickAndUploadVideo(
        chatId: 'temp_chat', // Будет заменен на реальный ID
        userId: 'temp_user', // Будет заменен на реальный ID
        source: ImageSource.camera,
      );

      if (result != null) {
        onVideoSelected(result);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Ошибка записи видео: $e');
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await MediaUploadService.pickAndUploadFile(
        chatId: 'temp_chat', // Будет заменен на реальный ID
        userId: 'temp_user', // Будет заменен на реальный ID
      );

      if (result != null) {
        onFileSelected(result);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Ошибка выбора файла: $e');
    }
  }

  Future<void> _shareLocation(BuildContext context) async {
    // TODO(developer): Реализовать выбор местоположения
    _showErrorSnackBar(context, 'Функция местоположения пока не реализована');
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}

/// Виджет для отображения прогресса загрузки файла
class FileUploadProgressWidget extends StatelessWidget {
  const FileUploadProgressWidget({
    super.key,
    required this.fileName,
    required this.progress,
    this.onCancel,
  });

  final String fileName;
  final double progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onCancel != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onCancel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    ),
  );
}
