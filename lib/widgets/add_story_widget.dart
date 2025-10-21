import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/story.dart';
import '../services/story_service.dart';

/// Виджет для добавления сториса
class AddStoryWidget extends ConsumerStatefulWidget {
  const AddStoryWidget({super.key, required this.userId, this.onStoryAdded});

  final String userId;
  final VoidCallback? onStoryAdded;

  @override
  ConsumerState<AddStoryWidget> createState() => _AddStoryWidgetState();
}

class _AddStoryWidgetState extends ConsumerState<AddStoryWidget> {
  final StoryService _storyService = StoryService();
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _showAddStoryDialog,
        child: Container(
          width: 70,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              // Кнопка добавления
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  color: Colors.grey.shade100,
                ),
                child: const Icon(Icons.add, color: Colors.grey, size: 24),
              ),
              const SizedBox(height: 4),
              // Текст
              const Text(
                'Добавить',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );

  void _showAddStoryDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить сторис'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Подпись (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          TextButton(onPressed: _showSourceDialog, child: const Text('Продолжить')),
        ],
      ),
    );
  }

  void _showSourceDialog() {
    Navigator.of(context).pop(); // Закрываем предыдущий диалог

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите источник'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () {
                Navigator.of(context).pop();
                _uploadStoryFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () {
                Navigator.of(context).pop();
                _uploadStoryFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadStoryFromGallery() async {
    await _uploadStory(ImageSource.gallery);
  }

  Future<void> _uploadStoryFromCamera() async {
    await _uploadStory(ImageSource.camera);
  }

  Future<void> _uploadStory(ImageSource source) async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      final caption = _captionController.text.trim();

      Story? story;
      if (source == ImageSource.gallery) {
        story = await _storyService.createStory(
          userId: widget.userId,
          caption: caption.isNotEmpty ? caption : null,
          mediaUrl: '', // TODO(developer): Add media URL
        );
      } else {
        story = await _storyService.createStory(
          userId: widget.userId,
          caption: caption.isNotEmpty ? caption : null,
          mediaUrl: '', // TODO(developer): Add media URL
        );
      }

      if (mounted) {
        _captionController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сторис успешно добавлен!'), backgroundColor: Colors.green),
        );
        widget.onStoryAdded?.call();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл не выбран'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки сториса: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

/// Виджет для отображения сторисов пользователя в профиле
class UserStoriesWidget extends ConsumerWidget {
  const UserStoriesWidget({
    super.key,
    required this.userId,
    this.showAddButton = false,
    this.onStoryAdded,
  });

  final String userId;
  final bool showAddButton;
  final VoidCallback? onStoryAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(specialistStoriesProvider(userId));

    return storiesAsync.when(
      data: (stories) => _buildStoriesList(context, stories),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки сторисов: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(specialistStoriesProvider(userId)),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesList(BuildContext context, List<Story> stories) {
    if (stories.isEmpty && !showAddButton) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет активных сторисов'),
          ],
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length + (showAddButton ? 1 : 0),
        itemBuilder: (context, index) {
          if (showAddButton && index == 0) {
            return AddStoryWidget(userId: userId, onStoryAdded: onStoryAdded);
          }

          final storyIndex = showAddButton ? index - 1 : index;
          final story = stories[storyIndex];
          return _buildStoryCircle(context, story);
        },
      ),
    );
  }

  Widget _buildStoryCircle(BuildContext context, Story story) => GestureDetector(
        onTap: () => _openStory(context, story),
        child: Container(
          width: 70,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              // Аватарка с обводкой
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 3),
                ),
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.auto_stories, color: Colors.blue, size: 24),
                ),
              ),
              const SizedBox(height: 4),
              // Время до истечения
              Text(
                _formatTimeUntilExpiry(story.timeUntilExpiry),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );

  String _formatTimeUntilExpiry(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}ч';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м';
    } else {
      return '${duration.inSeconds}с';
    }
  }

  void _openStory(BuildContext context, Story story) {
    // В реальном приложении здесь бы открывался экран просмотра сториса
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Открытие сториса: ${story.id}')));
  }
}
