import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist_story.dart';
import '../services/story_service.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.userId,
  });
  final List<SpecialistStory> stories;
  final int initialIndex;
  final String userId;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();

  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_progressController);

    _startStory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startStory() {
    if (_currentIndex >= widget.stories.length) {
      Navigator.pop(context);
      return;
    }

    final story = widget.stories[_currentIndex];
    if (!story.isActive) {
      _nextStory();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Отмечаем сторис как просмотренную
    _storyService.markStoryAsViewed(story.id, widget.userId);

    // Запускаем прогресс
    _progressController.reset();
    _progressController.forward().then((_) {
      if (mounted) {
        _nextStory();
      }
    });

    setState(() {
      _isLoading = false;
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    }
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Нет сторис для просмотра',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _pauseStory(),
        onTapUp: (_) => _resumeStory(),
        onTapCancel: _resumeStory,
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // Сторис контент
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _startStory();
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _buildStoryContent(story);
              },
            ),

            // Прогресс бар
            _buildProgressBar(),

            // Заголовок
            _buildHeader(),

            // Навигация
            _buildNavigation(),

            // Индикатор загрузки
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(SpecialistStory story) => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Основной контент
            _buildMainContent(story),

            // Текст и подпись
            if (story.text != null || story.caption != null) _buildTextOverlay(story),
          ],
        ),
      );

  Widget _buildMainContent(SpecialistStory story) {
    switch (story.contentType) {
      case StoryContentType.image:
        return Image.network(
          story.contentUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              setState(() {
                _isLoading = false;
              });
              return child;
            }
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 64,
            ),
          ),
        );
      case StoryContentType.video:
        // TODO(developer): Реализовать видео плеер
        return const Center(
          child: Text(
            'Видео плеер будет реализован',
            style: TextStyle(color: Colors.white),
          ),
        );
      case StoryContentType.text:
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                story.text ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildTextOverlay(SpecialistStory story) => Positioned(
        bottom: 100,
        left: 16,
        right: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (story.text != null)
              Text(
                story.text!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            if (story.caption != null) ...[
              const SizedBox(height: 8),
              Text(
                story.caption!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildProgressBar() => Positioned(
        top: 50,
        left: 8,
        right: 8,
        child: Row(
          children: List.generate(
            widget.stories.length,
            (index) => Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: index == _currentIndex
                    ? AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) => LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Container(
                        color: index < _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
              ),
            ),
          ),
        ),
      );

  Widget _buildHeader() {
    final story = widget.stories[_currentIndex];

    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Аватар специалиста
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            backgroundImage:
                story.specialistAvatar != null ? NetworkImage(story.specialistAvatar!) : null,
            child: story.specialistAvatar == null
                ? Text(
                    story.specialistName.isNotEmpty ? story.specialistName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // Имя специалиста
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.specialistName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(story.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Кнопка закрытия
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() => Row(
        children: [
          // Левая область для предыдущей сторис
          Expanded(
            child: GestureDetector(
              onTap: _previousStory,
              child: Container(
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
          ),

          // Правая область для следующей сторис
          Expanded(
            child: GestureDetector(
              onTap: _nextStory,
              child: Container(
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      );

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч назад';
    } else {
      return '${difference.inDays}д назад';
    }
  }
}
