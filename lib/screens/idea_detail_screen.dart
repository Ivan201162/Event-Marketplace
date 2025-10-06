import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../models/idea_comment.dart';
import '../services/event_ideas_service.dart';
import '../services/idea_booking_service.dart';
import '../widgets/idea_comment_widget.dart';

/// Экран детального просмотра идеи
class IdeaDetailScreen extends ConsumerStatefulWidget {
  const IdeaDetailScreen({
    super.key,
    required this.idea,
    this.userId,
  });

  final EventIdea idea;
  final String? userId;

  @override
  ConsumerState<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends ConsumerState<IdeaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventIdeasService _ideasService = EventIdeasService();
  final IdeaBookingService _bookingService = IdeaBookingService();

  List<IdeaComment> _comments = [];
  List<EventIdea> _similarIdeas = [];
  bool _isLoadingComments = true;
  bool _isLoadingSimilar = true;
  bool _isLiked = false;
  bool _isFavorite = false;
  final bool _isAttachedToBooking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadComments(),
      _loadSimilarIdeas(),
      _loadUserInteractions(),
    ]);
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _ideasService.getIdeaComments(widget.idea.id);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } on Exception {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _loadSimilarIdeas() async {
    try {
      final ideas = await _ideasService.getSimilarIdeas(widget.idea.id);
      setState(() {
        _similarIdeas = ideas;
        _isLoadingSimilar = false;
      });
    } on Exception {
      setState(() {
        _isLoadingSimilar = false;
      });
    }
  }

  Future<void> _loadUserInteractions() async {
    if (widget.userId == null) return;

    try {
      final futures = await Future.wait([
        _ideasService.isIdeaLiked(widget.idea.id, widget.userId!),
        _ideasService.isIdeaInFavorites(widget.idea.id, widget.userId!),
      ]);

      setState(() {
        _isLiked = futures[0];
        _isFavorite = futures[1];
      });
    } on Exception {
      // Игнорируем ошибки
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.idea.title),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          actions: [
            IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
            ),
            IconButton(
              onPressed: _shareIdea,
              icon: const Icon(Icons.share),
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'attach_to_booking',
                  child: Row(
                    children: [
                      Icon(Icons.attach_file),
                      SizedBox(width: 8),
                      Text('Прикрепить к заявке'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report),
                      SizedBox(width: 8),
                      Text('Пожаловаться'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Изображение
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.idea.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            // Контент
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  _buildCommentsTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Детали', icon: Icon(Icons.info)),
            Tab(text: 'Комментарии', icon: Icon(Icons.comment)),
          ],
        ),
      );

  Widget _buildDetailsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и категория
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.idea.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Chip(
                  label: Text(widget.idea.category.displayName),
                  avatar: Text(widget.idea.category.emoji),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Описание
            Text(
              widget.idea.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),

            // Детали
            _buildIdeaDetails(),

            const SizedBox(height: 24),

            // Теги
            if (widget.idea.tags.isNotEmpty) ...[
              Text(
                'Теги',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.idea.tags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Похожие идеи
            if (_similarIdeas.isNotEmpty) ...[
              Text(
                'Похожие идеи',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _similarIdeas.length,
                  itemBuilder: (context, index) {
                    final idea = _similarIdeas[index];
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _navigateToIdea(idea),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Image.network(
                                  idea.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  idea.title,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildCommentsTab() => Column(
        children: [
          // Поле для добавления комментария
          if (widget.userId != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Добавить комментарий...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _addComment,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _addComment(''),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),

          // Список комментариев
          Expanded(
            child: _isLoadingComments
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? _buildEmptyCommentsState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return IdeaCommentWidget(
                            comment: comment,
                            onLike: () => _toggleCommentLike(comment),
                            onReply: () => _replyToComment(comment),
                          );
                        },
                      ),
          ),
        ],
      );

  Widget _buildIdeaDetails() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Детали',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (widget.idea.budget != null)
                _buildDetailRow(
                  'Бюджет',
                  '${widget.idea.budget!.toStringAsFixed(0)} ₽',
                ),
              if (widget.idea.duration != null)
                _buildDetailRow(
                  'Длительность',
                  '${widget.idea.duration} часов',
                ),
              if (widget.idea.guestCount != null)
                _buildDetailRow(
                  'Количество гостей',
                  '${widget.idea.guestCount} человек',
                ),
              if (widget.idea.location != null)
                _buildDetailRow('Локация', widget.idea.location!),
              if (widget.idea.season != null)
                _buildDetailRow('Сезон', widget.idea.season!),
              if (widget.idea.style != null)
                _buildDetailRow('Стиль', widget.idea.style!),
              if (widget.idea.colorScheme != null &&
                  widget.idea.colorScheme!.isNotEmpty)
                _buildDetailRow(
                  'Цветовая схема',
                  widget.idea.colorScheme!.join(', '),
                ),
              if (widget.idea.inspiration != null)
                _buildDetailRow('Вдохновение', widget.idea.inspiration!),
              _buildDetailRow('Автор', widget.idea.createdBy),
              _buildDetailRow(
                'Дата создания',
                _formatDate(widget.idea.createdAt),
              ),
              _buildDetailRow('Просмотры', widget.idea.views.toString()),
              _buildDetailRow('Лайки', widget.idea.likes.toString()),
              _buildDetailRow(
                'Комментарии',
                widget.idea.commentsCount.toString(),
              ),
            ],
          ),
        ),
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyCommentsState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет комментариев',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Будьте первым, кто оставит комментарий',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );

  Future<void> _toggleLike() async {
    if (widget.userId == null) return;

    try {
      if (_isLiked) {
        await _ideasService.unlikeIdea(widget.idea.id, widget.userId!);
      } else {
        await _ideasService.likeIdea(widget.idea.id, widget.userId!);
      }

      setState(() {
        _isLiked = !_isLiked;
      });
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка изменения лайка: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.userId == null) return;

    try {
      if (_isFavorite) {
        await _ideasService.removeFromFavorites(widget.idea.id, widget.userId!);
      } else {
        await _ideasService.addToFavorites(widget.idea.id, widget.userId!);
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка изменения избранного: $e');
    }
  }

  void _shareIdea() {
    // TODO(developer): Реализовать шаринг
    _showErrorSnackBar('Функция шаринга будет добавлена');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'attach_to_booking':
        _attachToBooking();
        break;
      case 'report':
        _reportIdea();
        break;
    }
  }

  void _attachToBooking() {
    // TODO(developer): Реализовать прикрепление к заявке
    _showErrorSnackBar('Функция прикрепления к заявке будет добавлена');
  }

  void _reportIdea() {
    // TODO(developer): Реализовать жалобу
    _showErrorSnackBar('Функция жалоб будет добавлена');
  }

  void _addComment(String content) {
    if (widget.userId == null || content.trim().isEmpty) return;

    // TODO(developer): Реализовать добавление комментария
    _showErrorSnackBar('Функция комментариев будет добавлена');
  }

  void _toggleCommentLike(IdeaComment comment) {
    // TODO(developer): Реализовать лайк комментария
    _showErrorSnackBar('Функция лайков комментариев будет добавлена');
  }

  void _replyToComment(IdeaComment comment) {
    // TODO(developer): Реализовать ответ на комментарий
    _showErrorSnackBar('Функция ответов на комментарии будет добавлена');
  }

  void _navigateToIdea(EventIdea idea) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => IdeaDetailScreen(
          idea: idea,
          userId: widget.userId,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
