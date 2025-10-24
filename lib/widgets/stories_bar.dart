import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story.dart';
import '../providers/feed_providers.dart';
import 'story_circle.dart';

/// Горизонтальная полоса Stories
class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: storiesAsync.when(
        data: (stories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: stories.length + 1, // +1 для кнопки добавления
          itemBuilder: (context, index) {
            if (index == 0) {
              // Кнопка добавления своей Story
              return const _AddStoryButton();
            }
            
            final story = stories[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: StoryCircle(
                story: story,
                onTap: () => _openStoryViewer(context, story),
              ),
            );
          },
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Ошибка загрузки Stories: $error'),
        ),
      ),
    );
  }

  void _openStoryViewer(BuildContext context, Story story) {
    // TODO: Открыть полноэкранный просмотр Story
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открытие Story: ${story.id}')),
    );
  }
}

/// Кнопка добавления новой Story
class _AddStoryButton extends StatelessWidget {
  const _AddStoryButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _showAddStoryDialog(context),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.add,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showAddStoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить Story'),
        content: const Text('Выберите способ добавления Story'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Открыть камеру
            },
            child: const Text('Камера'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Открыть галерею
            },
            child: const Text('Галерея'),
          ),
        ],
      ),
    );
  }
}
