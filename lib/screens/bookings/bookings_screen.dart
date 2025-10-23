import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking.dart';
import '../../providers/auth_providers.dart';
import '../../providers/booking_providers.dart';
import '../../widgets/booking_card.dart';

/// Bookings management screen
class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BookingStatus _selectedStatus = BookingStatus.pending;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирования'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ожидают'),
            Tab(text: 'Подтверждены'),
            Tab(text: 'В процессе'),
            Tab(text: 'Завершены'),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(specialistBookingsStreamProvider);
            },
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
                child: Text('Войдите в аккаунт для просмотра бронирований'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(BookingStatus.pending, user.uid),
              _buildBookingsList(BookingStatus.confirmed, user.uid),
              _buildBookingsList(BookingStatus.inProgress, user.uid),
              _buildBookingsList(BookingStatus.completed, user.uid),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки бронирований',
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create booking
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Создание бронирования пока не реализовано')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookingsList(BookingStatus status, String userId) {
    final bookingsAsync = ref.watch(specialistBookingsStreamProvider(userId));

    return bookingsAsync.when(
      data: (allBookings) {
        final bookings =
            allBookings.where((booking) => booking.status == status).toList();

        if (bookings.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(specialistBookingsStreamProvider(userId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return BookingCard(
                booking: booking,
                onTap: () => _showBookingDetails(booking),
                onStatusChange: (newStatus) =>
                    _updateBookingStatus(booking, newStatus),
                onEdit: () => _editBooking(booking),
                onDelete: () => _deleteBooking(booking),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки бронирований',
              style: TextStyle(fontSize: 18, color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(specialistBookingsStreamProvider(userId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BookingStatus status) {
    String title;
    String subtitle;
    IconData icon;

    switch (status) {
      case BookingStatus.pending:
        title = 'Нет ожидающих бронирований';
        subtitle = 'Новые заявки будут отображаться здесь';
        icon = Icons.schedule;
        break;
      case BookingStatus.confirmed:
        title = 'Нет подтвержденных бронирований';
        subtitle = 'Подтвержденные заявки будут отображаться здесь';
        icon = Icons.check_circle_outline;
        break;
      case BookingStatus.inProgress:
        title = 'Нет активных бронирований';
        subtitle = 'Текущие работы будут отображаться здесь';
        icon = Icons.work_outline;
        break;
      case BookingStatus.completed:
        title = 'Нет завершенных бронирований';
        subtitle = 'Завершенные работы будут отображаться здесь';
        icon = Icons.done_all;
        break;
      default:
        title = 'Нет бронирований';
        subtitle = 'Бронирования будут отображаться здесь';
        icon = Icons.event_note;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Все статусы'),
              leading: Radio<BookingStatus?>(
                value: null,
                groupValue: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            ...BookingStatus.values.map(
              (status) => ListTile(
                title: Text(status.displayName),
                leading: Radio<BookingStatus>(
                  value: status,
                  groupValue: _selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Booking details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.service,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Клиент: ${booking.clientName}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              booking.status.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Details
                      _buildDetailRow('Дата', booking.formattedDate),
                      _buildDetailRow('Время', booking.formattedTime),
                      _buildDetailRow(
                          'Длительность', booking.formattedDuration),
                      _buildDetailRow('Стоимость', booking.formattedPrice),

                      if (booking.notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Примечания',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(booking.notes),
                      ],

                      if (booking.location != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Место проведения', booking.location!),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    if (booking.canBeConfirmed)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateBookingStatus(
                              booking, BookingStatus.confirmed),
                          child: const Text('Подтвердить'),
                        ),
                      ),
                    if (booking.canBeConfirmed) const SizedBox(width: 12),
                    if (booking.canBeCompleted)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateBookingStatus(
                              booking, BookingStatus.completed),
                          child: const Text('Завершить'),
                        ),
                      ),
                    if (booking.canBeCancelled)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateBookingStatus(
                              booking, BookingStatus.cancelled),
                          child: const Text('Отменить'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.red;
    }
  }

  void _updateBookingStatus(Booking booking, BookingStatus newStatus) {
    final bookingService = ref.read(bookingServiceProvider);

    bookingService.updateBookingStatus(booking.id, newStatus).then((success) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text('Статус изменен на: ${newStatus.displayName}')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Ошибка при изменении статуса')));
      }
    });
  }

  void _editBooking(Booking booking) {
    // TODO: Navigate to edit booking screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Редактирование бронирования пока не реализовано')),
    );
  }

  void _deleteBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить бронирование'),
        content: const Text('Вы уверены, что хотите удалить это бронирование?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final bookingService = ref.read(bookingServiceProvider);
              bookingService.deleteBooking(booking.id).then((success) {
                if (success) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                      const SnackBar(content: Text('Бронирование удалено')));
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(
                      content: Text('Ошибка при удалении бронирования')));
                }
              });
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
