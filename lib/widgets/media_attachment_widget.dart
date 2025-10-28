import 'package:event_marketplace_app/services/media_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Виджет для прикрепления медиафайлов к сообщению
class MediaAttachmentWidget extends StatefulWidget {
  const MediaAttachmentWidget(
      {required this.onMediaSelected, required this.onError, super.key,});
  final Function(MediaUploadResult) onMediaSelected;
  final Function(String) onError;

  @override
  State<MediaAttachmentWidget> createState() => _MediaAttachmentWidgetState();
}

class _MediaAttachmentWidgetState extends State<MediaAttachmentWidget> {
  bool _isUploading = false;
  String? _uploadingFileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Прикрепить файл',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Progress indicator
          if (_isUploading) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Загрузка $_uploadingFileName...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Media options
          if (!_isUploading) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMediaOption(
                    icon: Icons.photo_camera,
                    label: 'Камера',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMediaOption(
                    icon: Icons.photo_library,
                    label: 'Галерея',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMediaOption(
                    icon: Icons.videocam,
                    label: 'Видео',
                    onTap: () => _pickVideo(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMediaOption(
                    icon: Icons.audiotrack,
                    label: 'Аудио',
                    onTap: _pickAudio,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMediaOption(
                    icon: Icons.description,
                    label: 'Документ',
                    onTap: _pickDocument,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMediaOption(
                    icon: Icons.attach_file,
                    label: 'Файл',
                    onTap: _pickFile,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  _isUploading ? null : () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadingFileName = 'Изображение';
      });

      final result = await MediaUploadService.pickAndUploadImage(
        chatId: 'test_chat', // TODO(developer): Получить реальный chatId
        userId: 'test_user', // TODO(developer): Получить реальный userId
        source: source,
      );

      if (result != null) {
        widget.onMediaSelected(result);
        Navigator.of(context).pop();
      } else {
        widget.onError('Не удалось загрузить изображение');
      }
    } catch (e) {
      widget.onError('Ошибка загрузки изображения: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingFileName = null;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadingFileName = 'Видео';
      });

      final result = await MediaUploadService.pickAndUploadVideo(
        chatId: 'test_chat', // TODO(developer): Получить реальный chatId
        userId: 'test_user', // TODO(developer): Получить реальный userId
        source: source,
      );

      if (result != null) {
        widget.onMediaSelected(result);
        Navigator.of(context).pop();
      } else {
        widget.onError('Не удалось загрузить видео');
      }
    } catch (e) {
      widget.onError('Ошибка загрузки видео: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingFileName = null;
      });
    }
  }

  Future<void> _pickAudio() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadingFileName = 'Аудиофайл';
      });

      final result = await MediaUploadService.pickAndUploadAudio(
        chatId: 'test_chat', // TODO(developer): Получить реальный chatId
        userId: 'test_user', // TODO(developer): Получить реальный userId
      );

      if (result != null) {
        widget.onMediaSelected(result);
        Navigator.of(context).pop();
      } else {
        widget.onError('Не удалось загрузить аудиофайл');
      }
    } catch (e) {
      widget.onError('Ошибка загрузки аудиофайла: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingFileName = null;
      });
    }
  }

  Future<void> _pickDocument() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadingFileName = 'Документ';
      });

      final result = await MediaUploadService.pickAndUploadDocument(
        chatId: 'test_chat', // TODO(developer): Получить реальный chatId
        userId: 'test_user', // TODO(developer): Получить реальный userId
      );

      if (result != null) {
        widget.onMediaSelected(result);
        Navigator.of(context).pop();
      } else {
        widget.onError('Не удалось загрузить документ');
      }
    } catch (e) {
      widget.onError('Ошибка загрузки документа: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingFileName = null;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadingFileName = 'Файл';
      });

      final result = await MediaUploadService.pickAndUploadFile(
        chatId: 'test_chat', // TODO(developer): Получить реальный chatId
        userId: 'test_user', // TODO(developer): Получить реальный userId
      );

      if (result != null) {
        widget.onMediaSelected(result);
        Navigator.of(context).pop();
      } else {
        widget.onError('Не удалось загрузить файл');
      }
    } catch (e) {
      widget.onError('Ошибка загрузки файла: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingFileName = null;
      });
    }
  }
}
