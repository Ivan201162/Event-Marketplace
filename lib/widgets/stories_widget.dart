import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_type.dart';
import '../models/story.dart';
import '../providers/story_providers.dart';

/// Виджет для отображения сторис
class StoriesWidget extends ConsumerWidget {
  const StoriesWidget({
    super.key,
    required this.specialistId,
    this.showAddStory = false,
    this.onAddStory,
  });
  final String specialistId;
  final bool showAddStory;
  final VoidCallback? onAddStory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(specialistStoriesProvider(specialistId));

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: storiesAsync.when(
        data: (stories) {
          final activeStories = stories
              .where((story) => !story.isExpired && story.isActive)
              .toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activeStories.length + (showAddStory ? 1 : 0),
            itemBuilder: (context, index) {
              if (showAddStory && index == 0) {
                return _buildAddStoryButton(context);
              }

              final storyIndex = showAddStory ? index - 1 : index;
              final story = activeStories[storyIndex];

              return _buildStoryItem(context, story);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка загрузки сторис: $error'),
        ),
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            GestureDetector(
              onTap: onAddStory,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Добавить',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );

  Widget _buildStoryItem(BuildContext context, Story story) {
    final isViewed = story.isViewedBy('current_user');

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _openStory(context, story),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isViewed
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  story.thumbnailUrl ?? story.mediaUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: Icon(
                      story.mediaType == MediaType.video
                          ? Icons.videocam
                          : Icons.image,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.specialistName,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _openStory(BuildContext context, Story story) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryViewScreen(story: story),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Экран просмотра сторис
class StoryViewScreen extends StatefulWidget {
  const StoryViewScreen({
    super.key,
    required this.story,
  });
  final Story story;

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_progressController);

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Медиа контент
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: _buildMediaContent(),
              ),
            ),
            // Прогресс бар
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: _buildProgressBar(),
            ),
            // Заголовок
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: _buildHeader(),
            ),
            // Действия
            Positioned(
              bottom: 50,
              left: 16,
              right: 16,
              child: _buildActions(),
            ),
          ],
        ),
      );

  Widget _buildMediaContent() {
    if (widget.story.mediaType == MediaType.video) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            color: Colors.white,
            size: 80,
          ),
        ),
      );
    } else {
      return Image.network(
        widget.story.mediaUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(
              Icons.image,
              color: Colors.white,
              size: 80,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildProgressBar() => AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) => LinearProgressIndicator(
          value: _progressAnimation.value,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );

  Widget _buildHeader() => Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(
              widget.story.specialistPhotoUrl ??
                  'https://via.placeholder.com/40',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.story.specialistName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTime(widget.story.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );

  Widget _buildActions() => Column(
        children: [
          if (widget.story.content != null &&
              widget.story.content!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.story.content!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Отправить сообщение...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: _likeStory,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareStory,
              ),
            ],
          ),
        ],
      );

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  void _likeStory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Лайк добавлен')),
    );
  }

  void _shareStory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сторис скопирована в буфер обмена')),
    );
  }
}

/// Виджет для создания новой сторис
class CreateStoryWidget extends StatefulWidget {
  const CreateStoryWidget({
    super.key,
    this.onStoryCreated,
  });
  final VoidCallback? onStoryCreated;

  @override
  State<CreateStoryWidget> createState() => _CreateStoryWidgetState();
}

class _CreateStoryWidgetState extends State<CreateStoryWidget> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedImagePath;
  bool _isVideo = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать сторис'),
          actions: [
            TextButton(
              onPressed: _canPublish() ? _publishStory : null,
              child: const Text('Опубликовать'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Предварительный просмотр
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: _buildPreview(),
              ),
            ),
            // Панель инструментов
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Текстовое поле
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Добавить текст...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Кнопки действий
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo),
                          label: const Text('Фото'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Видео'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildPreview() {
    if (_selectedImagePath != null) {
      return Image.network(
        _selectedImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.image,
            color: Colors.white,
            size: 80,
          ),
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: Colors.white,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Выберите фото или видео',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }
  }

  bool _canPublish() =>
      _selectedImagePath != null || _textController.text.isNotEmpty;

  void _pickImage() {
    setState(() {
      _selectedImagePath = 'https://via.placeholder.com/400x600';
      _isVideo = false;
    });
  }

  void _pickVideo() {
    setState(() {
      _selectedImagePath = 'https://via.placeholder.com/400x600';
      _isVideo = true;
    });
  }

  void _publishStory() {
    // TODO: Реализовать публикацию сторис
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сторис опубликована')),
    );
    Navigator.pop(context);
    widget.onStoryCreated?.call();
  }
}
