import 'package:flutter/material.dart';

import '../models/specialist.dart';
import '../models/story.dart';
import '../services/story_service.dart';

class InstagramStoryViewer extends StatefulWidget {
  const InstagramStoryViewer({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.specialist,
  });
  final List<Story> stories;
  final int initialIndex;
  final Specialist specialist;

  @override
  State<InstagramStoryViewer> createState() => _InstagramStoryViewerState();
}

class _InstagramStoryViewerState extends State<InstagramStoryViewer> with TickerProviderStateMixin {
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
    _pageController = PageController(initialPage: _currentIndex);

    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.linear,
      ),
    );

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
      _progressController.forward().then((_) {
        if (_currentIndex < widget.stories.length - 1) {
          _nextStory();
        } else {
          Navigator.of(context).pop();
        }
      });
    }
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
      _progressController.reset();
      _startProgress();
    } else {
      Navigator.of(context).pop();
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
      _progressController.reset();
      _startProgress();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _progressController.stop();
    } else {
      _startProgress();
    }
  }

  void _onTap(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth / 3) {
      _previousStory();
    } else if (tapPosition > screenWidth * 2 / 3) {
      _nextStory();
    } else {
      _togglePause();
    }
  }

  Widget _buildProgressIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
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
                child: index == _currentIndex
                    ? AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      )
                    : index < _currentIndex
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
      );

  Widget _buildStoryContent(Story story) => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Stack(
          children: [
            // Изображение/видео
            Center(
              child: Image.network(
                story.mediaUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.image,
                    color: Colors.white,
                    size: 100,
                  ),
                ),
              ),
            ),

            // Текст сторис
            if (story.text.isNotEmpty)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    story.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'Сторис не найдены',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTap,
        child: Stack(
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

            // Верхняя панель с прогрессом
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildProgressIndicator(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Аватар специалиста
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: widget.specialist.imageUrl != null
                                ? NetworkImage(widget.specialist.imageUrl!)
                                : null,
                            child: widget.specialist.imageUrl == null
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          // Имя специалиста
                          Expanded(
                            child: Text(
                              widget.specialist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Время
                          Text(
                            _formatTime(
                              widget.stories[_currentIndex].createdAt,
                            ),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Кнопка закрытия
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Индикатор паузы
            if (_isPaused)
              const Center(
                child: Icon(
                  Icons.pause_circle_filled,
                  color: Colors.white,
                  size: 60,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч назад';
    } else {
      return '${difference.inDays}д назад';
    }
  }
}
