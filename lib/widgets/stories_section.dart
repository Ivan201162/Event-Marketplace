import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../models/story.dart';
import '../services/story_service.dart';

/// Виджет секции сторисов специалистов
class StoriesSection extends ConsumerStatefulWidget {
  const StoriesSection({super.key});

  @override
  ConsumerState<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends ConsumerState<StoriesSection> {
  final StoryService _storyService = StoryService();
  Map<String, List<Story>> _userStories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      setState(() => _isLoading = true);

      // Получаем список специалистов с активными сторисами
      final allStories = await _storyService.getAllActiveStories();

      // Группируем сторисы по пользователям
      final userStories = <String, List<Story>>{};
      for (final story in allStories) {
        if (!userStories.containsKey(story.specialistId)) {
          userStories[story.specialistId] = [];
        }
        userStories[story.specialistId]!.add(story);
      }

      setState(() {
        _userStories = userStories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки сторисов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_userStories.isEmpty) {
      return _buildEmptyWidget();
    }

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Сторисы специалистов',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.storiesView),
                  child: const Text('Все'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _userStories.length,
              itemBuilder: (context, index) {
                final userId = _userStories.keys.elementAt(index);
                final stories = _userStories[userId]!;
                return _buildStoryCircle(userId, stories);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() => Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );

  Widget _buildEmptyWidget() => Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: Text(
            'Пока нет активных сторисов',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );

  Widget _buildStoryCircle(String userId, List<Story> stories) {
    final hasUnviewedStories =
        stories.any((story) => !story.isViewedBy(userId));

    return GestureDetector(
      onTap: () => _openStoriesView(userId, stories),
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
                border: Border.all(
                  color: hasUnviewedStories
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 27,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Имя пользователя
            Text(
              'Специалист',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Индикатор количества сторисов
            if (stories.length > 1)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${stories.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openStoriesView(String userId, List<Story> stories) {
    context.push(
      AppRoutes.storiesView,
      extra: {
        'userId': userId,
        'stories': stories,
      },
    );
  }
}

/// Экран просмотра сторисов
class StoriesViewScreen extends ConsumerStatefulWidget {
  const StoriesViewScreen({
    super.key,
    required this.userId,
    required this.stories,
  });
  final String userId;
  final List<Story> stories;

  @override
  ConsumerState<StoriesViewScreen> createState() => _StoriesViewScreenState();
}

class _StoriesViewScreenState extends ConsumerState<StoriesViewScreen> {
  final StoryService _storyService = StoryService();
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isViewing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startViewing();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startViewing() {
    if (widget.stories.isNotEmpty && !_isViewing) {
      _isViewing = true;
      _markCurrentStoryAsViewed();
      _startAutoAdvance();
    }
  }

  void _markCurrentStoryAsViewed() {
    if (_currentIndex < widget.stories.length) {
      final currentStory = widget.stories[_currentIndex];
      _storyService.markStoryAsViewed(currentStory.id, widget.userId);
    }
  }

  void _startAutoAdvance() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isViewing) {
        _nextStory();
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Сторисы'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Нет активных сторисов',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Сторисы
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _markCurrentStoryAsViewed();
              _startAutoAdvance();
            },
            itemCount: widget.stories.length,
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              return _buildStoryContent(story);
            },
          ),

          // Верхняя панель с прогрессом
          _buildTopBar(),

          // Нижняя панель с информацией
          _buildBottomBar(),

          // Кнопки навигации
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStoryContent(Story story) => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: (story.mediaUrl.contains('mp4') || story.mediaUrl.contains('mov'))
            ? _buildVideoContent(story)
            : _buildImageContent(story),
      );

  Widget _buildImageContent(Story story) => Image.network(
        story.mediaUrl ?? '',
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.error,
            color: Colors.white,
            size: 50,
          ),
        ),
      );

  Widget _buildVideoContent(Story story) {
    // В реальном приложении здесь бы использовался video_player
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Видео контент',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Прогресс-бары
                Row(
                  children: List.generate(
                    widget.stories.length,
                    (index) => Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(
                          right: index < widget.stories.length - 1 ? 4 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: index <= _currentIndex
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Кнопка закрытия
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1}/${widget.stories.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildBottomBar() {
    if (_currentIndex >= widget.stories.length) return const SizedBox.shrink();

    final story = widget.stories[_currentIndex];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (story.caption.isNotEmpty)
                Text(
                  story.caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${story.viewCount}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() => Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: Row(
          children: [
            // Левая область для перехода к предыдущему сторису
            Expanded(
              child: GestureDetector(
                onTap: _previousStory,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // Правая область для перехода к следующему сторису
            Expanded(
              child: GestureDetector(
                onTap: _nextStory,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      );
}
