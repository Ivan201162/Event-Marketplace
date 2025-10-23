import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_view/story_view.dart';

import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';

/// Виджет для отображения сторис пользователя
class StoriesWidget extends ConsumerWidget {
  const StoriesWidget(
      {super.key, required this.userId, this.isOwnProfile = false});
  final String userId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(userStoriesProvider(userId));

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: storiesAsync.when(
        data: (stories) => _buildStoriesList(context, stories),
        loading: _buildLoadingStories,
        error: (error, stack) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildStoriesList(BuildContext context, List<UserStory> stories) {
    if (stories.isEmpty && !isOwnProfile) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: stories.length + (isOwnProfile ? 1 : 0),
      itemBuilder: (context, index) {
        if (isOwnProfile && index == 0) {
          return _buildAddStoryButton(context);
        }

        final storyIndex = isOwnProfile ? index - 1 : index;
        final story = stories[storyIndex];

        return _buildStoryItem(context, story);
      },
    );
  }

  Widget _buildAddStoryButton(BuildContext context) => Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _addStory(context),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  color: Colors.grey[100],
                ),
                child: Icon(Icons.add, color: Colors.grey[600], size: 30),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Добавить',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _buildStoryItem(BuildContext context, UserStory story) {
    final isViewed = story.viewedBy.isNotEmpty;

    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _viewStory(context, story),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isViewed ? Colors.grey[300]! : Colors.blue,
                    width: 2),
              ),
              child: ClipOval(
                child: story.isVideo
                    ? Stack(
                        children: [
                          if (story.thumbnailUrl != null)
                            CachedNetworkImage(
                              imageUrl: story.thumbnailUrl!,
                              fit: BoxFit.cover,
                              width: 70,
                              height: 70,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.video_library),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.video_library),
                              ),
                            )
                          else
                            Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.video_library),
                            ),
                          const Positioned(
                            bottom: 4,
                            right: 4,
                            child: Icon(Icons.play_circle_filled,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      )
                    : story.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: story.imageUrl!,
                            fit: BoxFit.cover,
                            width: 70,
                            height: 70,
                            placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image)),
                            errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image)),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatStoryTime(story.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStories() => ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 80,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.grey[200]),
              ),
              const SizedBox(height: 4),
              Container(width: 40, height: 12, color: Colors.grey[200]),
            ],
          ),
        ),
      );

  void _addStory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                // TODO(developer): Открыть камеру для фото
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Записать видео'),
              onTap: () {
                Navigator.pop(context);
                // TODO(developer): Открыть камеру для видео
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                // TODO(developer): Открыть галерею
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewStory(BuildContext context, UserStory story) {
    final storyController = StoryController();

    final storyItems = <StoryItem>[];

    if (story.isVideo && story.videoUrl != null) {
      storyItems.add(
        StoryItem.pageVideo(
          story.videoUrl!,
          controller: storyController,
          caption: story.caption != null ? Text(story.caption!) : null,
        ),
      );
    } else if (story.imageUrl != null) {
      storyItems.add(
        StoryItem.pageImage(
          url: story.imageUrl!,
          controller: storyController,
          caption: story.caption != null ? Text(story.caption!) : null,
        ),
      );
    }

    if (storyItems.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => StoryView(
            storyItems: storyItems,
            controller: storyController,
            onComplete: () {
              Navigator.of(context).pop();
            },
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
    }
  }

  String _formatStoryTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}м';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}ч';
    } else {
      return '${difference.inDays}д';
    }
  }
}
