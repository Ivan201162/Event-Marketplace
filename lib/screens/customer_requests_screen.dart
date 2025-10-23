import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/booking_status.dart';
import '../providers/auth_provider.dart';
import '../services/booking_service.dart';
import '../services/firestore_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/loading_widget.dart';

class CustomerRequestsScreen extends StatefulWidget {
  const CustomerRequestsScreen({super.key});

  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final FirestoreService _firestoreService = FirestoreService();

  late TabController _tabController;
  String _selectedSortOption = 'date_desc';
  final String _selectedStatusFilter = 'all';

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Мои заявки'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все', icon: Icon(Icons.list)),
              Tab(text: 'На рассмотрении', icon: Icon(Icons.pending)),
              Tab(text: 'Подтверждено', icon: Icon(Icons.check_circle)),
              Tab(text: 'Завершено', icon: Icon(Icons.done_all)),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (value) {
                setState(() {
                  _selectedSortOption = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'date_desc', child: Text('По дате (новые)')),
                const PopupMenuItem(
                    value: 'date_asc', child: Text('По дате (старые)')),
                const PopupMenuItem(value: 'status', child: Text('По статусу')),
                const PopupMenuItem(
                    value: 'price_desc', child: Text('По цене (убывание)')),
                const PopupMenuItem(
                    value: 'price_asc', child: Text('По цене (возрастание)')),
              ],
            ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.user == null) {
              return const Center(child: Text('Необходимо войти в систему'));
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(authProvider.user!.id, 'all'),
                _buildBookingsList(authProvider.user!.id, 'pending'),
                _buildBookingsList(authProvider.user!.id, 'confirmed'),
                _buildBookingsList(authProvider.user!.id, 'completed'),
              ],
            );
          },
        ),
      );

  Widget _buildBookingsList(String customerId, String statusFilter) =>
      StreamBuilder<List<Booking>>(
        stream: _firestoreService.bookingsByCustomerStream(customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки заявок: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          var bookings = snapshot.data ?? [];

          // Фильтрация по статусу
          if (statusFilter != 'all') {
            bookings = bookings.where((booking) {
              switch (statusFilter) {
                case 'pending':
                  return booking.status == BookingStatus.pending;
                case 'confirmed':
                  return booking.status == BookingStatus.confirmed;
                case 'completed':
                  return booking.status == BookingStatus.completed;
                default:
                  return true;
              }
            }).toList();
          }

          // Сортировка
          bookings = _sortBookings(bookings, _selectedSortOption);

          if (bookings.isEmpty) {
            return _buildEmptyState(statusFilter);
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return BookingCard(
                  booking: booking,
                  onTap: () => _showBookingDetails(booking),
                  onCancel: booking.status == BookingStatus.pending ||
                          booking.status == BookingStatus.confirmed
                      ? () => _cancelBooking(booking)
                      : null,
                  onReschedule: booking.status == BookingStatus.confirmed
                      ? () => _rescheduleBooking(booking)
                      : null,
                );
              },
            ),
          );
        },
      );

  Widget _buildEmptyState(String statusFilter) {
    String message;
    IconData icon;

    switch (statusFilter) {
      case 'pending':
        message = 'Нет заявок на рассмотрении';
        icon = Icons.pending;
        break;
      case 'confirmed':
        message = 'Нет подтвержденных заявок';
        icon = Icons.check_circle;
        break;
      case 'completed':
        message = 'Нет завершенных заявок';
        icon = Icons.done_all;
        break;
      default:
        message = 'У вас пока нет заявок';
        icon = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/specialists');
            },
            icon: const Icon(Icons.search),
            label: const Text('Найти специалиста'),
          ),
        ],
      ),
    );
  }

  List<Booking> _sortBookings(List<Booking> bookings, String sortOption) {
    switch (sortOption) {
      case 'date_desc':
        bookings.sort((a, b) => b.eventDate.compareTo(a.eventDate));
        break;
      case 'date_asc':
        bookings.sort((a, b) => a.eventDate.compareTo(b.eventDate));
        break;
      case 'status':
        bookings.sort((a, b) => a.status.name.compareTo(b.status.name));
        break;
      case 'price_desc':
        bookings.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
      case 'price_asc':
        bookings.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
    }
    return bookings;
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                booking.title ?? booking.eventTitle,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: booking.status.color),
                    ),
                    child: Text(
                      booking.status.name,
                      style: TextStyle(
                          color: booking.status.color,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person, 'Специалист',
                  booking.specialistName ?? 'Не указан'),
              _buildDetailRow(
                Icons.calendar_today,
                'Дата',
                '${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year}',
              ),
              _buildDetailRow(
                Icons.access_time,
                'Время',
                '${booking.eventDate.hour.toString().padLeft(2, '0')}:${booking.eventDate.minute.toString().padLeft(2, '0')}',
              ),
              if (booking.location != null)
                _buildDetailRow(Icons.location_on, 'Место', booking.location!),
              _buildDetailRow(
                Icons.attach_money,
                'Сумма',
                '${booking.totalPrice.toStringAsFixed(0)} ₽',
              ),
              _buildDetailRow(Icons.payment, 'Аванс',
                  '${booking.prepayment.toStringAsFixed(0)} ₽'),
              if (booking.description != null) ...[
                const SizedBox(height: 16),
                const Text('Описание',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(booking.description!),
              ],
              const Spacer(),
              if (booking.status == BookingStatus.pending ||
                  booking.status == BookingStatus.confirmed)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelBooking(booking),
                        child: const Text('Отменить'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (booking.status == BookingStatus.confirmed)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _rescheduleBooking(booking),
                          child: const Text('Перенести'),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text('$label: ',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заявку'),
        content: const Text(
          'Вы уверены, что хотите отменить эту заявку? '
          'Аванс будет возвращен в течение 3-5 рабочих дней.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Нет')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _bookingService.cancelBooking(booking.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Заявка отменена'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Ошибка отмены заявки: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _rescheduleBooking(Booking booking) async {
    // TODO(developer): Implement reschedule functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Функция переноса будет добавлена в следующем обновлении')),
    );
  }
}
