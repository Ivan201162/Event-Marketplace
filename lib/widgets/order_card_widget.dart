import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/enhanced_order.dart';

/// Виджет карточки заявки
class OrderCardWidget extends StatelessWidget {
  const OrderCardWidget({
    super.key,
    required this.order,
    this.onTap,
    this.onEdit,
    this.onCancel,
    this.onComplete,
  });
  final EnhancedOrder order;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок и статус
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),

                const SizedBox(height: 8),

                // Описание
                Text(
                  order.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Детали
                Row(
                  children: [
                    _buildDetailChip(
                      icon: Icons.attach_money,
                      text: '${order.budget} ₽',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      icon: Icons.schedule,
                      text: order.deadline != null ? _formatDate(order.deadline!) : 'Не указан',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      icon: Icons.location_on,
                      text: order.location ?? 'Не указано',
                      color: Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Приоритет и категория
                Row(
                  children: [
                    _buildPriorityChip(),
                    const SizedBox(width: 8),
                    _buildCategoryChip(),
                    const Spacer(),
                    Text(
                      'Создана ${_formatRelativeDate(order.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // Действия
                if (_shouldShowActions()) ...[
                  const SizedBox(height: 12),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _buildStatusChip() {
    Color color;
    String text;

    switch (order.status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Ожидает';
        break;
      case OrderStatus.accepted:
        color = Colors.blue;
        text = 'Принята';
        break;
      case OrderStatus.inProgress:
        color = Colors.blue;
        text = 'В работе';
        break;
      case OrderStatus.completed:
        color = Colors.green;
        text = 'Завершена';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Отменена';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String text,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildPriorityChip() {
    Color color;
    String text;

    switch (order.priority) {
      case OrderPriority.low:
        color = Colors.green;
        text = 'Низкий';
        break;
      case OrderPriority.medium:
        color = Colors.orange;
        text = 'Средний';
        break;
      case OrderPriority.high:
        color = Colors.red;
        text = 'Высокий';
        break;
      case OrderPriority.urgent:
        color = Colors.purple;
        text = 'Срочный';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          order.category ?? 'Не указана',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _buildActionButtons() => Row(
        children: [
          if (order.status == OrderStatus.pending) ...[
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Редактировать'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Отменить'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
          if (order.status == OrderStatus.inProgress) ...[
            TextButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Завершить'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ],
      );

  bool _shouldShowActions() =>
      order.status == OrderStatus.pending || order.status == OrderStatus.inProgress;

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'только что';
    }
  }
}
