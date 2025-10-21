import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../services/supabase_service.dart';

/// Экран создания идеи/поста
class CreateIdeaScreen extends ConsumerStatefulWidget {
  const CreateIdeaScreen({super.key});

  @override
  ConsumerState<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends ConsumerState<CreateIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  String _selectedType = 'text';
  String? _selectedCategory;
  List<File> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _types = ['text', 'photo', 'video', 'reel'];

  final List<String> _categories = [
    'Фотография',
    'Видеосъемка',
    'Декор',
    'Кейтеринг',
    'Музыка',
    'Анимация',
    'Другое',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
        _selectedType = 'photo';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выбора изображений: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        setState(() {
          _selectedImages = [File(video.path)];
          _selectedType = 'video';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выбора видео: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _createIdea() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Загрузить медиа файлы в Supabase Storage
      final mediaUrls = <String>[];

      final idea = await SupabaseService.createIdea(
        type: _selectedType,
        content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
        mediaUrls: mediaUrls,
        category: _selectedCategory,
      );

      if (idea != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Идея создана успешно!'), backgroundColor: Colors.green),
        );
        context.pop();
      } else {
        throw Exception('Не удалось создать идею');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания идеи: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать идею'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createIdea,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Опубликовать', style: TextStyle(color: Colors.white)),
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
              // Тип контента
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Категория
              _buildCategorySelector(),
              const SizedBox(height: 24),

              // Контент
              _buildContentField(),
              const SizedBox(height: 24),

              // Медиа
              _buildMediaSection(),
              const SizedBox(height: 24),

              // Предварительный просмотр
              if (_selectedImages.isNotEmpty) _buildMediaPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Тип контента', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _types.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(_getTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = type;
                  if (type != 'photo' && type != 'video') {
                    _selectedImages.clear();
                  }
                });
              },
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: theme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Категория', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Выберите категорию',
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Описание', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contentController,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Расскажите о вашей идее...',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              if (_selectedType == 'text' && _selectedImages.isEmpty) {
                return 'Введите описание или добавьте медиа';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Медиа', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Фото'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Видео'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Предварительный просмотр',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final file = _selectedImages[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Image.file(
                        file,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Текст';
      case 'photo':
        return 'Фото';
      case 'video':
        return 'Видео';
      case 'reel':
        return 'Рилс';
      default:
        return type;
    }
  }
}
