import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking.dart';

/// Карточка заявки
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.showActions = false,
    this.onApprove,
    this.onReject,
    this.onCancel,
    this.onEdit,
    this.onComplete,
  });

  final Booking booking;
  final bool showActions;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с статусом
              _buildHeader(context),

              const SizedBox(height: 12),

              // Информация о заявке
              _buildBookingInfo(),

              const SizedBox(height: 12),

              // Детали события
              _buildEventDetails(),

              if (showActions) ...[
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ],
          ),
        ),
      );

  /// Построить заголовок
  Widget _buildHeader(BuildContext context) => Row(
        children: [
          // Статус
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(booking.status),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(booking.status),
                  size: 16,
                  color: _getStatusColor(booking.status),
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusText(booking.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(booking.status),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Дата создания
          Text(
            _formatDate(booking.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );

  /// Построить информацию о заявке
  Widget _buildBookingInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название события
          if (booking.title != null && booking.title!.isNotEmpty) ...[
            Text(
              booking.title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Участники
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Заказчик: ${booking.customerName ?? 'Неизвестно'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          if (booking.specialistName != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.work,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Специалист: ${booking.specialistName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      );

  /// Построить детали события
  Widget _buildEventDetails() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Дата и время события
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(booking.eventDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Цена
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Стоимость: ${booking.totalPrice.toInt()}₽',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            if (booking.prepayment > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.payment,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Предоплата: ${booking.prepayment.toInt()}₽',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            // Сообщение
            if (booking.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.message,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );

  /// Построить действия
  Widget _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Действия в зависимости от статуса
    switch (booking.status) {
      case BookingStatus.pending:
        if (onApprove != null) {
          actions.add(
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Подтвердить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          );
        }
        if (onReject != null) {
          actions.add(
            const SizedBox(width: 8),
          );
          actions.add(
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Отклонить'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          );
        }
        if (onCancel != null) {
          actions.add(
            const SizedBox(width: 8),
          );
          actions.add(
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Отменить'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
          );
        }
        break;

      case BookingStatus.confirmed:
        if (onComplete != null) {
          actions.add(
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Завершить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          );
        }
        if (onCancel != null) {
          actions.add(
            const SizedBox(width: 8),
          );
          actions.add(
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Отменить'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
          );
        }
        break;

      case BookingStatus.completed:
        actions.add(
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Заявка завершена',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        actions.add(
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    booking.status == BookingStatus.cancelled ? Icons.cancel : Icons.close,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.status == BookingStatus.cancelled
                        ? 'Заявка отменена'
                        : 'Заявка отклонена',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;
    }

    // Кнопка редактирования (если доступна)
    if (onEdit != null && _canEdit()) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 8));
      }
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Редактировать'),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: actions);
  }

  /// Проверить, можно ли редактировать заявку
  bool _canEdit() =>
      booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed;

  /// Получить иконку статуса
  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.rejected:
        return Icons.close;
    }
  }

  /// Получить цвет статуса
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.rejected:
        return Colors.red;
    }
  }

  /// Получить текст статуса
  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает';
      case BookingStatus.confirmed:
        return 'Подтверждено';
      case BookingStatus.cancelled:
        return 'Отменено';
      case BookingStatus.completed:
        return 'Завершено';
      case BookingStatus.rejected:
        return 'Отклонено';
    }
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня в ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Вчера в ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }
}
