import 'package:flutter/material.dart';
import '../models/specialist_profile_extended.dart';

/// Виджет элемента FAQ
class FAQItemWidget extends StatelessWidget {
  const FAQItemWidget({
    super.key,
    required this.faqItem,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });
  final FAQItem faqItem;
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
                    if (faqItem.isPublished) ...[
                      const Icon(Icons.public, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                    ] else ...[
                      const Icon(Icons.lock, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        faqItem.question,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                                faqItem.isPublished ? Icons.lock : Icons.public,
                                color: faqItem.isPublished ? Colors.grey : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                faqItem.isPublished ? 'Скрыть' : 'Опубликовать',
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Редактировать'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Удалить',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Ответ
                Text(
                  faqItem.answer,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Категория и порядок
                Row(
                  children: [
                    Chip(
                      label: Text(
                        _getCategoryDisplayName(faqItem.category),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getCategoryColor(faqItem.category),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Порядок: ${faqItem.order}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Информация о дате
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(faqItem.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'general':
        return 'Общие';
      case 'pricing':
        return 'Цены';
      case 'booking':
        return 'Бронирование';
      case 'services':
        return 'Услуги';
      case 'equipment':
        return 'Оборудование';
      case 'cancellation':
        return 'Отмена';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'general':
        return Colors.blue[100]!;
      case 'pricing':
        return Colors.green[100]!;
      case 'booking':
        return Colors.orange[100]!;
      case 'services':
        return Colors.purple[100]!;
      case 'equipment':
        return Colors.red[100]!;
      case 'cancellation':
        return Colors.grey[100]!;
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
