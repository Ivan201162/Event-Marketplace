import 'package:flutter/material.dart';
import '../models/gallery_item.dart';

/// Карточка элемента галереи
class GalleryItemCard extends StatelessWidget {
  const GalleryItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLike,
    this.onDelete,
    this.onEdit,
  });

  final GalleryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Основное изображение/видео
              _buildMediaContent(),

              // Overlay с информацией
              _buildOverlay(),

              // Кнопки действий
              _buildActionButtons(),
            ],
          ),
        ),
      );

  Widget _buildMediaContent() => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: item.isImage
              ? Image.network(
                  item.thumbnailUrl,
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
                    child: const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.grey, size: 48)),
                  ),
                )
              : _buildVideoThumbnail(),
        ),
      );

  Widget _buildVideoThumbnail() => Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.thumbnailUrl,
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
              child: const Center(
                  child:
                      Icon(Icons.video_library, color: Colors.grey, size: 48)),
            ),
          ),

          // Иконка воспроизведения
          const Center(
              child: Icon(Icons.play_circle_filled,
                  color: Colors.white, size: 48)),

          // Длительность видео
          if (item.duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.formattedDuration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _buildOverlay() => Positioned(
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
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Text(
                item.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Статистика
              Row(
                children: [
                  if (item.viewCount > 0) ...[
                    const Icon(Icons.visibility,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      item.viewCount.toString(),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (item.likeCount > 0) ...[
                    const Icon(Icons.favorite, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      item.likeCount.toString(),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildActionButtons() => Positioned(
        top: 8,
        right: 8,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Избранное
            if (item.isFeatured)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.star, color: Colors.white, size: 16),
              ),

            const SizedBox(width: 4),

            // Кнопка лайка
            if (onLike != null)
              GestureDetector(
                onTap: onLike,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.favorite_border,
                      color: Colors.white, size: 16),
                ),
              ),

            // Кнопка редактирования
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],

            // Кнопка удаления
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      const Icon(Icons.delete, color: Colors.white, size: 16),
                ),
              ),
            ],
          ],
        ),
      );
}
