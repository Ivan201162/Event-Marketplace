import 'package:flutter/material.dart';

/// Виджет годовщины или праздника
class AnniversaryWidget extends StatelessWidget {
  const AnniversaryWidget({
    super.key,
    required this.title,
    required this.date,
    this.description,
    this.partnerName,
    this.yearsMarried,
    this.onEdit,
    this.onDelete,
  });
  final String title;
  final DateTime date;
  final String? description;
  final String? partnerName;
  final int? yearsMarried;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _isToday(date);
    final isUpcoming = date.isAfter(now) && date.difference(now).inDays <= 30;
    final daysUntil = date.difference(now).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isToday ? Colors.blue.shade200 : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и дата
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.blue.shade700 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(date),
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // Индикатор статуса
              if (isToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Сегодня!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (isUpcoming)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Через $daysUntil дн.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          // Описание
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description!, style: const TextStyle(fontSize: 14)),
          ],

          // Информация о партнере
          if (partnerName != null && partnerName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.favorite, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  'С $partnerName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // Количество лет
          if (yearsMarried != null && yearsMarried! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.cake, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$yearsMarried ${_getYearsText(yearsMarried!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.amber,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // Действия
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Редактировать'),
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 8),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Удалить'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getYearsText(int years) {
    if (years % 10 == 1 && years % 100 != 11) {
      return 'год';
    } else if ([2, 3, 4].contains(years % 10) &&
        ![12, 13, 14].contains(years % 100)) {
      return 'года';
    } else {
      return 'лет';
    }
  }
}
