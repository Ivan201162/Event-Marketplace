import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/storage_service.dart';
import '../../widgets/ui_kit/ui_kit.dart';

/// Экран создания идеи
class CreateIdeaScreen extends ConsumerStatefulWidget {
  const CreateIdeaScreen({super.key});

  @override
  ConsumerState<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends ConsumerState<CreateIdeaScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  List<File> _selectedImages = [];
  List<File> _selectedVideos = [];
  bool _isLoading = false;
  bool _isVideo = false;
  
  final List<String> _popularTags = [
    'Свадьба',
    'День рождения',
    'Корпоратив',
    'Детский праздник',
    'Выпускной',
    'Юбилей',
    'Новый год',
    '8 марта',
    '23 февраля',
    'Другое',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
        _isVideo = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    
    if (video != null) {
      setState(() {
        _selectedVideos = [File(video.path)];
        _selectedImages.clear();
        _isVideo = true;
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _removeVideo(int index) async {
    setState(() {
      _selectedVideos.removeAt(index);
      _isVideo = false;
    });
  }

  Future<void> _createIdea() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Пользователь не авторизован');
        return;
      }

      // Загружаем медиа в Storage
      List<String> mediaUrls = [];
      final storageService = StorageService();
      
      if (_isVideo && _selectedVideos.isNotEmpty) {
        // Загружаем видео
        for (int i = 0; i < _selectedVideos.length; i++) {
          final videoUrl = await storageService.uploadIdeaVideo(
            user.uid, 
            _selectedVideos[i], 
            'idea_video_${DateTime.now().millisecondsSinceEpoch}_$i'
          );
          if (videoUrl != null) {
            mediaUrls.add(videoUrl);
          }
        }
      } else {
        // Загружаем изображения
        for (int i = 0; i < _selectedImages.length; i++) {
          final imageUrl = await storageService.uploadIdeaImage(
            user.uid, 
            _selectedImages[i], 
            'idea_image_${DateTime.now().millisecondsSinceEpoch}_$i'
          );
          if (imageUrl != null) {
            mediaUrls.add(imageUrl);
          }
        }
      }

      // Парсим теги
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Создаем идею
      final ideaData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'tags': tags,
        'mediaUrls': mediaUrls,
        'isVideo': _isVideo,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Пользователь',
        'authorAvatar': user.photoURL,
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'viewsCount': 0,
        'isFeatured': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('ideas')
          .add(ideaData);

      _showSuccessSnackBar('Идея успешно опубликована!');
      
      // Возвращаемся назад
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/main');
      }
    } catch (e) {
      debugPrint('Error creating idea: $e');
      _showErrorSnackBar('Ошибка при публикации идеи');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поделиться идеей'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
                : const Text(
                    'Опубликовать',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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
              // Заголовок
              _buildTextField(
                controller: _titleController,
                label: 'Название идеи',
                hint: 'Например: Романтическая свадьба в стиле прованс',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название идеи';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Описание
              _buildTextField(
                controller: _descriptionController,
                label: 'Описание',
                hint: 'Расскажите подробнее о вашей идее, что вдохновило, как реализовать...',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите описание идеи';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Теги
              _buildTagsSection(),
              const SizedBox(height: 16),

              // Медиа
              _buildMediaSection(),
              const SizedBox(height: 32),

              // Кнопка публикации
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createIdea,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Опубликовать идею',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Теги',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _tagsController,
          label: 'Теги (через запятую)',
          hint: 'Свадьба, Романтика, Прованс, Цветы',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularTags.map((tag) {
            return FilterChip(
              label: Text(tag),
              selected: _tagsController.text.contains(tag),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_tagsController.text.isEmpty) {
                      _tagsController.text = tag;
                    } else {
                      _tagsController.text = '${_tagsController.text}, $tag';
                    }
                  } else {
                    _tagsController.text = _tagsController.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t != tag)
                        .join(', ');
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Медиа',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Фото'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Видео'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isEmpty && _selectedVideos.isEmpty)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Добавьте фото или видео', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else if (_isVideo && _selectedVideos.isNotEmpty)
          _buildVideoPreview()
        else
          _buildImagePreview(),
      ],
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
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
    );
  }

  Widget _buildVideoPreview() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedVideos.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 150,
                    height: 150,
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeVideo(index),
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
    );
  }
}