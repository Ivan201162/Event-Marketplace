import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';

/// Карточка поста в ленте
class FeedPostCard extends StatefulWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок поста
            _buildPostHeader(),

            // Контент поста
            _buildPostContent(),

            // Действия с постом
            _buildPostActions(),

            // Информация о лайках и комментариях
            _buildPostInfo(),
          ],
        ),
      );

  Widget _buildPostHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: CachedNetworkImageProvider(
                'https://placehold.co/100x100/4CAF50/white?text=SP',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Специалист',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(
                    _formatTime(widget.post.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: _showPostOptions),
          ],
        ),
      );

  Widget _buildPostContent() {
    if (widget.post.mediaUrls.isNotEmpty) {
      return Column(
        children: [
          if (widget.post.text != null && widget.post.text!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.post.text!, style: const TextStyle(fontSize: 14)),
            ),
          const SizedBox(height: 8),
          _buildMediaContent(),
        ],
      );
    } else if (widget.post.text != null && widget.post.text!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(widget.post.text!, style: const TextStyle(fontSize: 14)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMediaContent() {
    if (widget.post.mediaUrls.length == 1) {
      return _buildSingleMedia(widget.post.mediaUrls.first);
    } else if (widget.post.mediaUrls.length > 1) {
      return _buildMultipleMedia();
    }
    return const SizedBox.shrink();
  }

  Widget _buildSingleMedia(String mediaUrl) => SizedBox(
        height: 300,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: mediaUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) =>
              Container(color: Colors.grey[300], child: const Icon(Icons.error)),
        ),
      );

  Widget _buildMultipleMedia() => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.post.mediaUrls.length,
          itemBuilder: (context, index) => Container(
            width: 200,
            margin: const EdgeInsets.only(right: 8),
            child: CachedNetworkImage(
              imageUrl: widget.post.mediaUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.grey[300], child: const Icon(Icons.error)),
            ),
          ),
        ),
      );

  Widget _buildPostActions() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildActionButton(
              icon: _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.grey,
              onTap: _toggleLike,
            ),
            const SizedBox(width: 16),
            _buildActionButton(icon: Icons.chat_bubble_outline, onTap: widget.onComment),
            const SizedBox(width: 16),
            _buildActionButton(icon: Icons.share, onTap: widget.onShare),
            const Spacer(),
            _buildActionButton(
              icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? Colors.blue : Colors.grey,
              onTap: _toggleSave,
            ),
          ],
        ),
      );

  Widget _buildActionButton({required IconData icon, Color? color, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: color ?? Colors.grey[600], size: 24),
      );

  Widget _buildPostInfo() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.likesCount > 0)
              Text(
                '${widget.post.likesCount} лайков',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            if (widget.post.commentsCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${widget.post.commentsCount} комментариев',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ],
        ),
      );

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'сейчас';
    }
  }

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onLike();
  }

  void _toggleSave() {
    setState(() => _isSaved = !_isSaved);
    widget.onSave();
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                widget.onShare();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Сохранить'),
              onTap: () {
                Navigator.pop(context);
                widget.onSave();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Пожаловаться'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать жалобу
              },
            ),
          ],
        ),
      ),
    );
  }
}
