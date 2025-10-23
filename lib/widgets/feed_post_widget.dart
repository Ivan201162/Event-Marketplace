import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

import '../models/enhanced_feed_post.dart';

/// Виджет поста в ленте
class FeedPostWidget extends ConsumerStatefulWidget {
  const FeedPostWidget({
    super.key,
    required this.post,
    this.onUserTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onMore,
  });

  final EnhancedFeedPost post;
  final VoidCallback? onUserTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onMore;

  @override
  ConsumerState<FeedPostWidget> createState() => _FeedPostWidgetState();
}

class _FeedPostWidgetState extends ConsumerState<FeedPostWidget> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isExpanded = false;
  VideoPlayerController? _videoController;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer() {
    if (widget.post.media.isNotEmpty) {
      final firstVideo = widget.post.media
          .where((media) => media.type == FeedPostMediaType.video)
          .firstOrNull;

      if (firstVideo != null) {
        _videoController =
            VideoPlayerController.networkUrl(Uri.parse(firstVideo.url));
        _videoController?.initialize().then((_) {
          setState(() {});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(),
            _buildPostContent(),
            _buildPostMedia(),
            _buildPostActions(),
            _buildPostStats(),
            if (widget.post.comments.isNotEmpty) _buildCommentsPreview(),
          ],
        ),
      );

  Widget _buildPostHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onUserTap,
              child: CircleAvatar(
                radius: 20,
                backgroundImage: widget.post.authorId.isNotEmpty
                    ? CachedNetworkImageProvider(
                        'https://ui-avatars.com/api/?name=${widget.post.authorId}&size=40',
                      )
                    : null,
                child: widget.post.authorId.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пользователь ${widget.post.authorId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _formatDate(widget.post.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (widget.post.isPinned)
              const Icon(Icons.push_pin, color: Colors.orange, size: 16),
            if (widget.post.isSponsored)
              const Icon(Icons.ads_click, color: Colors.blue, size: 16),
            IconButton(
                onPressed: widget.onMore, icon: const Icon(Icons.more_vert)),
          ],
        ),
      );

  Widget _buildPostContent() {
    if (widget.post.content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.content,
            style: const TextStyle(fontSize: 16),
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
          if (widget.post.content.length > 100)
            TextButton(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(_isExpanded ? 'Свернуть' : 'Показать полностью'),
            ),
          if (widget.post.tags.isNotEmpty) _buildTags(),
          if (widget.post.location != null) _buildLocation(),
        ],
      ),
    );
  }

  Widget _buildTags() => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          children: widget.post.tags
              .map(
                (tag) => GestureDetector(
                  onTap: () {
                    // TODO: Переход к поиску по тегу
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('#$tag',
                        style:
                            TextStyle(color: Colors.blue[800], fontSize: 12)),
                  ),
                ),
              )
              .toList(),
        ),
      );

  Widget _buildLocation() => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(widget.post.location!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      );

  Widget _buildPostMedia() {
    if (widget.post.media.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildMediaContent(),
    );
  }

  Widget _buildMediaContent() {
    if (widget.post.media.length == 1) {
      return _buildSingleMedia(widget.post.media.first);
    } else {
      return _buildMediaCarousel();
    }
  }

  Widget _buildSingleMedia(FeedPostMedia media) {
    switch (media.type) {
      case FeedPostMediaType.image:
        return GestureDetector(
          onTap: () => _showImageFullscreen(media.url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: media.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error)),
            ),
          ),
        );
      case FeedPostMediaType.video:
        return _buildVideoPlayer(media);
      case FeedPostMediaType.gif:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(imageUrl: media.url, fit: BoxFit.cover),
        );
      case FeedPostMediaType.audio:
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Icon(Icons.audiotrack, size: 32)),
        );
    }
  }

  Widget _buildVideoPlayer(FeedPostMedia media) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            if (!_videoController!.value.isPlaying)
              const Icon(Icons.play_circle_fill,
                  size: 64, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCarousel() => Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              onPageChanged: (index) {
                setState(() {
                  _currentMediaIndex = index;
                });
              },
              itemCount: widget.post.media.length,
              itemBuilder: (context, index) =>
                  _buildSingleMedia(widget.post.media[index]),
            ),
          ),
          if (widget.post.media.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.post.media.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentMediaIndex == index
                          ? Colors.blue
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _buildPostActions() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildActionButton(
              icon: _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.grey,
              onTap: () {
                setState(() {
                  _isLiked = !_isLiked;
                });
                widget.onLike?.call();
              },
            ),
            const SizedBox(width: 16),
            _buildActionButton(
                icon: Icons.chat_bubble_outline, onTap: widget.onComment),
            const SizedBox(width: 16),
            _buildActionButton(
                icon: Icons.share_outlined, onTap: widget.onShare),
            const Spacer(),
            _buildActionButton(
              icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? Colors.blue : Colors.grey,
              onTap: () {
                setState(() {
                  _isSaved = !_isSaved;
                });
                widget.onSave?.call();
              },
            ),
          ],
        ),
      );

  Widget _buildActionButton(
          {required IconData icon, Color? color, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: color ?? Colors.grey[600], size: 24),
      );

  Widget _buildPostStats() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.post.likesCount > 0)
              Text(
                '${widget.post.likesCount} ${_getLikesText(widget.post.likesCount)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (widget.post.commentsCount > 0)
              TextButton(
                onPressed: widget.onComment,
                child: Text(
                  'Показать все ${widget.post.commentsCount} ${_getCommentsText(widget.post.commentsCount)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      );

  Widget _buildCommentsPreview() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: widget.post.comments
              .take(2)
              .map(
                (comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Пользователь ${comment.authorId} ',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        TextSpan(
                          text: comment.text,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );

  void _showImageFullscreen(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
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
      return 'Только что';
    }
  }

  String _getLikesText(int count) {
    if (count == 1) return 'лайк';
    if (count >= 2 && count <= 4) return 'лайка';
    return 'лайков';
  }

  String _getCommentsText(int count) {
    if (count == 1) return 'комментарий';
    if (count >= 2 && count <= 4) return 'комментария';
    return 'комментариев';
  }
}
