import 'package:flutter/material.dart';
import '../models/enhanced_order.dart';

/// Виджет таймлайна заявки
class OrderTimelineWidget extends StatelessWidget {
  const OrderTimelineWidget({
    super.key,
    required this.timeline,
  });

  final List<OrderTimelineEvent> timeline;

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'История заявки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${timeline.length} событий',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Таймлайн
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: timeline.length,
          itemBuilder: (context, index) {
            final event = timeline[index];
            final isLast = index == timeline.length - 1;
            return _buildTimelineItem(event, isLast);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.timeline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'История заявки пуста',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'События появятся здесь по мере работы над заявкой',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildTimelineItem(OrderTimelineEvent event, bool isLast) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Линия таймлайна
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getEventColor(event.type),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    event.type.icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(top: 8),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Содержимое события
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(event.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (event.metadata.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildMetadata(event.metadata),
                  ],
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildMetadata(Map<String, dynamic> metadata) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: metadata.entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );

  Color _getEventColor(OrderTimelineEventType type) {
    switch (type) {
      case OrderTimelineEventType.created:
        return Colors.blue;
      case OrderTimelineEventType.accepted:
        return Colors.green;
      case OrderTimelineEventType.started:
        return Colors.orange;
      case OrderTimelineEventType.milestone:
        return Colors.purple;
      case OrderTimelineEventType.completed:
        return Colors.teal;
      case OrderTimelineEventType.cancelled:
        return Colors.red;
      case OrderTimelineEventType.comment:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
