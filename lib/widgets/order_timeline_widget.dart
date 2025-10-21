import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/enhanced_order.dart';

/// Виджет таймлайна заявки
class OrderTimelineWidget extends StatelessWidget {
  const OrderTimelineWidget({super.key, required this.timeline});
  final List<OrderTimelineEvent> timeline;

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const Center(child: Text('История заявки пуста'));
    }

    return ListView.builder(
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final event = timeline[index];
        final isLast = index == timeline.length - 1;

        return _buildTimelineItem(event, isLast);
      },
    );
  }

  Widget _buildTimelineItem(OrderTimelineEvent event, bool isLast) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Индикатор
      Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: _getTypeColor(event.type), shape: BoxShape.circle),
          ),
          if (!isLast) Container(width: 2, height: 40, color: Colors.grey[300]),
        ],
      ),

      const SizedBox(width: 16),

      // Содержимое
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(event.description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(event.createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );

  Color _getTypeColor(OrderTimelineEventType type) {
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
        return Colors.green;
      case OrderTimelineEventType.cancelled:
        return Colors.red;
      case OrderTimelineEventType.comment:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy HH:mm').format(date);
}
