import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/specialist_profile_extended.dart';

/// Виджет карточки видео
class VideoCardWidget extends StatelessWidget {
  const VideoCardWidget({
    super.key,
    required this.video,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });
  final PortfolioVideo video;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с индикатором публичности
                Row(
                  children: [
                    if (video.isPublic) ...[
                      const Icon(Icons.public, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                    ] else ...[
                      const Icon(Icons.lock, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        video.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'publish':
                            onTogglePublish();
                            break;
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'publish',
                          child: Row(
                            children: [
                              Icon(
                                video.isPublic ? Icons.lock : Icons.public,
                                color: video.isPublic ? Colors.grey : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(video.isPublic ? 'Скрыть' : 'Опубликовать'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [Icon(Icons.edit), SizedBox(width: 8), Text('Редактировать')],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Удалить', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Превью видео
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.video_library, size: 48, color: Colors.grey),
                          ),
                        ),

                        // Иконка воспроизведения
                        const Center(
                          child: Icon(Icons.play_circle_filled, size: 48, color: Colors.white),
                        ),

                        // Длительность
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video.duration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Описание
                Text(
                  video.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Платформа и теги
                Row(
                  children: [
                    Chip(
                      label: Text(
                        _getPlatformDisplayName(video.platform),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getPlatformColor(video.platform),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    if (video.tags.isNotEmpty) ...[
                      Expanded(
                        child: Text(
                          'Теги: ${video.tags.take(2).join(', ')}${video.tags.length > 2 ? '...' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Информация о просмотрах и дате
                Row(
                  children: [
                    Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${video.viewCount} просмотров',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(video.uploadedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  String _getPlatformDisplayName(String platform) {
    switch (platform) {
      case 'youtube':
        return 'YouTube';
      case 'vimeo':
        return 'Vimeo';
      case 'direct':
        return 'Прямая загрузка';
      default:
        return platform;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'youtube':
        return Colors.red[100]!;
      case 'vimeo':
        return Colors.blue[100]!;
      case 'direct':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
