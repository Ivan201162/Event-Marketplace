import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story.dart';
import '../providers/auth_providers.dart';
import '../services/story_service.dart';

/// Экран просмотра сторис
class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
    this.onStoryViewed,
  });

  final List<Story> stories;
  final int initialIndex;
  final void Function(Story)? onStoryViewed;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  int _currentIndex = 0;
  bool _isPaused = false;
  final StoryService _storyService = StoryService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _progressController = AnimationController(
      duration: const Duration(seconds: 5), // 5 секунд на сторис
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_progressController);

    _startProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startProgress() {
    if (!_isPaused && _currentIndex < widget.stories.length) {
      final story = widget.stories[_currentIndex];
      final remainingTime = story.timeUntilExpiry;

      if (remainingTime.inSeconds > 0) {
        _progressController.duration = Duration(
          seconds: remainingTime.inSeconds.clamp(1, 10), // Максимум 10 секунд
        );
        _progressController.forward().then((_) {
          if (mounted) {
            _nextStory();
          }
        });
      } else {
        _nextStory();
      }
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.reset();
      _startProgress();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.reset();
      _startProgress();
    }
  }

  void _pauseProgress() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
  }

  void _resumeProgress() {
    setState(() {
      _isPaused = false;
    });
    _startProgress();
  }

  void _markStoryAsViewed(Story story) {
    widget.onStoryViewed?.call(story);

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      _storyService.markStoryAsViewed(story.id, currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Сторис контент
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _progressController.reset();
                _startProgress();
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _buildStoryContent(story);
              },
            ),

            // Прогресс-бар
            _buildProgressBar(),

            // Заголовок
            _buildHeader(),

            // Управление
            _buildControls(),
          ],
        ),
      );

  Widget _buildStoryContent(Story story) => GestureDetector(
        onTapDown: (_) => _pauseProgress(),
        onTapUp: (_) => _resumeProgress(),
        onTapCancel: _resumeProgress,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: story.mediaUrl.isNotEmpty
              ? Image.network(
                  story.mediaUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      _markStoryAsViewed(story);
                      return child;
                    }
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 64)),
                )
              : story.isVideo
                  ? const Center(
                      child: Text(
                        'Видео просмотр пока не реализован',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            story.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
        ),
      );

  Widget _buildProgressBar() => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 4,
          margin: const EdgeInsets.all(16),
          child: Row(
            children: List.generate(widget.stories.length, (index) {
              final isActive = index == _currentIndex;
              final isCompleted = index < _currentIndex;

              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: isActive
                      ? AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) => LinearProgressIndicator(
                            value: _progressAnimation.value,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : isCompleted
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            )
                          : null,
                ),
              );
            }),
          ),
        ),
      );

  Widget _buildHeader() {
    if (widget.stories.isEmpty) return const SizedBox.shrink();

    final story = widget.stories[_currentIndex];

    return Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Аватар автора
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),

          // Информация об авторе
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Автор сторис', // Здесь можно добавить имя автора
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(story.timeAgo, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // Кнопка закрытия
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SizedBox(
          height: 200,
          child: Row(
            children: [
              // Левая область для предыдущей сторис
              Expanded(
                child: GestureDetector(
                  onTap: _previousStory,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Правая область для следующей сторис
              Expanded(
                child: GestureDetector(
                  onTap: _nextStory,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      );
}
