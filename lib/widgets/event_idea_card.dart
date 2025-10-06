import 'package:flutter/material.dart';
import '../models/event_idea.dart';

/// Карточка идеи мероприятия в стиле Pinterest
class EventIdeaCard extends StatelessWidget {
  const EventIdeaCard({
    super.key,
    required this.idea,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  final EventIdea idea;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображения
              if (idea.hasImages) _buildImages(),

              // Контент
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Text(
                      idea.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Описание
                    Text(
                      idea.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Метаданные
                    _buildMetadata(),
                    const SizedBox(height: 12),

                    // Теги
                    if (idea.tags.isNotEmpty) _buildTags(),

                    const SizedBox(height: 12),

                    // Действия
                    _buildActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildImages() {
    if (idea.images.length == 1) {
      // Одно изображение
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            idea.images.first,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Несколько изображений
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              // Первое изображение
              Image.network(
                idea.images.first,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                ),
              ),

              // Индикатор количества изображений
              if (idea.images.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${idea.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMetadata() => Row(
        children: [
          // Бюджет
          if (idea.budget != null) ...[
            _buildMetadataItem(
              icon: Icons.attach_money,
              text: idea.formattedBudget,
            ),
            const SizedBox(width: 16),
          ],

          // Длительность
          if (idea.duration != null) ...[
            _buildMetadataItem(
              icon: Icons.access_time,
              text: idea.formattedDuration,
            ),
            const SizedBox(width: 16),
          ],

          // Количество гостей
          if (idea.guests != null) ...[
            _buildMetadataItem(
              icon: Icons.people,
              text: idea.formattedGuests,
            ),
          ],
        ],
      );

  Widget _buildMetadataItem({
    required IconData icon,
    required String text,
  }) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );

  Widget _buildTags() => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: idea.tags
            .take(3)
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      );

  Widget _buildActions() => Row(
        children: [
          // Лайки
          _buildActionButton(
            icon: Icons.favorite_border,
            count: idea.likes,
            onTap: onLike,
          ),
          const SizedBox(width: 16),

          // Комментарии
          _buildActionButton(
            icon: Icons.comment_outlined,
            count: idea.comments,
            onTap: onComment,
          ),
          const SizedBox(width: 16),

          // Просмотры
          _buildActionButton(
            icon: Icons.visibility_outlined,
            count: idea.views,
          ),

          const Spacer(),

          // Время
          Text(
            idea.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      );

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.grey[600],
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      );
}
