import 'package:flutter/material.dart';
import '../models/portfolio_item.dart';

/// Виджет портфолио специалиста
class PortfolioWidget extends StatelessWidget {
  const PortfolioWidget({
    super.key,
    required this.portfolioItems,
    this.onItemTap,
    this.onLike,
    this.showActions = true,
  });

  final List<PortfolioItem> portfolioItems;
  final void Function(PortfolioItem)? onItemTap;
  final void Function(PortfolioItem)? onLike;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    if (portfolioItems.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Портфолио', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              '${portfolioItems.length} работ',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Сетка портфолио
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: portfolioItems.length,
          itemBuilder: (context, index) {
            final item = portfolioItems[index];
            return _buildPortfolioItem(item);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
    child: const Column(
      children: [
        Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Портфолио пусто',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        SizedBox(height: 8),
        Text(
          'Специалист ещё не добавил свои работы',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildPortfolioItem(PortfolioItem item) => GestureDetector(
    onTap: () => onItemTap?.call(item),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Медиа контент
            Positioned.fill(
              child: item.mediaType == PortfolioMediaType.image
                  ? Image.network(
                      item.mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
                      ),
                    )
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
                      ),
                    ),
            ),

            // Градиент для читаемости текста
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
            ),

            // Информация о работе
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.category.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.category,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Действия
            if (showActions) ...[
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Кнопка лайка
                    GestureDetector(
                      onTap: () => onLike?.call(item),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_border, color: Colors.white, size: 14),
                            if (item.likes > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                item.likes.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Индикатор типа медиа
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.mediaType == PortfolioMediaType.image ? Icons.image : Icons.videocam,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.mediaType == PortfolioMediaType.image ? 'Фото' : 'Видео',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
