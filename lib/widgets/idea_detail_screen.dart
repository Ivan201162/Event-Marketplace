import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../services/event_idea_service.dart';
import 'idea_comments_widget.dart';

/// Экран детального просмотра идеи
class IdeaDetailScreen extends ConsumerStatefulWidget {
  const IdeaDetailScreen({super.key, required this.idea});

  final EventIdea idea;

  @override
  ConsumerState<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends ConsumerState<IdeaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventIdeaService _ideaService = EventIdeaService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Увеличиваем счетчик просмотров
    _ideaService.incrementViews(widget.idea.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.idea.title),
          actions: [
            IconButton(onPressed: _shareIdea, icon: const Icon(Icons.share), tooltip: 'Поделиться'),
            IconButton(
              onPressed: _toggleLike,
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Лайк',
            ),
          ],
        ),
        body: Column(
          children: [
            // Основная информация об идее
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Изображения
                    if (widget.idea.hasImages) _buildImages(),

                    const SizedBox(height: 16),

                    // Заголовок
                    Text(
                      widget.idea.title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    // Автор и время
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: widget.idea.authorAvatar != null
                              ? NetworkImage(widget.idea.authorAvatar!)
                              : null,
                          child: widget.idea.authorAvatar == null
                              ? Text(
                                  (widget.idea.authorName ?? 'П').isNotEmpty
                                      ? (widget.idea.authorName ?? 'П')[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.idea.authorName ?? 'Пользователь',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                widget.idea.timeAgo,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Описание
                    Text(widget.idea.description, style: Theme.of(context).textTheme.bodyLarge),

                    const SizedBox(height: 16),

                    // Метаданные
                    _buildMetadata(),

                    const SizedBox(height: 16),

                    // Теги
                    if (widget.idea.tags.isNotEmpty) _buildTags(),

                    const SizedBox(height: 16),

                    // Статистика
                    _buildStats(),
                  ],
                ),
              ),
            ),

            // Вкладки
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Комментарии'),
                Tab(text: 'Подробнее'),
              ],
            ),

            // Контент вкладок
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  IdeaCommentsWidget(ideaId: widget.idea.id),
                  _buildDetailsTab(),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildImages() {
    if (widget.idea.images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            widget.idea.images.first,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 48)),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.idea.images.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.idea.images[index],
                width: 150,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMetadata() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Детали мероприятия',
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (widget.idea.budget != null) ...[
                _buildMetadataRow(
                  icon: Icons.attach_money,
                  label: 'Бюджет',
                  value: widget.idea.formattedBudget,
                ),
              ],
              if (widget.idea.duration != null) ...[
                _buildMetadataRow(
                  icon: Icons.access_time,
                  label: 'Длительность',
                  value: widget.idea.formattedDuration,
                ),
              ],
              if (widget.idea.guests != null) ...[
                _buildMetadataRow(
                  icon: Icons.people,
                  label: 'Гости',
                  value: widget.idea.formattedGuests,
                ),
              ],
              if (widget.idea.location != null) ...[
                _buildMetadataRow(
                  icon: Icons.location_on,
                  label: 'Место',
                  value: widget.idea.location!,
                ),
              ],
              if (widget.idea.category != null) ...[
                _buildMetadataRow(
                  icon: Icons.category,
                  label: 'Категория',
                  value: widget.idea.category!,
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildMetadataRow({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              '$label: ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );

  Widget _buildTags() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Теги',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.idea.tags
                .map(
                  (tag) => Chip(
                    label: Text('#$tag'),
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );

  Widget _buildStats() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(icon: Icons.favorite, count: widget.idea.likes, label: 'Лайки'),
              _buildStatItem(
                  icon: Icons.comment, count: widget.idea.comments, label: 'Комментарии'),
              _buildStatItem(icon: Icons.visibility, count: widget.idea.views, label: 'Просмотры'),
              _buildStatItem(icon: Icons.share, count: widget.idea.shares, label: 'Поделились'),
            ],
          ),
        ),
      );

  Widget _buildStatItem({required IconData icon, required int count, required String label}) =>
      Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      );

  Widget _buildDetailsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Дополнительная информация',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Здесь можно добавить дополнительную информацию
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Создано',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.idea.createdAt.day}.${widget.idea.createdAt.month}.${widget.idea.createdAt.year} в ${widget.idea.createdAt.hour}:${widget.idea.createdAt.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  void _shareIdea() {
    // Здесь можно добавить логику шаринга
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция шаринга будет добавлена позже'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _toggleLike() async {
    try {
      await _ideaService.likeIdea(widget.idea.id);
      setState(() {
        // Обновляем счетчик лайков
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Лайк добавлен!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }
}
