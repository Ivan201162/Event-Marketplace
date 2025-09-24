import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/event_idea.dart';

/// Карточка идеи мероприятия в стиле Pinterest
class EventIdeaCard extends StatelessWidget {
  const EventIdeaCard({
    super.key,
    required this.idea,
    required this.onTap,
    required this.onLike,
    required this.onSave,
    required this.onShare,
  });

  final EventIdea idea;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context),
            _buildContentSection(context, theme),
            _buildActionsSection(context, theme),
          ],
        ),
      ),
    );
  }

  /// Секция с изображением
  Widget _buildImageSection(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: _getAspectRatio(),
        child: Stack(
          children: [
            if (idea.mainImage != null)
              CachedNetworkImage(
                imageUrl: idea.mainImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            
            // Индикатор множественных изображений
            if (idea.images.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library,
                        size: 16,
                        color: Colors.white,
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
            
            // Рекомендуемая метка
            if (idea.isFeatured)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Рекомендуем',
                        style: TextStyle(
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

  /// Секция с контентом
  Widget _buildContentSection(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            idea.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          
          // Описание
          Text(
            idea.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Теги
          if (idea.tags.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: idea.tags.take(3).map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          const SizedBox(height: 8),
          
          // Метаинформация
          Row(
            children: [
              // Тип мероприятия
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  idea.type.displayName,
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              
              // Время создания
              Text(
                idea.timeAgo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Секция с действиями
  Widget _buildActionsSection(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          // Лайки
          _buildActionButton(
            icon: idea.isLikedBy('current_user_id') 
                ? Icons.favorite 
                : Icons.favorite_border,
            count: idea.likesCount,
            color: idea.isLikedBy('current_user_id') 
                ? Colors.red 
                : (theme.iconTheme.color ?? Colors.grey),
            onTap: onLike,
          ),
          const SizedBox(width: 16),
          
          // Сохранения
          _buildActionButton(
            icon: idea.isSavedBy('current_user_id') 
                ? Icons.bookmark 
                : Icons.bookmark_border,
            count: idea.savesCount,
            color: idea.isSavedBy('current_user_id') 
                ? theme.primaryColor 
                : (theme.iconTheme.color ?? Colors.grey),
            onTap: onSave,
          ),
          const Spacer(),
          
          // Поделиться
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onShare,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка действия с счетчиком
  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Получить соотношение сторон изображения
  double _getAspectRatio() {
    // Случайное соотношение для создания masonry эффекта
    final ratios = [0.8, 1.0, 1.2, 1.4];
    return ratios[idea.id.hashCode % ratios.length];
  }

  /// Форматировать счетчик
  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
