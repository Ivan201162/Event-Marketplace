import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/idea.dart';
import '../../providers/auth_providers.dart';
import '../../providers/ideas_providers.dart';
import '../../widgets/idea_card.dart';

/// Ideas screen with creative event ideas
class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  @override
  Widget build(BuildContext context) {
    final ideasAsync = ref.watch(ideasStreamProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/ideas/create');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(ideasStreamProvider);
            },
          ),
        ],
      ),
      body: ideasAsync.when(
        data: (ideas) {
          if (ideas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Пока нет идей',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Будьте первым, кто поделится креативной идеей!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ideasStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: ideas.length,
              itemBuilder: (context, index) {
                final idea = ideas[index];
                return IdeaCard(
                  idea: idea,
                  onTap: () => _showIdeaDetails(context, idea),
                  onLike: () => _handleLike(idea),
                  onShare: () {
                    _shareIdea(idea);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки идей',
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(ideasStreamProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIdeaDetails(BuildContext context, Idea idea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Idea details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                idea.categoryIcon,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  idea.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  idea.shortDesc,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Детали идеи',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        idea.detailedDescription ?? 'Подробное описание пока не добавлено.',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (idea.requiredMaterials.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Необходимые материалы',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: idea.requiredMaterials
                              .map((material) => Chip(
                                    label: Text(material),
                                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                  ))
                              .toList(),
                        ),
                      ],
                      if (idea.tags.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Теги',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: idea.tags
                              .map((tag) => Chip(
                                    label: Text('#$tag'),
                                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (idea.difficulty != null) ...[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Сложность',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    idea.difficultyText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (idea.estimatedDuration != null) ...[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Время',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    idea.formattedDuration,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _saveIdea(idea);
                        },
                        icon: const Icon(Icons.bookmark_border),
                        label: const Text('Сохранить'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _useIdea(idea);
                        },
                        icon: const Icon(Icons.lightbulb),
                        label: const Text('Использовать'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLike(Idea idea) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите в аккаунт для лайков')),
      );
      return;
    }

    final ideaService = ref.read(ideaServiceProvider);
    if (idea.isLikedBy(currentUser.uid)) {
      ideaService.unlikeIdea(idea.id, currentUser.uid);
    } else {
      ideaService.likeIdea(idea.id, currentUser.uid);
    }
  }

  void _shareIdea(Idea idea) {
    final shareText = 'Посмотрите эту идею в Event Marketplace: ${idea.title} - ${idea.shortDesc}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ссылка на идею скопирована: $shareText'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _saveIdea(Idea idea) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите в аккаунт для сохранения идей')),
      );
      return;
    }

    final ideaService = ref.read(ideaServiceProvider);
    ideaService.saveIdea(idea.id, currentUser.uid);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Идея сохранена в избранное')),
    );
  }

  void _useIdea(Idea idea) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите в аккаунт для использования идей')),
      );
      return;
    }

    // Переход к созданию заявки с предзаполненной идеей
    context.push('/requests/create?idea=${idea.id}');
  }
}
