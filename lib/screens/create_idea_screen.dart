import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/enhanced_idea.dart';
import '../providers/enhanced_ideas_providers.dart';
import '../providers/auth_providers.dart';

/// Экран создания новой идеи/публикации
class CreateIdeaScreen extends ConsumerStatefulWidget {
  const CreateIdeaScreen({super.key});

  @override
  ConsumerState<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends ConsumerState<CreateIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  
  String _selectedType = 'image';
  List<XFile> _selectedMedia = [];
  bool _isLoading = false;

  final List<String> _ideaTypes = [
    'image',
    'video',
    'post',
    'reels',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать публикацию'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publishIdea,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Опубликовать'),
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
              // Выбор типа публикации
              _buildTypeSelector(),
              const SizedBox(height: 20),

              // Заголовок
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  hintText: 'Введите заголовок публикации',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите заголовок';
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
                  hintText: 'Опишите вашу идею...',
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

              // Бюджет (опционально)
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Бюджет (₽)',
                  hintText: 'Укажите примерный бюджет',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Медиа
              _buildMediaSection(),
              const SizedBox(height: 20),

              // Кнопка публикации
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publishIdea,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Публикуем...'),
                          ],
                        )
                      : const Text('Опубликовать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Тип публикации',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                'image',
                'Фото',
                Icons.photo_library,
                _selectedType == 'image',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTypeOption(
                'video',
                'Видео',
                Icons.video_library,
                _selectedType == 'video',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                'post',
                'Пост',
                Icons.article,
                _selectedType == 'post',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTypeOption(
                'reels',
                'Рилс',
                Icons.movie,
                _selectedType == 'reels',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(String type, String title, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedMedia.clear(); // Очищаем медиа при смене типа
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).iconTheme.color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Медиа файлы',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            TextButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_selectedMedia.isEmpty)
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                style: BorderStyle.solid,
              ),
            ),
            child: InkWell(
              onTap: _pickMedia,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getMediaIcon(),
                    size: 48,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите для добавления ${_getMediaText()}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedMedia.length,
              itemBuilder: (context, index) {
                final media = _selectedMedia[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          File(media.path),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMedia.removeAt(index);
                              });
                            },
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
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getMediaIcon() {
    switch (_selectedType) {
      case 'image':
        return Icons.photo_library;
      case 'video':
        return Icons.video_library;
      case 'post':
        return Icons.article;
      case 'reels':
        return Icons.movie;
      default:
        return Icons.photo_library;
    }
  }

  String _getMediaText() {
    switch (_selectedType) {
      case 'image':
        return 'фото';
      case 'video':
        return 'видео';
      case 'post':
        return 'фото для поста';
      case 'reels':
        return 'видео для рилса';
      default:
        return 'медиа';
    }
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      if (_selectedType == 'image' || _selectedType == 'post') {
        final List<XFile> images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _selectedMedia.addAll(images);
          });
        }
      } else if (_selectedType == 'video' || _selectedType == 'reels') {
        final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          setState(() {
            _selectedMedia = [video];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе медиа: $e')),
        );
      }
    }
  }

  Future<void> _publishIdea() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один медиа файл')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем данные текущего пользователя
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходимо войти в систему')),
        );
        return;
      }

      // Создаем новую идею
      final newIdea = EnhancedIdea(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: IdeaType.fromString(_selectedType),
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Пользователь',
        media: _selectedMedia.map((file) => IdeaMedia(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: file.path, // В реальном приложении здесь будет URL загруженного файла
          type: IdeaMediaType.fromString(_selectedType),
          width: 0,
          height: 0,
        )).toList(),
        budget: _budgetController.text.isNotEmpty 
            ? int.tryParse(_budgetController.text)?.toDouble()
            : null,
        likesCount: 0,
        commentsCount: 0,
        isLiked: false,
        isSaved: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Добавляем идею через провайдер
      ref.read(enhancedIdeasProvider).addIdea(newIdea);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Публикация успешно создана!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при создании публикации: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}