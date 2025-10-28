import 'package:event_marketplace_app/models/event_idea.dart';
import 'package:event_marketplace_app/services/event_idea_service.dart';
import 'package:event_marketplace_app/widgets/create_idea_dialog.dart';
import 'package:event_marketplace_app/widgets/event_idea_card.dart';
import 'package:event_marketplace_app/widgets/idea_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Лента идей мероприятий в стиле Pinterest
class EventIdeasFeed extends ConsumerStatefulWidget {
  const EventIdeasFeed({super.key, this.userId, this.showUserIdeas = false});

  final String? userId;
  final bool showUserIdeas;

  @override
  ConsumerState<EventIdeasFeed> createState() => _EventIdeasFeedState();
}

class _EventIdeasFeedState extends ConsumerState<EventIdeasFeed> {
  final EventIdeaService _ideaService = EventIdeaService();
  final ScrollController _scrollController = ScrollController();

  List<EventIdea> _ideas = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _popularTags = [];

  @override
  void initState() {
    super.initState();
    _loadIdeas();
    _loadPopularTags();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreIdeas();
    }
  }

  Future<void> _loadIdeas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<EventIdea> ideas;
      if (widget.showUserIdeas && widget.userId != null) {
        ideas = await _ideaService.getUserIdeas(widget.userId!);
      } else {
        ideas = await _ideaService.getAllIdeas(
          category: _selectedCategory,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        );
      }

      setState(() {
        _ideas = ideas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreIdeas() async {
    if (_isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      List<EventIdea> moreIdeas;
      if (widget.showUserIdeas && widget.userId != null) {
        moreIdeas = await _ideaService.getUserIdeas(widget.userId!, limit: 10);
      } else {
        moreIdeas = await _ideaService.getAllIdeas(
          limit: 10,
          category: _selectedCategory,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        );
      }

      setState(() {
        _ideas.addAll(moreIdeas);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadPopularTags() async {
    try {
      final tags = await _ideaService.getPopularTags();
      setState(() {
        _popularTags = tags;
      });
    } catch (e) {
      debugPrint('Error loading popular tags: $e');
    }
  }

  Future<void> _createIdea() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateIdeaDialog(),
    );

    if (result ?? false) {
      await _loadIdeas();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Заголовок и поиск
          _buildHeader(),

          // Популярные теги
          if (_popularTags.isNotEmpty) _buildPopularTags(),

          // Лента идей
          Expanded(child: _buildIdeasFeed()),
        ],
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.showUserIdeas ? 'Мои идеи' : 'Идеи мероприятий',
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),

                // Кнопка создания идеи
                if (!widget.showUserIdeas)
                  IconButton(
                    onPressed: _createIdea,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Создать идею',
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Поиск
            TextField(
              decoration: InputDecoration(
                hintText: 'Поиск идей...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _loadIdeas();
              },
            ),
          ],
        ),
      );

  Widget _buildPopularTags() => Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _popularTags.length,
          itemBuilder: (context, index) {
            final tag = _popularTags[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('#$tag'),
                selected: _selectedCategory == tag,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? tag : null;
                  });
                  _loadIdeas();
                },
              ),
            );
          },
        ),
      );

  Widget _buildIdeasFeed() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_ideas.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadIdeas,
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        padding: const EdgeInsets.all(16),
        itemCount: _ideas.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _ideas.length) {
            return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),),
            );
          }

          final idea = _ideas[index];
          return EventIdeaCard(
            idea: idea,
            onTap: () => _viewIdea(idea),
            onLike: () => _toggleLike(idea),
            onComment: () => _viewIdea(idea),
            onShare: () => _shareIdea(idea),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Ошибка загрузки идей',
                style: Theme.of(context).textTheme.titleLarge,),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadIdeas, child: const Text('Повторить'),),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.showUserIdeas ? 'Нет идей' : 'Нет идей мероприятий',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              widget.showUserIdeas
                  ? 'Создайте свою первую идею мероприятия'
                  : 'Специалисты еще не поделились идеями',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (!widget.showUserIdeas) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createIdea,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Создать идею'),
              ),
            ],
          ],
        ),
      );

  void _viewIdea(EventIdea idea) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(
        builder: (context) => IdeaDetailScreen(idea: idea),),);
  }

  Future<void> _toggleLike(EventIdea idea) async {
    try {
      await _ideaService.likeIdea(idea.id);
      await _loadIdeas();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),);
    }
  }

  void _shareIdea(EventIdea idea) {
    // Здесь можно добавить логику шаринга
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция шаринга будет добавлена позже'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
