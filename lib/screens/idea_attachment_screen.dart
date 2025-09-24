import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../providers/event_ideas_providers.dart';
import '../widgets/event_idea_card.dart';

/// Экран для прикрепления идей к заявке
class IdeaAttachmentScreen extends ConsumerStatefulWidget {
  const IdeaAttachmentScreen({
    super.key,
    required this.onIdeasSelected,
    this.selectedIdeas = const [],
  });

  final Function(List<EventIdea>) onIdeasSelected;
  final List<EventIdea> selectedIdeas;

  @override
  ConsumerState<IdeaAttachmentScreen> createState() => _IdeaAttachmentScreenState();
}

class _IdeaAttachmentScreenState extends ConsumerState<IdeaAttachmentScreen> {
  final Set<String> _selectedIdeaIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIdeaIds.addAll(widget.selectedIdeas.map((idea) => idea.id));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ideasAsync = ref.watch(filteredIdeasProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Выберите идеи'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          if (_selectedIdeaIds.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                'Готово (${_selectedIdeaIds.length})',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск идей...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(ideasFiltersProvider.notifier).updateSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                ref.read(ideasFiltersProvider.notifier).updateSearchQuery(value);
              },
            ),
          ),

          // Счетчик выбранных идей
          if (_selectedIdeaIds.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.primaryColor.withOpacity(0.1),
              child: Text(
                'Выбрано идей: ${_selectedIdeaIds.length}',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Список идей
          Expanded(
            child: ideasAsync.when(
              data: (ideas) => _buildIdeasList(ideas),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error),
            ),
          ),
        ],
      ),
    );
  }

  /// Список идей
  Widget _buildIdeasList(List<EventIdea> ideas) {
    if (ideas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Идей не найдено',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить поисковый запрос',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ideas.length,
      itemBuilder: (context, index) {
        final idea = ideas[index];
        final isSelected = _selectedIdeaIds.contains(idea.id);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Stack(
            children: [
              EventIdeaCard(
                idea: idea,
                onTap: () => _toggleIdeaSelection(idea),
                onLike: () {}, // Отключаем лайки в режиме выбора
                onSave: () {}, // Отключаем сохранение в режиме выбора
                onShare: () {}, // Отключаем поделиться в режиме выбора
              ),
              
              // Индикатор выбора
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleIdeaSelection(idea),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Виджет ошибки
  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(filteredIdeasProvider),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  /// Переключить выбор идеи
  void _toggleIdeaSelection(EventIdea idea) {
    setState(() {
      if (_selectedIdeaIds.contains(idea.id)) {
        _selectedIdeaIds.remove(idea.id);
      } else {
        _selectedIdeaIds.add(idea.id);
      }
    });
  }

  /// Подтвердить выбор
  void _confirmSelection() {
    final selectedIdeas = ref.read(filteredIdeasProvider).value
        ?.where((idea) => _selectedIdeaIds.contains(idea.id))
        .toList() ?? [];
    
    widget.onIdeasSelected(selectedIdeas);
    Navigator.of(context).pop();
  }
}

/// Диалог выбора идей
class IdeaSelectionDialog extends StatelessWidget {
  const IdeaSelectionDialog({
    super.key,
    required this.onIdeasSelected,
    this.selectedIdeas = const [],
  });

  final Function(List<EventIdea>) onIdeasSelected;
  final List<EventIdea> selectedIdeas;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: IdeaAttachmentScreen(
          onIdeasSelected: onIdeasSelected,
          selectedIdeas: selectedIdeas,
        ),
      ),
    );
  }
}

/// Виджет для отображения выбранных идей
class SelectedIdeasWidget extends StatelessWidget {
  const SelectedIdeasWidget({
    super.key,
    required this.ideas,
    required this.onRemoveIdea,
    this.onTap,
  });

  final List<EventIdea> ideas;
  final Function(EventIdea) onRemoveIdea;
  final Function(EventIdea)? onTap;

  @override
  Widget build(BuildContext context) {
    if (ideas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выбранные идеи (${ideas.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ideas.length,
              itemBuilder: (context, index) {
                final idea = ideas[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      // Миниатюра идеи
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onTap?.call(idea),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: idea.mainImage != null
                                  ? Image.network(
                                      idea.mainImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image_not_supported),
                                    )
                                  : const Icon(Icons.image),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Название идеи
                      Text(
                        idea.title,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      
                      // Кнопка удаления
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => onRemoveIdea(idea),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
