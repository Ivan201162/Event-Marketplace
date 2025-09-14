import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../providers/firestore_providers.dart';
import '../providers/auth_providers.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не авторизован')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заявки'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Отправленные', icon: Icon(Icons.send)),
            Tab(text: 'Подтвержденные', icon: Icon(Icons.check_circle)),
            Tab(text: 'Отклоненные', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(currentUser.id, 'pending'),
          _buildBookingsList(currentUser.id, 'confirmed'),
          _buildBookingsList(currentUser.id, 'rejected'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(String customerId, String status) {
    final bookingsAsync = ref.watch(bookingsByCustomerProvider(customerId));

    return bookingsAsync.when(
      data: (bookings) {
        final filteredBookings = bookings.where((booking) => booking is Booking && booking.status == status).cast<Booking>().toList();
        
        if (filteredBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(status),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bookingsByCustomerProvider(customerId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              return _buildBookingCard(booking);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(bookingsByCustomerProvider(customerId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с датой и временем
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.title ?? 'Без названия',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(booking.eventDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(booking.status)),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Описание события
            if (booking.description != null) ...[
              Text(
                'Описание:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
            
            // Стоимость
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Стоимость:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${booking.totalPrice.toStringAsFixed(0)} ₽',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            if (booking.prepayment > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Аванс:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${booking.prepayment.toStringAsFixed(0)} ₽',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            
            // Статус оплаты
            if (booking.prepayment > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    booking.prepaymentPaid ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: booking.prepaymentPaid ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.prepaymentPaid ? 'Аванс оплачен' : 'Аванс не оплачен',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: booking.prepaymentPaid ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Действия в зависимости от статуса
            if (booking.status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewBookingDetails(booking),
                      icon: const Icon(Icons.info, size: 16),
                      label: const Text('Подробности'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(booking),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Отменить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (booking.status == 'confirmed') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewBookingDetails(booking),
                      icon: const Icon(Icons.info, size: 16),
                      label: const Text('Подробности'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _contactSpecialist(booking),
                      icon: const Icon(Icons.message, size: 16),
                      label: const Text('Связаться'),
                    ),
                  ),
                ],
              ),
              
              // Кнопка оплаты аванса
              if (booking.prepayment > 0 && !booking.prepaymentPaid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _payPrepayment(booking),
                    icon: const Icon(Icons.payment, size: 16),
                    label: Text('Оплатить аванс ${booking.prepayment.toStringAsFixed(0)} ₽'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ] else if (booking.status == 'rejected') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _viewBookingDetails(booking),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Подробности'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _viewBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking.title ?? 'Без названия'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Дата и время:', _formatDateTime(booking.eventDate)),
              if (booking.description != null)
                _buildDetailRow('Описание:', booking.description!),
              _buildDetailRow('Стоимость:', '${booking.totalPrice.toStringAsFixed(0)} ₽'),
              if (booking.prepayment > 0)
                _buildDetailRow('Аванс:', '${booking.prepayment.toStringAsFixed(0)} ₽'),
              _buildDetailRow('Статус:', _getStatusText(booking.status)),
              if (booking.prepayment > 0)
                _buildDetailRow('Оплата аванса:', booking.prepaymentPaid ? 'Оплачен' : 'Не оплачен'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заявку'),
        content: const Text('Вы уверены, что хотите отменить эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.updateBookingStatus(booking.id, 'cancelled');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заявка отменена'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _contactSpecialist(Booking booking) {
    // TODO: Реализовать переход в чат со специалистом
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Переход в чат будет реализован позже')),
    );
  }

  void _payPrepayment(Booking booking) {
    // TODO: Реализовать оплату аванса
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Оплата аванса ${booking.prepayment.toStringAsFixed(0)} ₽ будет реализована позже'),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.send;
      case 'confirmed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Нет отправленных заявок';
      case 'confirmed':
        return 'Нет подтвержденных заявок';
      case 'rejected':
        return 'Нет отклоненных заявок';
      default:
        return 'Нет заявок';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Отправлена';
      case 'confirmed':
        return 'Подтверждена';
      case 'rejected':
        return 'Отклонена';
      default:
        return 'Неизвестно';
    }
  }
}