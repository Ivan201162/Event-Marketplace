import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/booking_status.dart';
import '../providers/auth_provider.dart';
import '../services/booking_service.dart';
import '../services/firestore_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/loading_widget.dart';

class SpecialistRequestsScreen extends StatefulWidget {
  const SpecialistRequestsScreen({super.key, required this.specialistId});
  final String specialistId;

  @override
  State<SpecialistRequestsScreen> createState() => _SpecialistRequestsScreenState();
}

class _SpecialistRequestsScreenState extends State<SpecialistRequestsScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final FirestoreService _firestoreService = FirestoreService();

  late TabController _tabController;
  String _selectedSortOption = 'date_desc';

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
          title: const Text('Заявки на бронирование'),
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
                  value: 'date_desc',
                  child: Text('По дате (новые)'),
                ),
                const PopupMenuItem(
                  value: 'date_asc',
                  child: Text('По дате (старые)'),
                ),
                const PopupMenuItem(
                  value: 'status',
                  child: Text('По статусу'),
                ),
                const PopupMenuItem(
                  value: 'price_desc',
                  child: Text('По цене (убывание)'),
                ),
                const PopupMenuItem(
                  value: 'price_asc',
                  child: Text('По цене (возрастание)'),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBookingsList('all'),
            _buildBookingsList('pending'),
            _buildBookingsList('confirmed'),
            _buildBookingsList('completed'),
          ],
        ),
      );

  Widget _buildBookingsList(String statusFilter) => StreamBuilder<List<Booking>>(
        stream: _firestoreService.bookingsBySpecialistStream(widget.specialistId),
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
                  onApprove: booking.status == BookingStatus.pending
                      ? () => _updateBookingStatus(booking, BookingStatus.confirmed)
                      : null,
                  onReject: booking.status == BookingStatus.pending
                      ? () => _updateBookingStatus(booking, BookingStatus.rejected)
                      : null,
                  onComplete: booking.status == BookingStatus.confirmed
                      ? () => _updateBookingStatus(booking, BookingStatus.completed)
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
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: booking.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: booking.status.color),
                    ),
                    child: Text(
                      booking.status.name,
                      style: TextStyle(
                        color: booking.status.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.person,
                'Заказчик',
                booking.customerName ?? 'Не указан',
              ),
              _buildDetailRow(
                Icons.phone,
                'Телефон',
                booking.customerPhone ?? 'Не указан',
              ),
              _buildDetailRow(
                Icons.email,
                'Email',
                booking.customerEmail ?? 'Не указан',
              ),
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
                _buildDetailRow(
                  Icons.location_on,
                  'Место',
                  booking.location!,
                ),
              _buildDetailRow(
                Icons.attach_money,
                'Сумма',
                '${booking.totalPrice.toStringAsFixed(0)} ₽',
              ),
              _buildDetailRow(
                Icons.payment,
                'Аванс',
                '${booking.prepayment.toStringAsFixed(0)} ₽',
              ),
              if (booking.description != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Описание',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(booking.description!),
              ],
              const Spacer(),
              if (booking.status == BookingStatus.pending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateBookingStatus(
                          booking,
                          BookingStatus.rejected,
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Отклонить'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateBookingStatus(
                          booking,
                          BookingStatus.confirmed,
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Подтвердить'),
                      ),
                    ),
                  ],
                ),
              if (booking.status == BookingStatus.confirmed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateBookingStatus(booking, BookingStatus.completed),
                    icon: const Icon(Icons.done),
                    label: const Text('Отметить как завершенное'),
                  ),
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
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: Text(value),
            ),
          ],
        ),
      );

  Future<void> _updateBookingStatus(
    Booking booking,
    BookingStatus newStatus,
  ) async {
    try {
      await _firestoreService.updateBookingStatusWithCalendar(
        booking.id,
        newStatus.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Статус изменен на: ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления статуса: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
