import 'package:flutter/material.dart';
import '../models/booking.dart';

/// Виджет карточки заявки
class BookingCardWidget extends StatelessWidget {
  const BookingCardWidget({
    super.key,
    required this.booking,
    this.onTap,
    this.onCancel,
    this.onReview,
  });
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
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
                        booking.eventTitle.isNotEmpty
                            ? booking.eventTitle
                            : booking.title ?? 'Заявка',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Информация о специалисте
                if (booking.specialistName != null &&
                    booking.specialistName!.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        booking.specialistName!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 4),

                // Дата и время
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(booking.eventDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                if (booking.startTime != null &&
                    booking.startTime!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.startTime!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],

                // Местоположение
                if (booking.location != null &&
                    booking.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.location!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Цена
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${booking.effectivePrice.toInt()}₽',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (booking.hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${booking.discountAmount.toInt()}₽ скидка',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Действия
                Row(
                  children: [
                    if (booking.canBeCancelled)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Отменить'),
                        ),
                      ),
                    if (booking.canBeCancelled &&
                        booking.status == BookingStatus.completed)
                      const SizedBox(width: 8),
                    if (booking.status == BookingStatus.completed &&
                        onReview != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Оставить отзыв'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Завтра';
    } else if (difference.inDays == -1) {
      return 'Вчера';
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      return 'Через ${difference.inDays} дн.';
    } else if (difference.inDays < 0 && difference.inDays >= -7) {
      return '${-difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
