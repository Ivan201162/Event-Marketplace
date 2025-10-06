import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/gallery_item.dart';
import '../providers/auth_providers.dart';
import '../services/gallery_service.dart';

/// Диалог загрузки медиа в галерею
class UploadMediaDialog extends ConsumerStatefulWidget {
  const UploadMediaDialog({super.key});

  @override
  ConsumerState<UploadMediaDialog> createState() => _UploadMediaDialogState();
}

class _UploadMediaDialogState extends ConsumerState<UploadMediaDialog> {
  final GalleryService _galleryService = GalleryService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  XFile? _selectedFile;
  GalleryItemType? _selectedType = GalleryItemType.image;
  bool _isFeatured = false;
  bool _isUploading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Добавить в галерею'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Выбор типа медиа
                _buildMediaTypeSelector(),
                const SizedBox(height: 16),

                // Выбор файла
                _buildFileSelector(),
                const SizedBox(height: 16),

                // Поля формы
                if (_selectedFile != null) ...[
                  _buildFormFields(),
                  const SizedBox(height: 16),
                ],

                // Ошибка
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadMedia,
            child: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Загрузить'),
          ),
        ],
      );

  Widget _buildMediaTypeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Тип медиа',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<GalleryItemType>(
                  title: const Text('Изображение'),
                  value: GalleryItemType.image,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? GalleryItemType.image;
                      _selectedFile = null; // Сбрасываем выбранный файл
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<GalleryItemType>(
                  title: const Text('Видео'),
                  value: GalleryItemType.video,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? GalleryItemType.image;
                      _selectedFile = null; // Сбрасываем выбранный файл
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildFileSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите файл',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_selectedFile == null) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Камера'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedType == GalleryItemType.image
                        ? Icons.image
                        : Icons.video_library,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatFileSize(
                            File(_selectedFile!.path).lengthSync(),
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ],
        ],
      );

  Widget _buildFormFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Название *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите название';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Описание
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Описание',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Теги
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Теги (через запятую)',
              border: OutlineInputBorder(),
              hintText: 'свадьба, фотосессия, портрет',
            ),
          ),
          const SizedBox(height: 16),

          // Избранное
          CheckboxListTile(
            title: const Text('Добавить в избранное'),
            subtitle: const Text('Показывать в разделе избранных работ'),
            value: _isFeatured,
            onChanged: (value) {
              setState(() {
                _isFeatured = value ?? false;
              });
            },
          ),
        ],
      );

  Future<void> _pickFromGallery() async {
    try {
      final file = _selectedType == GalleryItemType.image
          ? await _galleryService.pickImage()
          : await _galleryService.pickVideo();

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка выбора файла: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = _selectedType == GalleryItemType.image
          ? await _galleryService.takePhoto()
          : await _galleryService.recordVideo();

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка создания файла: $e';
      });
    }
  }

  Future<void> _uploadMedia() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final currentUserAsync = ref.read(currentUserProvider);
      final currentUser = currentUserAsync.value;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (_selectedType == GalleryItemType.image) {
        await _galleryService.uploadImage(
          specialistId: currentUser.uid,
          imageFile: _selectedFile!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          tags: tags,
          isFeatured: _isFeatured,
        );
      } else {
        await _galleryService.uploadVideo(
          specialistId: currentUser.uid,
          videoFile: _selectedFile!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          tags: tags,
          isFeatured: _isFeatured,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Медиа успешно загружено в галерею'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isUploading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
