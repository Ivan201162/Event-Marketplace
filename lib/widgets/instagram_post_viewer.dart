import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/specialist.dart';
import '../services/post_service.dart';

class InstagramPostViewer extends StatefulWidget {
  const InstagramPostViewer({
    super.key,
    required this.post,
    required this.specialist,
  });
  final Post post;
  final Specialist specialist;

  @override
  State<InstagramPostViewer> createState() => _InstagramPostViewerState();
}

class _InstagramPostViewerState extends State<InstagramPostViewer> {
  final PostService _postService = PostService();
  bool _isLiked = false;
  int _likesCount = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    // TODO(developer): Проверить, лайкнул ли текущий пользователь пост
    _isLiked = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    try {
      // TODO(developer): Получить ID текущего пользователя
      const currentUserId = 'current_user_id';

      await _postService.toggleLike(widget.post.id, currentUserId);

      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  Widget _buildMediaContent() {
    if (widget.post.mediaUrls.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image, size: 100, color: Colors.grey),
        ),
      );
    }

    if (widget.post.mediaUrls.length == 1) {
      return AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          widget.post.mediaUrls.first,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.image, size: 100, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.post.mediaUrls.length,
        itemBuilder: (context, index) => Image.network(
          widget.post.mediaUrls[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.image, size: 100, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.specialist.imageUrl != null
                  ? NetworkImage(widget.specialist.imageUrl!)
                  : null,
              child: widget.specialist.imageUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.specialist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatTime(widget.post.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO(developer): Показать меню поста
              },
            ),
          ],
        ),
      );

  Widget _buildPostActions() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.black,
              ),
              onPressed: _toggleLike,
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                // TODO(developer): Открыть комментарии
              },
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                // TODO(developer): Поделиться постом
              },
            ),
            const Spacer(),
            if (widget.post.mediaUrls.length > 1)
              Row(
                children: List.generate(
                  widget.post.mediaUrls.length,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildPostLikes() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          '$_likesCount отметок "Нравится"',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );

  Widget _buildPostCaption() {
    if (widget.post.text == null || widget.post.text!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(
              text: '${widget.specialist.name} ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: widget.post.text),
          ],
        ),
      ),
    );
  }

  Widget _buildPostComments() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextButton(
          onPressed: () {
            // TODO(developer): Открыть комментарии
          },
          child: Text(
            'Посмотреть все ${widget.post.commentsCount} комментариев',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Публикация',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.black),
              onPressed: () {
                // TODO(developer): Поделиться постом
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildPostHeader(),
            _buildMediaContent(),
            _buildPostActions(),
            _buildPostLikes(),
            _buildPostCaption(),
            _buildPostComments(),
            const Spacer(),
          ],
        ),
      );
}
