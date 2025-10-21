import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../models/event_idea.dart';
import '../providers/auth_providers.dart';
import '../services/event_ideas_service.dart';
import 'idea_detail_screen.dart';
import 'share_idea_screen.dart';

class VideoReelsViewer extends ConsumerStatefulWidget {
  const VideoReelsViewer({super.key, this.initialIdea});
  final EventIdea? initialIdea;

  @override
  ConsumerState<VideoReelsViewer> createState() => _VideoReelsViewerState();
}

class _VideoReelsViewerState extends ConsumerState<VideoReelsViewer> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<EventIdea> _videos = [];
  int _currentIndex = 0;
  VideoPlayerController? _currentController;
  bool _isPlaying = true;
  bool _isLoading = true;

  final EventIdeasService _ideasService = EventIdeasService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadVideos();
    _animationController.forward();
  }

  @override
  void dispose() {
    _currentController?.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await _ideasService.getPublishedIdeas(
        limit: 50,
      );

      setState(() {
        _videos = videos.where((idea) => idea.isVideo ?? false).toList();
        _isLoading = false;
      });

      if (_videos.isNotEmpty) {
        // Найти индекс начального видео
        if (widget.initialIdea != null) {
          final initialIndex = _videos.indexWhere(
            (video) => video.id == widget.initialIdea!.id,
          );
          if (initialIndex != -1) {
            _currentIndex = initialIndex;
            _pageController = PageController(initialPage: initialIndex);
          }
        }
        _initializeVideo(_videos[_currentIndex]);
      }
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки видео: $e')),
      );
    }
  }

  Future<void> _initializeVideo(EventIdea video) async {
    try {
      _currentController?.dispose();
      _currentController = VideoPlayerController.networkUrl(
        Uri.parse(video.mediaUrl ?? ''),
      );

      await _currentController!.initialize();
      _currentController!.setLooping(true);

      if (_isPlaying) {
        _currentController!.play();
      }

      setState(() {});
    } on Exception catch (e) {
      debugPrint('Ошибка инициализации видео: $e');
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _currentController?.play();
    } else {
      _currentController?.pause();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _videos.isEmpty
                ? const Center(
                    child: Text(
                      'Нет видео для просмотра',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        _initializeVideo(_videos[index]);
                      },
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        return _buildVideoPage(video);
                      },
                    ),
                  ),
      );

  Widget _buildVideoPage(EventIdea video) => Stack(
        fit: StackFit.expand,
        children: [
          // Видео
          if (_currentController != null && _currentController!.value.isInitialized)
            GestureDetector(
              onTap: _togglePlayPause,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _currentController!.value.size.width,
                  height: _currentController!.value.size.height,
                  child: VideoPlayer(_currentController!),
                ),
              ),
            )
          else
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Информация о видео
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Заголовок
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Описание
                  if (video.description.isNotEmpty) ...[
                    Text(
                      video.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Автор
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            video.authorAvatar != null ? NetworkImage(video.authorAvatar!) : null,
                        child: video.authorAvatar == null
                            ? const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        video.authorName ?? 'Неизвестный',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(video.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Кнопки действий справа
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                _buildActionButton(
                  icon: Icons.favorite_border,
                  color: Colors.white,
                  count: video.likes,
                  onTap: () => _toggleLike(video),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.comment,
                  color: Colors.white,
                  count: video.comments,
                  onTap: () => _openComments(video),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.bookmark_border,
                  color: Colors.white,
                  count: 0,
                  onTap: () => _toggleSave(video),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.share,
                  color: Colors.white,
                  count: video.shares,
                  onTap: () => _shareVideo(video),
                ),
              ],
            ),
          ),

          // Кнопка воспроизведения/паузы в центре
          if (!_isPlaying)
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),

          // Кнопка закрытия
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Индикатор прогресса
          if (_currentController != null && _currentController!.value.isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _currentController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
        ],
      );

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _toggleLike(EventIdea video) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    // await _ideasService.toggleLike(video.id, currentUser.id);
  }

  Future<void> _toggleSave(EventIdea video) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    // await _ideasService.toggleSave(video.id, currentUser.id);
  }

  Future<void> _shareVideo(EventIdea video) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareIdeaScreen(idea: video),
      ),
    );
  }

  void _openComments(EventIdea video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdeaDetailScreen(idea: video),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }
}
