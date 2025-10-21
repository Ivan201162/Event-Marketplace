import 'package:flutter/material.dart';

/// Виджет для отображения портфолио в виде сетки
class PortfolioGridWidget extends StatelessWidget {
  const PortfolioGridWidget({
    super.key,
    required this.portfolioItems,
    this.portfolioImages = const [],
    this.onAddItem,
    this.onItemTap,
  });
  final List<Map<String, dynamic>> portfolioItems;
  final List<String> portfolioImages;
  final VoidCallback? onAddItem;
  final void Function(Map<String, dynamic>)? onItemTap;

  @override
  Widget build(BuildContext context) {
    final allItems = <Widget>[];

    // Добавляем элементы портфолио
    for (final item in portfolioItems) {
      allItems.add(_buildPortfolioItem(item));
    }

    // Добавляем изображения портфолио
    for (final imageUrl in portfolioImages) {
      allItems.add(_buildImageItem(imageUrl));
    }

    // Добавляем кнопку добавления, если есть колбэк
    if (onAddItem != null) {
      allItems.add(_buildAddButton());
    }

    if (allItems.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Портфолио пусто', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text('Добавьте работы в портфолио', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) => allItems[index],
    );
  }

  Widget _buildPortfolioItem(Map<String, dynamic> item) {
    final imageUrl = item['imageUrl'] as String?;
    final title = item['title'] as String? ?? '';
    final description = item['description'] as String? ?? '';
    final type = item['type'] as String? ?? 'image';

    return GestureDetector(
      onTap: () => onItemTap?.call(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Изображение или видео
              if (imageUrl != null && imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(type),
                )
              else
                _buildPlaceholder(type),

              // Индикатор типа контента
              if (type == 'video')
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  ),
                ),

              // Градиент для текста
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildImageItem(String imageUrl) => GestureDetector(
        onTap: () {
          // TODO(developer): Открыть изображение в полноэкранном режиме
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder('image'),
            ),
          ),
        ),
      );

  Widget _buildAddButton() => GestureDetector(
        onTap: onAddItem,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 32, color: Colors.grey),
                SizedBox(height: 8),
                Text('Добавить', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      );

  Widget _buildPlaceholder(String type) => Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            type == 'video' ? Icons.videocam : Icons.image,
            size: 32,
            color: Colors.grey.shade400,
          ),
        ),
      );
}
