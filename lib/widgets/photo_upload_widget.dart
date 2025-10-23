import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/customer_profile_extended_providers.dart';

/// Виджет загрузки фото
class PhotoUploadWidget extends ConsumerStatefulWidget {
  const PhotoUploadWidget(
      {super.key, required this.userId, required this.onPhotoAdded});
  final String userId;
  final VoidCallback onPhotoAdded;

  @override
  ConsumerState<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends ConsumerState<PhotoUploadWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final List<String> _tags = [];
  bool _isPublic = false;
  bool _isUploading = false;
  File? _selectedImage;

  @override
  void dispose() {
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              AppBar(
                title: const Text('Добавить фото'),
                actions: [
                  if (_selectedImage != null)
                    TextButton(
                      onPressed: _isUploading ? null : _uploadPhoto,
                      child: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Загрузить'),
                    ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Выбор изображения
                      _buildImageSelector(),
                      const SizedBox(height: 16),

                      // Превью изображения
                      if (_selectedImage != null) ...[
                        _buildImagePreview(),
                        const SizedBox(height: 16)
                      ],

                      // Подпись
                      TextField(
                        controller: _captionController,
                        decoration: const InputDecoration(
                          labelText: 'Подпись (необязательно)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Теги
                      _buildTagsSection(),
                      const SizedBox(height: 16),

                      // Публичность
                      SwitchListTile(
                        title: const Text('Публичное фото'),
                        subtitle: const Text(
                            'Другие пользователи смогут видеть это фото'),
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildImageSelector() => Card(
        child: InkWell(
          onTap: _selectImage,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedImage == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Нажмите для выбора фото',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 48, color: Colors.green),
                      SizedBox(height: 8),
                      Text('Фото выбрано',
                          style: TextStyle(color: Colors.green)),
                    ],
                  ),
          ),
        ),
      );

  Widget _buildImagePreview() => Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        ),
      );

  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Теги',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Поле ввода тегов
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    hintText: 'Введите тег и нажмите Enter',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _addTag,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                  onPressed: () => _addTag(_tagsController.text),
                  icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 8),

          // Список тегов
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(tag),
                    ),
                  )
                  .toList(),
            ),
        ],
      );

  Future<void> _selectImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(content: Text('Ошибка выбора изображения: $e')));
      }
    }
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final service = ref.read(customerProfileExtendedServiceProvider);

      final photo = await service.addInspirationPhoto(
        userId: widget.userId,
        imageFile: _selectedImage!,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        tags: _tags,
        isPublic: _isPublic,
      );

      if (photo != null) {
        if (mounted) {
          Navigator.pop(context);
          widget.onPhotoAdded();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
              const SnackBar(content: Text('Фото успешно загружено')));
        }
      } else {
        throw Exception('Не удалось загрузить фото');
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
