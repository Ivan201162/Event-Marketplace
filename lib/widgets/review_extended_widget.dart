import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

import '../models/review_extended.dart';

/// Виджет расширенного отзыва
class ReviewExtendedWidget extends StatefulWidget {
  const ReviewExtendedWidget({
    super.key,
    required this.review,
    this.currentUserId,
    this.onLike,
    this.onShare,
    this.onReport,
    this.onViewMedia,
  });
  final ReviewExtended review;
  final String? currentUserId;
  final void Function(String)? onLike;
  final void Function(String)? onShare;
  final void Function(String)? onReport;
  final void Function(String)? onViewMedia;

  @override
  State<ReviewExtendedWidget> createState() => _ReviewExtendedWidgetState();
}

class _ReviewExtendedWidgetState extends State<ReviewExtendedWidget> {
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с информацией о пользователе
              _buildHeader(),

              const SizedBox(height: 12),

              // Рейтинг
              _buildRating(),

              const SizedBox(height: 12),

              // Комментарий
              if (widget.review.comment.isNotEmpty) ...[
                Text(
                  widget.review.comment,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
              ],

              // Медиа
              if (widget.review.media.isNotEmpty) ...[
                _buildMediaGrid(),
                const SizedBox(height: 12),
              ],

              // Теги
              if (widget.review.tags.isNotEmpty) ...[
                _buildTags(),
                const SizedBox(height: 12),
              ],

              // Детальная статистика
              _buildDetailedStats(),

              const SizedBox(height: 12),

              // Действия
              _buildActions(),

              const SizedBox(height: 8),

              // Информация о дате
              _buildDateInfo(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.review.customerPhotoUrl.isNotEmpty
                ? CachedNetworkImageProvider(widget.review.customerPhotoUrl)
                : null,
            child: widget.review.customerPhotoUrl.isEmpty
                ? Text(
                    widget.review.customerName.isNotEmpty
                        ? widget.review.customerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.review.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.review.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ],
                  ],
                ),
                Text(
                  _formatDate(widget.review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Поделиться'),
                  ],
                ),
              ),
              if (widget.currentUserId != null) ...[
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Пожаловаться'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      );

  Widget _buildRating() => Row(
        children: [
          ...List.generate(
            5,
            (index) => Icon(
              index < widget.review.rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.review.rating.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  Widget _buildMediaGrid() {
    final photos = widget.review.photos;
    final videos = widget.review.videos;
    final allMedia = [...photos, ...videos];

    if (allMedia.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Медиа (${allMedia.length})',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allMedia.length,
            itemBuilder: (context, index) {
              final media = allMedia[index];
              return GestureDetector(
                onTap: () => _showMediaViewer(media, allMedia),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: media.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                        ),
                        if (media.type == MediaType.video)
                          const Positioned.fill(
                            child: Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTags() => Wrap(
        spacing: 6,
        runSpacing: 4,
        children: widget.review.tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      );

  Widget _buildDetailedStats() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Качество',
                    widget.review.stats.quality,
                    Icons.star,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Общение',
                    widget.review.stats.communication,
                    Icons.chat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Пунктуальность',
                    widget.review.stats.punctuality,
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Цена/Качество',
                    widget.review.stats.value,
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatItem(String label, double value, IconData icon) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value > 0 ? value.toStringAsFixed(1) : '-',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  Widget _buildActions() => Row(
        children: [
          // Лайк
          GestureDetector(
            onTap: () => widget.onLike?.call(widget.review.id),
            child: Row(
              children: [
                Icon(
                  widget.review.isLikedBy(widget.currentUserId ?? '')
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.review.isLikedBy(widget.currentUserId ?? '')
                      ? Colors.red
                      : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.review.likesCount.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Просмотры
          Row(
            children: [
              Icon(
                Icons.visibility,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                widget.review.stats.viewsCount.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Полезность
          if (widget.review.stats.helpfulnessScore > 0)
            Row(
              children: [
                Icon(
                  Icons.thumb_up,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${(widget.review.stats.helpfulnessScore * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
        ],
      );

  Widget _buildDateInfo() => Row(
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Опубликован: ${_formatDate(widget.review.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (widget.review.updatedAt != widget.review.createdAt) ...[
            const SizedBox(width: 8),
            Text(
              'Обновлен: ${_formatDate(widget.review.updatedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      );

  void _showMediaViewer(ReviewMedia media, List<ReviewMedia> allMedia) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MediaViewerScreen(
          media: media,
          allMedia: allMedia,
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        widget.onShare?.call(widget.review.id);
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  void _showReportDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пожаловаться на отзыв'),
        content: const Text('Выберите причину жалобы:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onReport?.call(widget.review.id);
            },
            child: const Text('Пожаловаться'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

/// Экран просмотра медиа
class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.media,
    required this.allMedia,
  });
  final ReviewMedia media;
  final List<ReviewMedia> allMedia;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allMedia.indexOf(widget.media);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '${_currentIndex + 1} из ${widget.allMedia.length}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: widget.allMedia.length,
          itemBuilder: (context, index) {
            final media = widget.allMedia[index];
            return _buildMediaView(media);
          },
        ),
      );

  Widget _buildMediaView(ReviewMedia media) {
    if (media.type == MediaType.photo) {
      return PhotoView(
        imageProvider: CachedNetworkImageProvider(media.url),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      );
    } else {
      return _buildVideoView(media);
    }
  }

  Widget _buildVideoView(ReviewMedia media) => Center(
        child: FutureBuilder<VideoPlayerController>(
          future: _initializeVideoController(media.url),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return const Text('Ошибка загрузки видео');
            }

            final controller = snapshot.data!;
            return AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            );
          },
        ),
      );

  Future<VideoPlayerController> _initializeVideoController(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    return controller;
  }
}
