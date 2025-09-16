import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_profile_extended.dart';
import '../providers/customer_profile_extended_providers.dart';
import '../services/customer_profile_extended_service.dart';
import '../widgets/note_card_widget.dart';
import '../widgets/note_editor_widget.dart';
import '../widgets/note_filter_widget.dart';

/// Экран управления заметками заказчика
class CustomerNotesScreen extends ConsumerStatefulWidget {
  final String userId;

  const CustomerNotesScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<CustomerNotesScreen> createState() =>
      _CustomerNotesScreenState();
}

class _CustomerNotesScreenState extends ConsumerState<CustomerNotesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(customerNotesProvider(widget.userId));
    final statsAsync = ref.watch(customerProfileStatsProvider(widget.userId));
    final noteFilters = ref.watch(noteFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все заметки', icon: Icon(Icons.note)),
            Tab(text: 'Закреплённые', icon: Icon(Icons.push_pin)),
            Tab(text: 'По тегам', icon: Icon(Icons.tag)),
          ],
        ),
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
      body: Column(
        children: [
          // Статистика
          statsAsync.when(
            data: (stats) => _buildStatsCard(stats),
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          // Контент по вкладкам
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllNotesTab(notesAsync),
                _buildPinnedNotesTab(),
                _buildTagsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(CustomerProfileStats stats) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Всего заметок', stats.totalNotes, Icons.note),
            _buildStatItem('Закреплённых', stats.pinnedNotes, Icons.push_pin),
            _buildStatItem('Тегов', stats.totalTags, Icons.tag),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAllNotesTab(AsyncValue<List<CustomerNote>> notesAsync) {
    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return _buildEmptyState(
            'Нет заметок',
            'Создайте заметку, чтобы сохранить важную информацию',
            Icons.note_outlined,
          );
        }

        // Сортируем заметки: сначала закреплённые, потом по дате обновления
        final sortedNotes = List<CustomerNote>.from(notes);
        sortedNotes.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: sortedNotes.length,
          itemBuilder: (context, index) {
            final note = sortedNotes[index];
            return NoteCardWidget(
              note: note,
              onTap: () => _showNoteDetails(note),
              onEdit: () => _showEditNoteDialog(note),
              onDelete: () => _deleteNote(note),
              onTogglePin: () => _togglePin(note),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildPinnedNotesTab() {
    final pinnedNotesAsync = ref.watch(pinnedNotesProvider(widget.userId));

    return pinnedNotesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return _buildEmptyState(
            'Нет закреплённых заметок',
            'Закрепите важные заметки, чтобы они всегда были на виду',
            Icons.push_pin_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return NoteCardWidget(
              note: note,
              onTap: () => _showNoteDetails(note),
              onEdit: () => _showEditNoteDialog(note),
              onDelete: () => _deleteNote(note),
              onTogglePin: () => _togglePin(note),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTagsTab() {
    final tagsAsync = ref.watch(userTagsProvider(widget.userId));

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) {
          return _buildEmptyState(
            'Нет тегов',
            'Добавьте теги к заметкам, чтобы лучше их организовывать',
            Icons.tag_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            return _buildTagCard(tag);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTagCard(String tag) {
    final notesByTagAsync = ref.watch(notesByTagProvider((widget.userId, tag)));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.tag),
        title: Text(tag),
        subtitle: notesByTagAsync.when(
          data: (notes) => Text('${notes.length} заметок'),
          loading: () => const Text('Загрузка...'),
          error: (_, __) => const Text('Ошибка'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showNotesByTag(tag),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Ошибка: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(customerNotesProvider(widget.userId)),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => NoteEditorWidget(
        userId: widget.userId,
        onNoteSaved: () {
          ref.refresh(customerNotesProvider(widget.userId));
          ref.refresh(customerProfileStatsProvider(widget.userId));
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск заметок'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Введите запрос для поиска...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                Navigator.pop(context);
                _showSearchResults(query);
              }
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
      builder: (context) => NoteFilterWidget(
        currentFilters: ref.read(noteFiltersProvider),
        onFiltersChanged: (filters) {
          ref.read(noteFiltersProvider.notifier).state = filters;
        },
      ),
    );
  }

  void _showNoteDetails(CustomerNote note) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
            children: [
              AppBar(
                title: Text(note.title),
                actions: [
                  IconButton(
                    icon: Icon(note.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined),
                    onPressed: () {
                      Navigator.pop(context);
                      _togglePin(note);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditNoteDialog(note);
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.content,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 4,
                          children: note.tags
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    labelStyle: const TextStyle(fontSize: 12),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Создано: ${_formatDate(note.createdAt)}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                          if (note.updatedAt != note.createdAt) ...[
                            const SizedBox(width: 16),
                            Text(
                              'Обновлено: ${_formatDate(note.updatedAt)}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNoteDialog(CustomerNote note) {
    showDialog(
      context: context,
      builder: (context) => NoteEditorWidget(
        userId: widget.userId,
        existingNote: note,
        onNoteSaved: () {
          ref.refresh(customerNotesProvider(widget.userId));
          ref.refresh(customerProfileStatsProvider(widget.userId));
        },
      ),
    );
  }

  void _deleteNote(CustomerNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ref.read(customerProfileExtendedServiceProvider);
              await service.removeNote(widget.userId, note.id);
              ref.refresh(customerNotesProvider(widget.userId));
              ref.refresh(customerProfileStatsProvider(widget.userId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _togglePin(CustomerNote note) async {
    final service = ref.read(customerProfileExtendedServiceProvider);
    final updatedNote = note.copyWith(isPinned: !note.isPinned);
    await service.updateNote(widget.userId, updatedNote);
    ref.refresh(customerNotesProvider(widget.userId));
    ref.refresh(customerProfileStatsProvider(widget.userId));
  }

  void _showNotesByTag(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotesByTagScreen(
          userId: widget.userId,
          tag: tag,
        ),
      ),
    );
  }

  void _showSearchResults(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteSearchResultsScreen(
          userId: widget.userId,
          query: query,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Экран заметок по тегу
class NotesByTagScreen extends ConsumerWidget {
  final String userId;
  final String tag;

  const NotesByTagScreen({
    super.key,
    required this.userId,
    required this.tag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesByTagProvider((userId, tag)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Заметки: $tag'),
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text('Нет заметок с этим тегом'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCardWidget(
                note: note,
                onTap: () => _showNoteDetails(context, note),
                onEdit: () => _showEditNoteDialog(context, ref, note),
                onDelete: () => _deleteNote(context, ref, note),
                onTogglePin: () => _togglePin(context, ref, note),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }

  void _showNoteDetails(BuildContext context, CustomerNote note) {
    // TODO: Показать детали заметки
  }

  void _showEditNoteDialog(
      BuildContext context, WidgetRef ref, CustomerNote note) {
    // TODO: Редактировать заметку
  }

  void _deleteNote(BuildContext context, WidgetRef ref, CustomerNote note) {
    // TODO: Удалить заметку
  }

  void _togglePin(BuildContext context, WidgetRef ref, CustomerNote note) {
    // TODO: Переключить закрепление
  }
}

/// Экран результатов поиска заметок
class NoteSearchResultsScreen extends ConsumerWidget {
  final String userId;
  final String query;

  const NoteSearchResultsScreen({
    super.key,
    required this.userId,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(searchNotesProvider((userId, query)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Результаты поиска: $query'),
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text('Ничего не найдено'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCardWidget(
                note: note,
                onTap: () => _showNoteDetails(context, note),
                onEdit: () => _showEditNoteDialog(context, ref, note),
                onDelete: () => _deleteNote(context, ref, note),
                onTogglePin: () => _togglePin(context, ref, note),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }

  void _showNoteDetails(BuildContext context, CustomerNote note) {
    // TODO: Показать детали заметки
  }

  void _showEditNoteDialog(
      BuildContext context, WidgetRef ref, CustomerNote note) {
    // TODO: Редактировать заметку
  }

  void _deleteNote(BuildContext context, WidgetRef ref, CustomerNote note) {
    // TODO: Удалить заметку
  }

  void _togglePin(BuildContext context, WidgetRef ref, CustomerNote note) {
    // TODO: Переключить закрепление
  }
}
