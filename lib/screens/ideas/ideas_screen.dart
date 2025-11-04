import 'package:event_marketplace_app/core/app_components.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/models/idea.dart';
import 'package:event_marketplace_app/providers/ideas_provider.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Упрощенный экран идей
class IdeasScreen extends ConsumerWidget {
  const IdeasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.watch(ideasProvider).whenData((ideas) {
        debugLog("IDEAS_LOADED");
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            ref.invalidate(ideasProvider);
            await Future.delayed(const Duration(milliseconds: 500));
            debugLog("REFRESH_OK:ideas");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Обновлено'), duration: Duration(seconds: 1)),
              );
            }
          } catch (e) {
            debugLog("REFRESH_ERR:ideas:$e");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка обновления: $e')),
              );
            }
          }
        },
        child: Consumer(
          builder: (context, ref, child) {
            final ideasAsync = ref.watch(ideasProvider);
            return ideasAsync.when(
              data: (ideas) {
                if (ideas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Нет идей', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Создайте первую идею'),
                      ],
                    ),
                  );
                }
                // Вертикальный PageView для Shorts формата
                return PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: ideas.length,
                  itemBuilder: (context, index) {
                    final idea = ideas[index];
                    return _IdeaShortsCard(idea: idea);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки: $error'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-idea'),
        child: const Icon(Icons.add),
      ),
    );
  }

}

/// Карточка идеи в формате Shorts (вертикальная)
class _IdeaShortsCard extends StatelessWidget {
  const _IdeaShortsCard({required this.idea});
  final Idea idea;

  @override
  Widget build(BuildContext context) {
    // Shorts формат: вертикальное видео или квадратное фото на весь экран
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Медиа (видео или фото) - используем первый элемент из media массива
          if (idea.media.isNotEmpty)
            Image.network(
              idea.media.first,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[900],
                child: const Icon(Icons.broken_image, color: Colors.white54),
              ),
            )
          else
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.image, size: 64, color: Colors.white54),
              ),
            ),
          
          // Градиент снизу для текста
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    idea.text.isNotEmpty ? idea.text : 'Идея',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          // Действия справа
          Positioned(
            right: 16,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white, size: 32),
                  onPressed: () {
                    // TODO: Лайк
                  },
                ),
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.white, size: 32),
                  onPressed: () {
                    // TODO: Комментарии
                  },
                ),
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white, size: 32),
                  onPressed: () {
                    // TODO: Поделиться
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
