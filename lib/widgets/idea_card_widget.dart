import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

import '../models/enhanced_idea.dart';

/// Виджет карточки идеи
class IdeaCardWidget extends ConsumerStatefulWidget {
  const IdeaCardWidget({
    super.key,
    required this.idea,
    this.onUserTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onMore,
    this.onTap,
  });

  final EnhancedIdea idea;
  final VoidCallback? onUserTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onMore;
  final VoidCallback? onTap;

  @override
  ConsumerState<IdeaCardWidget> createState() => _IdeaCardWidgetState();
}

class _IdeaCardWidgetState extends ConsumerState<IdeaCardWidget> {
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
    if (widget.idea.media.isNotEmpty) {
      final firstVideo = widget.idea.media
          .where((media) => media.type == IdeaMediaType.video)
          .firstOrNull;

      if (firstVideo != null) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(firstVideo.url),
        );
        _videoController?.initialize().then((_) {
          setState(() {});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIdeaHeader(),
              _buildIdeaContent(),
              _buildIdeaMedia(),
              _buildIdeaActions(),
              _buildIdeaStats(),
              if (widget.idea.comments.isNotEmpty) _buildCommentsPreview(),
            ],
          ),
        ),
      );

  Widget _buildIdeaHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onUserTap,
              child: CircleAvatar(
                radius: 20,
                backgroundImage: widget.idea.authorId.isNotEmpty
                    ? CachedNetworkImageProvider(
                        'https://ui-avatars.com/api/?name=${widget.idea.authorId}&size=40',
                      )
                    : null,
                child: widget.idea.authorId.isEmpty
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
                    'Пользователь ${widget.idea.authorId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        widget.idea.type.icon,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.idea.type.displayName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(widget.idea.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.idea.isFeatured)
              const Icon(Icons.star, color: Colors.amber, size: 16),
            IconButton(
              onPressed: widget.onMore,
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      );

  Widget _buildIdeaContent() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.idea.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.idea.description,
              style: const TextStyle(fontSize: 16),
              maxLines: _isExpanded ? null : 3,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            if (widget.idea.description.length > 100)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(_isExpanded ? 'Свернуть' : 'Показать полностью'),
              ),
            if (widget.idea.tags.isNotEmpty) _buildTags(),
            if (widget.idea.budget != null ||
                widget.idea.timeline != null ||
                widget.idea.location != null)
              _buildIdeaDetails(),
          ],
        ),
      );

  Widget _buildTags() => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          children: widget.idea.tags
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
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );

  Widget _buildIdeaDetails() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (widget.idea.budget != null)
                _buildDetailRow(
                  Icons.attach_money,
                  'Бюджет',
                  '${widget.idea.budget!.toStringAsFixed(0)} ₽',
                ),
              if (widget.idea.timeline != null)
                _buildDetailRow(
                  Icons.schedule,
                  'Сроки',
                  widget.idea.timeline!,
                ),
              if (widget.idea.location != null)
                _buildDetailRow(
                  Icons.location_on,
                  'Место',
                  widget.idea.location!,
                ),
            ],
          ),
        ),
      );

  Widget _buildDetailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );

  Widget _buildIdeaMedia() {
    if (widget.idea.media.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildMediaContent(),
    );
  }

  Widget _buildMediaContent() {
    if (widget.idea.media.length == 1) {
      return _buildSingleMedia(widget.idea.media.first);
    } else {
      return _buildMediaCarousel();
    }
  }

  Widget _buildSingleMedia(IdeaMedia media) {
    switch (media.type) {
      case IdeaMediaType.image:
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
                child: const Icon(Icons.error),
              ),
            ),
          ),
        );
      case IdeaMediaType.video:
        return _buildVideoPlayer(media);
      case IdeaMediaType.gif:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: media.url,
            fit: BoxFit.cover,
          ),
        );
      case IdeaMediaType.audio:
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.audiotrack, size: 32),
          ),
        );
    }
  }

  Widget _buildVideoPlayer(IdeaMedia media) {
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
              const Icon(
                Icons.play_circle_fill,
                size: 64,
                color: Colors.white70,
              ),
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
              itemCount: widget.idea.media.length,
              itemBuilder: (context, index) =>
                  _buildSingleMedia(widget.idea.media[index]),
            ),
          ),
          if (widget.idea.media.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.idea.media.length,
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

  Widget _buildIdeaActions() => Padding(
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
              icon: Icons.chat_bubble_outline,
              onTap: widget.onComment,
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              icon: Icons.share_outlined,
              onTap: widget.onShare,
            ),
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

  Widget _buildActionButton({
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Icon(
          icon,
          color: color ?? Colors.grey[600],
          size: 24,
        ),
      );

  Widget _buildIdeaStats() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.idea.likesCount > 0)
              Text(
                '${widget.idea.likesCount} ${_getLikesText(widget.idea.likesCount)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (widget.idea.commentsCount > 0)
              TextButton(
                onPressed: widget.onComment,
                child: Text(
                  'Показать все ${widget.idea.commentsCount} ${_getCommentsText(widget.idea.commentsCount)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      );

  Widget _buildCommentsPreview() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: widget.idea.comments
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
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
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
