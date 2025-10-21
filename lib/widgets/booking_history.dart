import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';

/// Виджет для отображения истории заказов заказчика
class BookingHistory extends ConsumerWidget {
  const BookingHistory({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingService = BookingService();

    return StreamBuilder<List<Booking>>(
      stream: bookingService.getCustomerBookings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки заказов: ${snapshot.error}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Перезагружаем данные
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Данные обновляются автоматически через Stream
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingItem(context, booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingItem(BuildContext context, Booking booking) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок заказа
        Row(
          children: [
            Expanded(
              child: Text(
                booking.serviceName ?? 'Услуга',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _buildStatusChip(booking.status.name),
          ],
        ),
        const SizedBox(height: 12),

        // Информация о специалисте
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (booking.specialistName.isNotEmpty ?? false)
                    ? booking.specialistName.substring(0, 1).toUpperCase()
                    : 'С',
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.specialistName ?? 'Специалист',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Категория', // TODO: Добавить поле category в модель Booking
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Детали заказа
        _buildDetailRow(Icons.calendar_today, 'Дата', _formatDate(booking.eventDate)),
        _buildDetailRow(Icons.access_time, 'Время', _formatTime(booking.eventDate)),
        _buildDetailRow(Icons.location_on, 'Место', booking.location ?? 'Место не указано'),
        _buildDetailRow(Icons.attach_money, 'Стоимость', '${booking.totalPrice.toInt()} ₽'),

        const SizedBox(height: 16),

        // Действия
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO(developer): Открыть детали заказа
                },
                child: const Text('Подробнее'),
              ),
            ),
            const SizedBox(width: 12),
            if (booking.status.name == 'confirmed')
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO(developer): Открыть чат с специалистом
                  },
                  child: const Text('Написать'),
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'Завершен';
        break;
      case 'upcoming':
        color = Colors.blue;
        text = 'Предстоящий';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Отменен';
        break;
      default:
        color = Colors.grey;
        text = 'Неизвестно';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'История заказов пуста',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Когда вы сделаете заказ,\nон появится здесь',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  void _leaveReview(BuildContext context, Map<String, dynamic> booking) {
    // TODO(developer): Открыть экран создания отзыва
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Оставить отзыв')));
  }

  void _cancelBooking(BuildContext context, Map<String, dynamic> booking) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заказ'),
        content: const Text('Вы уверены, что хотите отменить этот заказ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Нет')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(developer): Отменить заказ
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Заказ отменен')));
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockBookings() => [
    {
      'id': '1',
      'service': 'Ведение свадьбы',
      'specialistName': 'Анна Петрова',
      'specialistAvatar': null,
      'date': '15.12.2024',
      'time': '18:00',
      'location': 'Ресторан "Золотой"',
      'price': '25000',
      'status': 'completed',
    },
    {
      'id': '2',
      'service': 'Фотосессия',
      'specialistName': 'Михаил Иванов',
      'specialistAvatar': null,
      'date': '22.12.2024',
      'time': '14:00',
      'location': 'Парк Горького',
      'price': '15000',
      'status': 'upcoming',
    },
    {
      'id': '3',
      'service': 'Музыкальное сопровождение',
      'specialistName': 'Елена Сидорова',
      'specialistAvatar': null,
      'date': '10.12.2024',
      'time': '19:00',
      'location': 'Дом культуры',
      'price': '12000',
      'status': 'cancelled',
    },
  ];

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Widget _buildDetailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}
