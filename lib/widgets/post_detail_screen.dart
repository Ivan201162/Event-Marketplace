import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../models/user_profile.dart';

/// Экран детального просмотра поста
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.post});
  final UserPost post;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.isVideo && widget.post.videoUrl != null) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.post.videoUrl!));
    _videoController!.initialize().then((_) {
      setState(() {
        _isVideoInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _sharePost,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showPostMenu,
            ),
          ],
        ),
        body: Column(
          children: [
            // Медиа контент
            Expanded(flex: 3, child: _buildMediaContent()),
            // Информация о посте
            Expanded(flex: 2, child: _buildPostInfo()),
          ],
        ),
      );

  Widget _buildMediaContent() {
    if (widget.post.isVideo && widget.post.videoUrl != null) {
      return _buildVideoPlayer();
    } else if (widget.post.imageUrl != null) {
      return _buildImageViewer();
    } else {
      return Container(
        color: Colors.grey[800],
        child: const Center(child: Icon(Icons.image, color: Colors.white, size: 64)),
      );
    }
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          children: [
            VideoPlayer(_videoController!),
            Center(
              child: IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 64,
                ),
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer() => InteractiveViewer(
        child: CachedNetworkImage(
          imageUrl: widget.post.imageUrl!,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            child: const Center(child: Icon(Icons.error, color: Colors.white, size: 64)),
          ),
        ),
      );

  Widget _buildPostInfo() => Container(
        color: Colors.white,
        child: Column(
          children: [
            // Действия с постом
            _buildPostActions(),
            // Лайки
            _buildLikesSection(),
            // Описание
            _buildCaption(),
            // Комментарии
            _buildCommentsSection(),
            // Время публикации
            _buildTimestamp(),
          ],
        ),
      );

  Widget _buildPostActions() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                widget.post.likedBy.contains(
                  'current_user_id',
                ) // TODO(developer): Получить ID текущего пользователя
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: widget.post.likedBy.contains('current_user_id') ? Colors.red : Colors.black,
              ),
              onPressed: _toggleLike,
            ),
            IconButton(icon: const Icon(Icons.comment_outlined), onPressed: _showComments),
            IconButton(icon: const Icon(Icons.share_outlined), onPressed: _sharePost),
            const Spacer(),
            IconButton(icon: const Icon(Icons.bookmark_border), onPressed: _savePost),
          ],
        ),
      );

  Widget _buildLikesSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              '${widget.post.likes} отметок "Нравится"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildCaption() {
    if (widget.post.caption.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'username', // TODO(developer): Получить имя пользователя
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.post.caption)),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            if (widget.post.comments > 0)
              TextButton(
                onPressed: _showComments,
                child: Text(
                  'Посмотреть все ${widget.post.comments} комментариев',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            // TODO(developer): Добавить список комментариев
          ],
        ),
      );

  Widget _buildTimestamp() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              _formatTimestamp(widget.post.timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}м';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}ч';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }

  void _toggleLike() {
    // TODO(developer): Реализовать лайк/дизлайк
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Лайк/дизлайк')));
  }

  void _showComments() {
    // TODO(developer): Показать экран комментариев
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Комментарии')));
  }

  void _sharePost() {
    // TODO(developer): Реализовать шаринг поста
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Поделиться постом')));
  }

  void _savePost() {
    // TODO(developer): Реализовать сохранение поста
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сохранить пост')));
  }

  void _showPostMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Копировать ссылку'),
              onTap: () {
                Navigator.pop(context);
                // TODO(developer): Копировать ссылку
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                _sharePost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Сохранить'),
              onTap: () {
                Navigator.pop(context);
                _savePost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Пожаловаться'),
              onTap: () {
                Navigator.pop(context);
                // TODO(developer): Показать диалог жалобы
              },
            ),
          ],
        ),
      ),
    );
  }
}
