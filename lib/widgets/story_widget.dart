import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story.dart';
import '../providers/auth_providers.dart';
import '../services/story_service.dart';
import 'create_story_dialog.dart';
import 'story_viewer_screen.dart';

/// Виджет для отображения сторис
class StoryWidget extends ConsumerStatefulWidget {
  const StoryWidget({
    super.key,
    this.userId,
    this.showAllStories = false,
  });

  final String? userId; // Если null, показываем все сторис
  final bool showAllStories;

  @override
  ConsumerState<StoryWidget> createState() => _StoryWidgetState();
}

class _StoryWidgetState extends ConsumerState<StoryWidget> {
  final StoryService _storyService = StoryService();
  List<Story> _stories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<Story> stories;
      if (widget.showAllStories) {
        stories = await _storyService.getAllActiveStories();
      } else if (widget.userId != null) {
        stories = await _storyService.getUserStories(widget.userId!);
      } else {
        stories = [];
      }

      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createStory() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateStoryDialog(),
    );

    if (result ?? false) {
      await _loadStories();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой создания
          _buildHeader(),
          const SizedBox(height: 16),

          // Список сторис
          _buildStoriesList(),
        ],
      );

  Widget _buildHeader() => Row(
        children: [
          Expanded(
            child: Text(
              widget.showAllStories ? 'Все сторис' : 'Мои сторис',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Кнопка создания сторис (только для своих сторис)
          if (!widget.showAllStories)
            IconButton(
              onPressed: _createStory,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Создать сторис',
            ),
        ],
      );

  Widget _buildStoriesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_stories.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 120,
      child: RefreshIndicator(
        onRefresh: _loadStories,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _stories.length,
          itemBuilder: (context, index) {
            final story = _stories[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: StoryCircle(
                story: story,
                onTap: () => _viewStory(story),
                onDelete:
                    !widget.showAllStories ? () => _deleteStory(story) : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки сторис',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStories,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.showAllStories ? 'Нет активных сторис' : 'Нет сторис',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.showAllStories
                  ? 'Специалисты еще не создали сторис'
                  : 'Создайте свою первую сторис',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            if (!widget.showAllStories) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createStory,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Создать сторис'),
              ),
            ],
          ],
        ),
      );

  void _viewStory(Story story) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StoryViewerScreen(
          stories: _stories,
          initialIndex: _stories.indexOf(story),
          onStoryViewed: _markStoryAsViewed,
        ),
      ),
    );
  }

  Future<void> _markStoryAsViewed(Story story) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        await _storyService.markStoryAsViewed(
          story.id,
          currentUser.uid,
        );
      }
    } catch (e) {
      debugPrint('Error marking story as viewed: $e');
    }
  }

  Future<void> _deleteStory(Story story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сторис'),
        content: const Text('Вы уверены, что хотите удалить эту сторис?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _storyService.deleteStory(story.id);
        await _loadStories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сторис удалена'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Круглая иконка сторис
class StoryCircle extends StatelessWidget {
  const StoryCircle({
    super.key,
    required this.story,
    this.onTap,
    this.onDelete,
  });

  final Story story;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: story.expiresAt.isBefore(DateTime.now())
                  ? Colors.grey
                  : Colors.blue,
              width: 3,
            ),
          ),
          child: Stack(
            children: [
              // Основное изображение
              ClipOval(
                child: story.mediaUrl.isNotEmpty
                    ? Image.network(
                        story.mediaUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Icon(
                            story.isVideo ? Icons.video_library : Icons.image,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.black,
                        child: story.title.isNotEmpty
                            ? Center(
                                child: Text(
                                  story.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : Icon(
                                story.isVideo
                                    ? Icons.video_library
                                    : Icons.image,
                                color: Colors.grey[400],
                              ),
                      ),
              ),

              // Индикатор истечения времени
              if (!story.expiresAt.isBefore(DateTime.now()))
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),

              // Кнопка удаления
              if (onDelete != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),

              // Индикатор просмотров
              if (story.viewCount > 0)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          story.viewCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
