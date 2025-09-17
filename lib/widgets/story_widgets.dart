import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:event_marketplace_app/models/story.dart';
import 'package:event_marketplace_app/services/story_service.dart';
import 'package:event_marketplace_app/providers/story_providers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Виджет для отображения сториса
class StoryWidget extends ConsumerWidget {
  final Story story;
  final VoidCallback? onTap;
  final bool showProgress;

  const StoryWidget({
    super.key,
    required this.story,
    this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final timeLeft = story.expiresAt.difference(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: story.isViewedBy('current_user') ? Colors.grey : Colors.blue,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // Медиа контент
              if (story.type == StoryType.image)
                Image.network(
                  story.mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                )
              else if (story.type == StoryType.video)
                Stack(
                  children: [
                    if (story.thumbnailUrl != null)
                      Image.network(
                        story.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child:
                                const Icon(Icons.videocam, color: Colors.grey),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.videocam, color: Colors.grey),
                      ),
                    const Positioned(
                      bottom: 4,
                      right: 4,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.text_fields, color: Colors.grey),
                ),

              // Прогресс истечения
              if (showProgress && timeLeft.inHours > 0)
                Positioned(
                  top: 4,
                  left: 4,
                  right: 4,
                  child: LinearProgressIndicator(
                    value: 1.0 - (timeLeft.inMinutes / (24 * 60)),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 2,
                  ),
                ),

              // Индикатор просмотра
              if (story.isViewedBy('current_user'))
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для создания сториса
class CreateStoryWidget extends ConsumerStatefulWidget {
  final String specialistId;
  final String specialistName;
  final String? specialistPhotoUrl;
  final VoidCallback? onStoryCreated;

  const CreateStoryWidget({
    super.key,
    required this.specialistId,
    required this.specialistName,
    this.specialistPhotoUrl,
    this.onStoryCreated,
  });

  @override
  ConsumerState<CreateStoryWidget> createState() => _CreateStoryWidgetState();
}

class _CreateStoryWidgetState extends ConsumerState<CreateStoryWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FloatingActionButton(
      onPressed: _isUploading ? null : _showCreateStoryDialog,
      child: _isUploading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Icon(Icons.add),
    );
  }

  void _showCreateStoryDialog() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () => _createStory(StoryType.image, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () => _createStory(StoryType.image, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(l10n.takeVideo),
              onTap: () => _createStory(StoryType.video, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: Text(l10n.chooseVideoFromGallery),
              onTap: () => _createStory(StoryType.video, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createStory(StoryType type, ImageSource source) async {
    Navigator.of(context).pop();

    try {
      setState(() {
        _isUploading = true;
      });

      final XFile? file = await _imagePicker.pickMedia(
        mediaType: type == StoryType.image ? MediaType.image : MediaType.video,
        source: source,
      );

      if (file == null) return;

      final service = ref.read(storyServiceProvider);
      await service.createStory(
        specialistId: widget.specialistId,
        specialistName: widget.specialistName,
        specialistPhotoUrl: widget.specialistPhotoUrl,
        type: type,
        mediaFile: file,
      );

      widget.onStoryCreated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.storyCreatedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorCreatingStory}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}

/// Виджет для отображения списка сторисов
class StoriesListWidget extends ConsumerWidget {
  final List<Story> stories;
  final Function(Story)? onStoryTap;

  const StoriesListWidget({
    super.key,
    required this.stories,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StoryWidget(
              story: story,
              onTap: () => onStoryTap?.call(story),
            ),
          );
        },
      ),
    );
  }
}

/// Виджет для просмотра сториса в полноэкранном режиме
class StoryViewerWidget extends ConsumerStatefulWidget {
  final Story story;
  final VoidCallback? onClose;

  const StoryViewerWidget({
    super.key,
    required this.story,
    this.onClose,
  });

  @override
  ConsumerState<StoryViewerWidget> createState() => _StoryViewerWidgetState();
}

class _StoryViewerWidgetState extends ConsumerState<StoryViewerWidget> {
  @override
  void initState() {
    super.initState();
    _markAsViewed();
  }

  void _markAsViewed() async {
    try {
      final service = ref.read(storyServiceProvider);
      await service.markStoryAsViewed(
        storyId: widget.story.id,
        userId: 'current_user', // TODO: Получить реальный ID пользователя
      );
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Медиа контент
          Center(
            child: widget.story.type == StoryType.image
                ? Image.network(
                    widget.story.mediaUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 64),
                      );
                    },
                  )
                : widget.story.type == StoryType.video
                    ? const Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 64),
                      )
                    : Center(
                        child: Text(
                          widget.story.caption ?? '',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                      ),
          ),

          // Заголовок
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.story.specialistPhotoUrl != null
                      ? NetworkImage(widget.story.specialistPhotoUrl!)
                      : null,
                  child: widget.story.specialistPhotoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.story.specialistName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(widget.story.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Подпись
          if (widget.story.caption != null && widget.story.caption!.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.story.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

          // Действия
          Positioned(
            bottom: 40,
            right: 16,
            child: Column(
              children: [
                IconButton(
                  onPressed: () => _likeStory(),
                  icon: Icon(
                    widget.story.likes > 0
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                Text(
                  widget.story.likes.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _likeStory() async {
    try {
      final service = ref.read(storyServiceProvider);
      await service.likeStory(
        storyId: widget.story.id,
        userId: 'current_user', // TODO: Получить реальный ID пользователя
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка лайка: $e')),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }
}
