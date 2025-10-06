import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/idea.dart';
import '../services/idea_service.dart';
import '../widgets/idea_widget.dart';
import 'idea_detail_screen.dart';

/// Экран сохраненных идей
class SavedIdeasScreen extends ConsumerStatefulWidget {
  const SavedIdeasScreen({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  ConsumerState<SavedIdeasScreen> createState() => _SavedIdeasScreenState();
}

class _SavedIdeasScreenState extends ConsumerState<SavedIdeasScreen> {
  final IdeaService _ideaService = IdeaService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Сохраненные идеи'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: StreamBuilder<List<Idea>>(
          stream: _ideaService.getSavedIdeas(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            final ideas = snapshot.data ?? [];
            if (ideas.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: ideas.length,
              itemBuilder: (context, index) {
                final idea = ideas[index];
                return IdeaWidget(
                  idea: idea,
                  onTap: () => _showIdeaDetail(idea),
                  onLike: () => _likeIdea(idea),
                  onSave: () => _saveIdea(idea),
                  onShare: () => _shareIdea(idea),
                );
              },
            );
          },
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет сохраненных идей',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Сохраняйте понравившиеся идеи для быстрого доступа',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO(developer): Перейти к экрану идей
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Переход к экрану идей')),
                );
              },
              icon: const Icon(Icons.lightbulb),
              label: const Text('Просмотреть идеи'),
            ),
          ],
        ),
      );

  void _showIdeaDetail(Idea idea) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => IdeaDetailScreen(
          idea: idea,
          userId: widget.userId,
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _likeIdea(Idea idea) {
    _ideaService.likeIdea(idea.id, widget.userId);
  }

  void _saveIdea(Idea idea) {
    _ideaService.saveIdea(idea.id, widget.userId);
  }

  void _shareIdea(Idea idea) {
    // TODO(developer): Реализовать шаринг идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Идея скопирована в буфер обмена')),
    );
  }

  void _showSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск в сохраненных'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Введите поисковый запрос...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтр сохраненных'),
        content: const Text('Фильтры для сохраненных идей'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

/// Экран моих идей
class MyIdeasScreen extends ConsumerStatefulWidget {
  const MyIdeasScreen({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  ConsumerState<MyIdeasScreen> createState() => _MyIdeasScreenState();
}

class _MyIdeasScreenState extends ConsumerState<MyIdeasScreen> {
  final IdeaService _ideaService = IdeaService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Мои идеи'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createIdea,
            ),
          ],
        ),
        body: StreamBuilder<List<Idea>>(
          stream: _ideaService.getUserIdeas(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            final ideas = snapshot.data ?? [];
            if (ideas.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: ideas.length,
              itemBuilder: (context, index) {
                final idea = ideas[index];
                return IdeaWidget(
                  idea: idea,
                  onTap: () => _showIdeaDetail(idea),
                  onLike: () => _likeIdea(idea),
                  onSave: () => _saveIdea(idea),
                  onShare: () => _shareIdea(idea),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createIdea,
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет идей',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте свою первую идею',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createIdea,
              icon: const Icon(Icons.add),
              label: const Text('Создать идею'),
            ),
          ],
        ),
      );

  void _createIdea() {
    // TODO(developer): Перейти к экрану создания идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Переход к созданию идеи')),
    );
  }

  void _showIdeaDetail(Idea idea) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => IdeaDetailScreen(
          idea: idea,
          userId: widget.userId,
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _likeIdea(Idea idea) {
    _ideaService.likeIdea(idea.id, widget.userId);
  }

  void _saveIdea(Idea idea) {
    _ideaService.saveIdea(idea.id, widget.userId);
  }

  void _shareIdea(Idea idea) {
    // TODO(developer): Реализовать шаринг идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Идея скопирована в буфер обмена')),
    );
  }
}
