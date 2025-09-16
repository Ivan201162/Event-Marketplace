import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/idea.dart';
import '../services/idea_service.dart';

/// Экран создания идеи
class CreateIdeaScreen extends ConsumerStatefulWidget {
  final String userId;

  const CreateIdeaScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends ConsumerState<CreateIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  final IdeaService _ideaService = IdeaService();

  String _selectedCategory = 'Декор';
  IdeaType _selectedType = IdeaType.general;
  List<IdeaImage> _images = [];
  List<String> _tags = [];
  bool _isPublic = true;
  bool _isLoading = false;

  final List<String> _categories = [
    'Декор',
    'Еда',
    'Развлечения',
    'Фото',
    'Музыка',
    'Одежда',
    'Подарки',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать идею'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveIdea,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              _buildBasicInfoSection(),

              const SizedBox(height: 24),

              // Категория и тип
              _buildCategoryAndTypeSection(),

              const SizedBox(height: 24),

              // Изображения
              _buildImagesSection(),

              const SizedBox(height: 24),

              // Теги
              _buildTagsSection(),

              const SizedBox(height: 24),

              // Настройки
              _buildSettingsSection(),

              const SizedBox(height: 24),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveIdea,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Создать идею'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Основная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Заголовок
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название идеи *',
                border: OutlineInputBorder(),
                hintText: 'Введите название идеи',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пожалуйста, введите название идеи';
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
                hintText: 'Опишите вашу идею подробно',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пожалуйста, введите описание идеи';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAndTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Категория и тип',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Категория
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Категория *',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'Декор';
                });
              },
            ),

            const SizedBox(height: 16),

            // Тип идеи
            DropdownButtonFormField<IdeaType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Тип идеи',
                border: OutlineInputBorder(),
              ),
              items: IdeaType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeText(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value ?? IdeaType.general;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Изображения',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_images.length}/10',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Кнопки добавления изображений
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _images.length < 10 ? _pickImages : null,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _images.length < 10 ? _takePhoto : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Камера'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Список изображений
            if (_images.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final image = _images[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              image.url,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Теги',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Поле ввода тегов
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                hintText: 'Добавить тег...',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.add),
              ),
              onFieldSubmitted: _addTag,
            ),

            const SizedBox(height: 16),

            // Список тегов
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 8),

            // Предустановленные теги
            const Text(
              'Популярные теги:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'красиво',
                'стильно',
                'оригинально',
                'просто',
                'быстро',
                'дешево',
                'дорого',
                'элегантно',
                'весело',
                'романтично',
              ].map((tag) {
                return ActionChip(
                  label: Text(tag),
                  onPressed: () => _addTag(tag),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Публичная идея
            SwitchListTile(
              title: const Text('Публичная идея'),
              subtitle: const Text('Идея будет видна всем пользователям'),
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
    );
  }

  Future<void> _pickImages() async {
    try {
      final images =
          await _ideaService.pickImages(maxImages: 10 - _images.length);
      for (final image in images) {
        final ideaImage = await _ideaService.uploadIdeaImage(image);
        if (ideaImage != null) {
          setState(() {
            _images.add(ideaImage);
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора изображений: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _ideaService.takePhoto();
      if (image != null) {
        final ideaImage = await _ideaService.uploadIdeaImage(image);
        if (ideaImage != null) {
          setState(() {
            _images.add(ideaImage);
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка съемки фото: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveIdea() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ideaId = await _ideaService.createIdea(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        authorId: widget.userId,
        authorName: 'Демо Пользователь', // TODO: Получить из контекста
        tags: _tags,
        type: _selectedType,
        images: _images,
        isPublic: _isPublic,
      );

      if (ideaId != null) {
        Navigator.pop(context, true);
        _showSuccessSnackBar('Идея успешно создана');
      } else {
        _showErrorSnackBar('Ошибка создания идеи');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTypeText(IdeaType type) {
    switch (type) {
      case IdeaType.general:
        return 'Общие';
      case IdeaType.wedding:
        return 'Свадьба';
      case IdeaType.birthday:
        return 'День рождения';
      case IdeaType.corporate:
        return 'Корпоратив';
      case IdeaType.holiday:
        return 'Праздник';
      case IdeaType.other:
        return 'Другое';
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
