import 'dart:io';

import 'package:event_marketplace_app/models/event_idea.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/services/event_idea_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Диалог создания идеи мероприятия
class CreateIdeaDialog extends ConsumerStatefulWidget {
  const CreateIdeaDialog({super.key});

  @override
  ConsumerState<CreateIdeaDialog> createState() => _CreateIdeaDialogState();
}

class _CreateIdeaDialogState extends ConsumerState<CreateIdeaDialog> {
  final EventIdeaService _ideaService = EventIdeaService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();
  final _guestsController = TextEditingController();
  final _locationController = TextEditingController();

  final List<XFile> _selectedImages = [];
  String? _selectedCategory;
  bool _isUploading = false;
  String? _error;

  final List<String> _categories = [
    'Свадьба',
    'День рождения',
    'Корпоратив',
    'Детский праздник',
    'Выпускной',
    'Юбилей',
    'Новый год',
    'Другое',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    _guestsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Создать идею мероприятия'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название идеи *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите название идеи';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Описание
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите описание';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Категория
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((category) => DropdownMenuItem(
                            value: category, child: Text(category),),)
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Изображения
                  _buildImageSelector(),
                  const SizedBox(height: 16),

                  // Дополнительные поля
                  _buildAdditionalFields(),
                  const SizedBox(height: 16),

                  // Теги
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Теги (через запятую)',
                      border: OutlineInputBorder(),
                      hintText: 'свадьба, романтично, лето',
                    ),
                  ),
                  const SizedBox(height: 16),

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
                            child: Text(_error!,
                                style: TextStyle(color: Colors.red[600]),),
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
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _isUploading ? null : _createIdea,
            child: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Создать'),
          ),
        ],
      );

  Widget _buildImageSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Изображения',
              style: TextStyle(fontWeight: FontWeight.bold),),
          const SizedBox(height: 8),
          if (_selectedImages.isEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
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
            // Превью изображений
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  final image = _selectedImages[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(image.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 12,),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Добавить'),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedImages.length}/5',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      );

  Widget _buildAdditionalFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Дополнительная информация',
              style: TextStyle(fontWeight: FontWeight.bold),),
          const SizedBox(height: 8),
          Row(
            children: [
              // Бюджет
              Expanded(
                child: TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Бюджет (₽)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),

              // Длительность
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Длительность (ч)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Количество гостей
              Expanded(
                child: TextFormField(
                  controller: _guestsController,
                  decoration: const InputDecoration(
                    labelText: 'Гости (чел)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),

              // Местоположение
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                      labelText: 'Место', border: OutlineInputBorder(),),
                ),
              ),
            ],
          ),
        ],
      );

  Future<void> _pickImages() async {
    try {
      final images =
          await _ideaService.pickImages(maxImages: 5 - _selectedImages.length);
      setState(() {
        _selectedImages.addAll(images);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка выбора изображений: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _ideaService.takePhoto();
      if (photo != null && _selectedImages.length < 5) {
        setState(() {
          _selectedImages.add(photo);
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка создания фото: $e';
      });
    }
  }

  Future<void> _createIdea() async {
    if (!_formKey.currentState!.validate()) {
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

      // Загружаем изображения
      var imageUrls = <String>[];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _ideaService.uploadIdeaImages(
          authorId: currentUser.uid,
          imageFiles: _selectedImages,
        );
      }

      // Парсим теги
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Парсим дополнительные поля
      double? budget;
      if (_budgetController.text.isNotEmpty) {
        budget = double.tryParse(_budgetController.text);
      }

      int? duration;
      if (_durationController.text.isNotEmpty) {
        duration = int.tryParse(_durationController.text);
      }

      int? guests;
      if (_guestsController.text.isNotEmpty) {
        guests = int.tryParse(_guestsController.text);
      }

      // Создаем идею
      final createIdea = CreateEventIdea(
        authorId: currentUser.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        images: imageUrls,
        authorName: currentUser.displayName,
        authorAvatar: currentUser.photoURL,
        tags: tags,
        category: _selectedCategory,
        budget: budget,
        duration: duration,
        guests: guests,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      await _ideaService.createIdea(createIdea);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Идея создана'), backgroundColor: Colors.green,),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isUploading = false;
      });
    }
  }
}
