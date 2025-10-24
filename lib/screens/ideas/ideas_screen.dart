import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ideas_providers.dart';
import '../../widgets/idea_card.dart';
import '../../widgets/idea_filters.dart';
import 'create_idea_sheet.dart';

/// Экран ленты идей
class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final ideasState = ref.watch(ideasProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          IdeaFilters(
            selectedFilter: _selectedFilter,
            selectedSort: _selectedSort,
            onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
            onSortChanged: (sort) => setState(() => _selectedSort = sort),
          ),
          
          // Лента идей
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(ideasProvider.notifier).refreshIdeas();
              },
              child: ideasState.when(
                data: (ideas) => ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: ideas.length,
                  itemBuilder: (context, index) {
                    final idea = ideas[index];
                    return IdeaCard(
                      idea: idea,
                      onTap: () => _openIdeaDetails(idea.id),
                      onLike: () => _likeIdea(idea.id),
                      onComment: () => _commentIdea(idea.id),
                      onSave: () => _saveIdea(idea.id),
                      onShare: () => _shareIdea(idea.id),
                    );
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Ошибка загрузки идей: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(ideasProvider.notifier).refreshIdeas(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createIdea(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск идей'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите запрос...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(ideasProvider.notifier).searchIdeas(_searchQuery);
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры идей'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Все'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: const Text('Популярные'),
              leading: Radio<String>(
                value: 'popular',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: const Text('Новые'),
              leading: Radio<String>(
                value: 'new',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: const Text('Тренды'),
              leading: Radio<String>(
                value: 'trending',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(ideasProvider.notifier).filterIdeas(_selectedFilter);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _createIdea() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateIdeaSheet(),
    );
  }

  void _openIdeaDetails(String ideaId) {
    // TODO: Открыть детали идеи
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открытие идеи $ideaId...')),
    );
  }

  void _likeIdea(String ideaId) {
    ref.read(ideasProvider.notifier).likeIdea(ideaId);
  }

  void _commentIdea(String ideaId) {
    // TODO: Открыть комментарии
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открытие комментариев для идеи $ideaId...')),
    );
  }

  void _saveIdea(String ideaId) {
    ref.read(ideasProvider.notifier).saveIdea(ideaId);
  }

  void _shareIdea(String ideaId) {
    ref.read(ideasProvider.notifier).shareIdea(ideaId);
  }
}