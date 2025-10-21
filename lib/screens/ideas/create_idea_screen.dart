import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/idea.dart';
import '../../providers/auth_providers.dart';
import '../../providers/ideas_providers.dart';
import '../../widgets/loading_overlay.dart';

/// Screen for creating a new idea
class CreateIdeaScreen extends ConsumerStatefulWidget {
  const CreateIdeaScreen({super.key});

  @override
  ConsumerState<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends ConsumerState<CreateIdeaScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailedDescriptionController = TextEditingController();
  final _materialsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  File? _selectedImage;
  String? _selectedCategory;
  String? _selectedDifficulty;
  int? _estimatedDuration;
  bool _isLoading = false;

  final List<String> _categories = [
    'День рождения',
    'Свадьба',
    'Корпоратив',
    'Детский праздник',
    'Выпускной',
    'Новый год',
    'Хэллоуин',
    '8 марта',
    '23 февраля',
    'Другое',
  ];

  final List<String> _difficulties = [
    'easy',
    'medium',
    'hard',
  ];

  final List<int> _durations = [
    30, 60, 90, 120, 180, 240, 300, 360, 480, 600,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _detailedDescriptionController.dispose();
    _materialsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать идею'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publishIdea,
            child: Text(
              'Опубликовать',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                if (currentUser != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: currentUser.photoURL != null
                            ? NetworkImage(currentUser.photoURL!)
                            : null,
                        child: currentUser.photoURL == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.displayName ?? 'Пользователь',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Поделитесь креативной идеей',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название идеи *',
                    hintText: 'Краткое и привлекательное название',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название идеи';
                    }
                    if (value.trim().length < 3) {
                      return 'Название должно содержать минимум 3 символа';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Short description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Краткое описание *',
                    hintText: 'Краткое описание идеи (1-2 предложения)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите описание идеи';
                    }
                    if (value.trim().length < 10) {
                      return 'Описание должно содержать минимум 10 символов';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category
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
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Выберите категорию';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Difficulty and Duration
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDifficulty,
                        decoration: const InputDecoration(
                          labelText: 'Сложность',
                          border: OutlineInputBorder(),
                        ),
                        items: _difficulties.map((difficulty) {
                          String label;
                          switch (difficulty) {
                            case 'easy':
                              label = 'Легко';
                              break;
                            case 'medium':
                              label = 'Средне';
                              break;
                            case 'hard':
                              label = 'Сложно';
                              break;
                            default:
                              label = difficulty;
                          }
                          return DropdownMenuItem(
                            value: difficulty,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDifficulty = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _estimatedDuration,
                        decoration: const InputDecoration(
                          labelText: 'Время (мин)',
                          border: OutlineInputBorder(),
                        ),
                        items: _durations.map((duration) {
                          final hours = duration ~/ 60;
                          final minutes = duration % 60;
                          String label;
                          if (hours > 0 && minutes > 0) {
                            label = '${hours}ч ${minutes}м';
                          } else if (hours > 0) {
                            label = '${hours}ч';
                          } else {
                            label = '${minutes}м';
                          }
                          return DropdownMenuItem(
                            value: duration,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _estimatedDuration = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Detailed description
                TextFormField(
                  controller: _detailedDescriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Подробное описание',
                    hintText: 'Детальное описание идеи, инструкции по реализации',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Required materials
                TextFormField(
                  controller: _materialsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Необходимые материалы',
                    hintText: 'Список материалов через запятую',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Tags
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Теги',
                    hintText: 'Теги через запятую (например: #свадьба, #декор)',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Image preview
                if (_selectedImage != null) ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Добавить фото'),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _removeImage,
                          icon: const Icon(Icons.delete),
                          label: const Text('Удалить'),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // Guidelines
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Советы для создания идеи',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Опишите идею максимально подробно\n'
                        '• Укажите необходимые материалы и время\n'
                        '• Добавьте фото для лучшего понимания\n'
                        '• Используйте теги для категоризации',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора изображения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _publishIdea() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Войдите в аккаунт для публикации идей'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ideaService = ref.read(ideaServiceProvider);
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        // In a real app, you would upload to Firebase Storage here
        // For now, we'll just use a placeholder
        imageUrl = 'https://via.placeholder.com/400x300?text=Idea+Image';
      }

      // Parse materials and tags
      final materials = _materialsController.text.trim().isEmpty
          ? <String>[]
          : _materialsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      final tags = _tagsController.text.trim().isEmpty
          ? <String>[]
          : _tagsController.text
              .split(',')
              .map((e) => e.trim().replaceAll('#', ''))
              .where((e) => e.isNotEmpty)
              .toList();

      // Create idea
      final ideaId = await ideaService.createIdea(
        title: _titleController.text.trim(),
        shortDesc: _descriptionController.text.trim(),
        mediaUrl: imageUrl,
        authorId: currentUser.uid,
        authorName: currentUser.displayName,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        estimatedDuration: _estimatedDuration,
        requiredMaterials: materials,
        detailedDescription: _detailedDescriptionController.text.trim().isEmpty
            ? null
            : _detailedDescriptionController.text.trim(),
        tags: tags,
      );

      if (ideaId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Идея успешно опубликована!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        throw Exception('Не удалось создать идею');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка публикации: $e'),
            backgroundColor: Colors.red,
          ),
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
