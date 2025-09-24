import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/specialist_story.dart';
import '../services/specialist_content_service.dart';

/// Виджет сторис специалиста
class SpecialistStoriesWidget extends ConsumerWidget {
  const SpecialistStoriesWidget({
    super.key,
    required this.specialistId,
    this.isOwnProfile = false,
    this.onAddStory,
    this.onStoryTap,
  });

  final String specialistId;
  final bool isOwnProfile;
  final VoidCallback? onAddStory;
  final Function(SpecialistStory)? onStoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return FutureBuilder<List<SpecialistStory>>(
      future: ref.read(specialistContentServiceProvider).getActiveStories(specialistId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stories = snapshot.data ?? [];
        
        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stories.length + (isOwnProfile ? 1 : 0),
            itemBuilder: (context, index) {
              // Кнопка добавления сторис для владельца профиля
              if (isOwnProfile && index == 0) {
                return _buildAddStoryButton(context, theme);
              }
              
              final storyIndex = isOwnProfile ? index - 1 : index;
              final story = stories[storyIndex];
              
              return _buildStoryItem(context, theme, story);
            },
          ),
        );
      },
    );
  }

  Widget _buildAddStoryButton(BuildContext context, ThemeData theme) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAddStory,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
                color: theme.colorScheme.surface,
              ),
              child: Icon(
                Icons.add,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Добавить',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(BuildContext context, ThemeData theme, SpecialistStory story) {
    final isViewed = false; // В реальном приложении здесь была бы проверка просмотра
    
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => onStoryTap?.call(story),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isViewed 
                      ? theme.colorScheme.outline.withOpacity(0.3)
                      : theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: story.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: story.thumbnailUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surface,
                          child: Icon(
                            story.isVideo ? Icons.videocam : Icons.image,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surface,
                          child: Icon(
                            story.isVideo ? Icons.videocam : Icons.image,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surface,
                        child: Icon(
                          story.isVideo ? Icons.videocam : Icons.image,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getStoryTime(story.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getStoryTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes}м';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч';
    } else {
      return '${difference.inDays}д';
    }
  }
}

/// Провайдер сервиса контента специалиста
final specialistContentServiceProvider = Provider<SpecialistContentService>((ref) {
  return SpecialistContentService();
});
