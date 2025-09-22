import 'package:flutter/material.dart';

import '../models/event_idea.dart';

/// Карточка идеи мероприятия
class IdeaCard extends StatelessWidget {
  const IdeaCard({
    super.key,
    required this.idea,
    required this.onTap,
    required this.onSave,
    required this.onLike,
    this.isSaved = false,
  });

  final EventIdea idea;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final VoidCallback onLike;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    Image.network(
                      idea.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
                    ),
                    // Бейдж категории
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(idea.category).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          idea.categoryDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Кнопки действий
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionButton(
                            icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
                            onPressed: onSave,
                            color: isSaved ? Colors.orange : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          _buildActionButton(
                            icon: Icons.favorite_outline,
                            onPressed: onLike,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    // Бейдж избранного
                    if (idea.isFeatured)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Рекомендуем',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Контент
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Text(
                      idea.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Описание
                    Expanded(
                      child: Text(
                        idea.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Метаданные
                    Row(
                      children: [
                        // Тип мероприятия
                        Icon(
                          _getTypeIcon(idea.type),
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            idea.typeDisplayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Стоимость
                        if (idea.estimatedCost != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${idea.estimatedCost!.toInt()} ₽',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Статистика
                    Row(
                      children: [
                        _buildStatIcon(Icons.favorite_outline, idea.likesCount),
                        const SizedBox(width: 12),
                        _buildStatIcon(Icons.bookmark_outline, idea.savesCount),
                        const SizedBox(width: 12),
                        _buildStatIcon(Icons.visibility_outlined, idea.viewsCount),
                      ],
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

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  Color _getCategoryColor(EventIdeaCategory category) {
    switch (category) {
      case EventIdeaCategory.decoration:
        return Colors.pink;
      case EventIdeaCategory.entertainment:
        return Colors.purple;
      case EventIdeaCategory.catering:
        return Colors.orange;
      case EventIdeaCategory.photography:
        return Colors.blue;
      case EventIdeaCategory.music:
        return Colors.green;
      case EventIdeaCategory.venue:
        return Colors.brown;
      case EventIdeaCategory.planning:
        return Colors.teal;
      case EventIdeaCategory.other:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(EventIdeaType type) {
    switch (type) {
      case EventIdeaType.wedding:
        return Icons.favorite;
      case EventIdeaType.birthday:
        return Icons.cake;
      case EventIdeaType.corporate:
        return Icons.business;
      case EventIdeaType.anniversary:
        return Icons.celebration;
      case EventIdeaType.graduation:
        return Icons.school;
      case EventIdeaType.holiday:
        return Icons.celebration;
      case EventIdeaType.private:
        return Icons.home;
      case EventIdeaType.other:
        return Icons.star;
    }
  }
}
