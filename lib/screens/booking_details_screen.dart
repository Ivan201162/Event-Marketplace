import 'package:event_marketplace_app/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран деталей заявки
class BookingDetailsScreen extends ConsumerWidget {
  const BookingDetailsScreen({required this.booking, super.key});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: const Text('Детали заявки'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () => _navigateToChat(context),
              tooltip: 'Перейти в чат',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookingInfoCard(booking: booking),
              const SizedBox(height: 16),
              _CustomerInfoCard(booking: booking),
              const SizedBox(height: 16),
              _SpecialistInfoCard(booking: booking),
              const SizedBox(height: 16),
              _PaymentInfoCard(booking: booking),
              const SizedBox(height: 16),
              _StatusCard(booking: booking),
              const SizedBox(height: 32),
              _ActionButtons(context),
            ],
          ),
        ),
      );

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          chatId:
              '${booking['customerId'] ?? ''}_${booking['specialistId'] ?? ''}',
        ),
      ),
    );
  }

  Widget _ActionButtons(BuildContext context) => Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Реализовать принятие заявки
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Заявка принята')));
              },
              icon: const Icon(Icons.check),
              label: const Text('Принять'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Реализовать отклонение заявки
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                    const SnackBar(content: Text('Заявка отклонена')),);
              },
              icon: const Icon(Icons.close),
              label: const Text('Отклонить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
}

/// Карточка с информацией о заявке
class _BookingInfoCard extends StatelessWidget {
  const _BookingInfoCard({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Информация о заявке',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.calendar_today,
                label: 'Дата события',
                value: booking['eventDate'] ?? 'Не указана',
              ),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Время',
                value: booking['eventTime'] ?? 'Не указано',
              ),
              _InfoRow(
                icon: Icons.location_on,
                label: 'Место',
                value: booking['location'] ?? 'Не указано',
              ),
            ],
          ),
        ),
      );
}

/// Карточка с информацией о заказчике
class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text('Заказчик',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person,
                label: 'Имя',
                value: booking['customerName'] ?? 'Не указано',
              ),
              _InfoRow(
                icon: Icons.phone,
                label: 'Телефон',
                value: booking['customerPhone'] ?? 'Не указан',
              ),
              _InfoRow(
                icon: Icons.email,
                label: 'Email',
                value: booking['customerEmail'] ?? 'Не указан',
              ),
            ],
          ),
        ),
      );
}

/// Карточка с информацией о специалисте
class _SpecialistInfoCard extends StatelessWidget {
  const _SpecialistInfoCard({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.work, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  const Text('Специалист',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person,
                label: 'Имя',
                value: booking['specialistName'] ?? 'Не указано',
              ),
              const _InfoRow(
                icon: Icons.category,
                label: 'Категория',
                value: 'Фотограф', // TODO: Добавить категорию в модель Booking
              ),
            ],
          ),
        ),
      );
}

/// Карточка с информацией о платеже
class _PaymentInfoCard extends StatelessWidget {
  const _PaymentInfoCard({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payment, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Text('Платеж',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.monetization_on,
                label: 'Сумма',
                value: '${booking['totalPrice'] ?? 0} ₽',
              ),
              _InfoRow(
                icon: Icons.payment,
                label: 'Статус',
                value: booking['paymentStatus'] ?? 'Не указан',
              ),
            ],
          ),
        ),
      );
}

/// Карточка со статусом заявки
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.booking});
  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (booking['status']) {
      case 'В обработке':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'В обработке';
      case 'Подтверждено':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'Подтверждено';
      case 'Отклонено':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = 'Отклонено';
      case 'Завершено':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        text = 'Завершено';
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        text = booking['status'] ?? 'Неизвестно';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Статус заявки',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка с информацией
class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value,});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500,),),
                ],
              ),
            ),
          ],
        ),
      );
}
