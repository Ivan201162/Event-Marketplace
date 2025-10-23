import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist_story.dart';
import '../screens/story_viewer_screen.dart';

class StoriesListWidget extends ConsumerWidget {
  const StoriesListWidget(
      {super.key, required this.storyGroups, required this.userId});
  final List<SpecialistStoryGroup> storyGroups;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (storyGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: storyGroups.length,
        itemBuilder: (context, index) {
          final group = storyGroups[index];
          return _buildStoryGroup(context, group);
        },
      ),
    );
  }

  Widget _buildStoryGroup(BuildContext context, SpecialistStoryGroup group) =>
      GestureDetector(
        onTap: () => _openStories(context, group),
        child: Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              // Аватар с индикатором
              Stack(
                children: [
                  // Основной аватар
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: group.hasUnviewedStories
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      backgroundImage: group.specialistAvatar != null
                          ? NetworkImage(group.specialistAvatar!)
                          : null,
                      child: group.specialistAvatar == null
                          ? Text(
                              group.specialistName.isNotEmpty
                                  ? group.specialistName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                  ),

                  // Индикатор новых сторис
                  if (group.hasUnviewedStories)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Text(
                            '!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              // Имя специалиста
              Text(
                group.specialistName,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  void _openStories(BuildContext context, SpecialistStoryGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            StoryViewerScreen(stories: group.stories, userId: userId),
      ),
    );
  }
}

/// Виджет для отображения сторис в профиле специалиста
class SpecialistStoriesWidget extends ConsumerWidget {
  const SpecialistStoriesWidget({
    super.key,
    required this.specialistId,
    required this.userId,
    this.isOwner = false,
  });
  final String specialistId;
  final String userId;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      StreamBuilder<List<SpecialistStory>>(
        stream: _getStoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Ошибка загрузки сторис: ${snapshot.error}'));
          }

          final stories = snapshot.data ?? [];

          if (stories.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildStoriesGrid(context, stories);
        },
      );

  Widget _buildEmptyState(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.auto_stories,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              isOwner
                  ? 'У вас пока нет сторис'
                  : 'У специалиста пока нет сторис',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isOwner
                  ? 'Создайте свою первую сторис, чтобы показать работу'
                  : 'Следите за обновлениями, чтобы не пропустить новые сторис',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            if (isOwner) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _createStory(context),
                icon: const Icon(Icons.add),
                label: const Text('Создать сторис'),
              ),
            ],
          ],
        ),
      );

  Widget _buildStoriesGrid(
          BuildContext context, List<SpecialistStory> stories) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Сторис',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (isOwner)
                  IconButton(
                    onPressed: () => _createStory(context),
                    icon: const Icon(Icons.add),
                    tooltip: 'Создать сторис',
                  ),
              ],
            ),
          ),

          // Сетка сторис
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return _buildStoryThumbnail(context, story);
            },
          ),
        ],
      );

  Widget _buildStoryThumbnail(BuildContext context, SpecialistStory story) =>
      GestureDetector(
        onTap: () => _openStory(context, story),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: story.hasViewed(userId)
                  ? Colors.grey.shade300
                  : Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Контент
                if (story.contentType == StoryContentType.image)
                  Image.network(
                    story.contentUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error)),
                  )
                else if (story.contentType == StoryContentType.video)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.play_circle_outline,
                          color: Colors.white, size: 32),
                    ),
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.purple, Colors.blue, Colors.green],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        story.text ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                // Индикатор типа контента
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(story.contentTypeIcon,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),

                // Индикатор просмотра
                if (story.hasViewed(userId))
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Stream<List<SpecialistStory>> _getStoriesStream() {
    // TODO(developer): Реализовать получение потока сторис из сервиса
    return Stream.value([]);
  }

  void _createStory(BuildContext context) {
    // TODO(developer): Реализовать создание сторис
    Navigator.pushNamed(
      context,
      '/create-story',
      arguments: {
        'specialistId': specialistId,
        'specialistName':
            'Имя специалиста', // TODO(developer): Получить из контекста
        'specialistAvatar': null,
      },
    );
  }

  void _openStory(BuildContext context, SpecialistStory story) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            StoryViewerScreen(stories: [story], userId: userId),
      ),
    );
  }
}
