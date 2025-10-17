import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/idea.dart';
import '../providers/ideas_provider.dart';

/// Экран идей (Pinterest-стиль)
class IdeasScreen extends ConsumerWidget {
  const IdeasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasAsync = ref.watch(ideasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateIdeaDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ideasAsync.when(
          data: (ideas) {
            if (ideas.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Нет идей',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Создайте первую идею или подпишитесь на специалистов',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ideasProvider);
              },
              child: _buildIdeasGrid(context, ideas, ref),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки идей',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdeasGrid(
    BuildContext context,
    List<Idea> ideas,
    WidgetRef ref,
  ) =>
      Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: ideas.length,
          itemBuilder: (context, index) {
            final idea = ideas[index];
            return _buildIdeaCard(context, idea, ref);
          },
        ),
      );

  Widget _buildIdeaCard(BuildContext context, Idea idea, WidgetRef ref) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showIdeaDetails(context, idea),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    image: idea.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(idea.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: idea.imageUrl == null ? Colors.grey[200] : null,
                  ),
                  child: idea.imageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        )
                      : Stack(
                          children: [
                            // Кнопка сохранения
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _toggleSave(context, idea),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    idea.isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              // Контент
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок
                      Text(
                        idea.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Описание
                      Expanded(
                        child: Text(
                          idea.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Автор и действия
                      Row(
                        children: [
                          // Аватар автора
                          GestureDetector(
                            onTap: () =>
                                context.push('/profile/${idea.authorId}'),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              backgroundImage: idea.authorAvatar != null
                                  ? NetworkImage(idea.authorAvatar!)
                                  : null,
                              child: idea.authorAvatar == null
                                  ? const Icon(Icons.person, size: 12)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Имя автора
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  context.push('/profile/${idea.authorId}'),
                              child: Text(
                                idea.authorName ?? 'Неизвестный автор',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Лайк
                          GestureDetector(
                            onTap: () => _toggleLike(context, idea),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  idea.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: idea.isLiked
                                      ? Colors.red
                                      : Colors.grey[600],
                                  size: 16,
                                ),
                                if (idea.likeCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    idea.likeCount.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  void _toggleLike(BuildContext context, Idea idea) {
    // TODO: Реализовать лайк через Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(idea.isLiked ? 'Лайк убран' : 'Лайк поставлен')),
    );
  }

  void _toggleSave(BuildContext context, Idea idea) {
    // TODO: Реализовать сохранение через Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(idea.isSaved ? 'Убрано из сохранённых' : 'Сохранено'),
      ),
    );
  }

  void _showIdeaDetails(BuildContext context, Idea idea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Изображение
              if (idea.imageUrl != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(idea.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Заголовок
              Text(
                idea.title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Автор
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    backgroundImage: idea.authorAvatar != null
                        ? NetworkImage(idea.authorAvatar!)
                        : null,
                    child: idea.authorAvatar == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    idea.authorName ?? 'Неизвестный автор',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Описание
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    idea.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),

              // Действия
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleLike(context, idea),
                      icon: Icon(
                        idea.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: idea.isLiked ? Colors.red : null,
                      ),
                      label: Text('${idea.likeCount}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCommentsDialog(context, idea),
                      icon: const Icon(Icons.comment),
                      label: Text('${idea.commentCount}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleSave(context, idea),
                      icon: Icon(
                        idea.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: idea.isSaved ? Colors.blue : null,
                      ),
                      label: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentsDialog(BuildContext context, Idea idea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Комментарии',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    // TODO: Загрузить комментарии из Firestore
                    Center(
                      child: Text('Комментарии загружаются...'),
                    ),
                  ],
                ),
              ),
              // Поле ввода комментария
              TextField(
                decoration: InputDecoration(
                  hintText: 'Добавить комментарий...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      // TODO: Отправить комментарий
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateIdeaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать идею'),
        content: const Text('Функция создания идей в разработке'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
