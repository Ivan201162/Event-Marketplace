import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/booking_status.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/loading_widget.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  late TabController _tabController;
  String _selectedSortOption = 'date_desc';
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('История мероприятий'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все', icon: Icon(Icons.history)),
              Tab(text: 'Завершенные', icon: Icon(Icons.done_all)),
              Tab(text: 'Отмененные', icon: Icon(Icons.cancel)),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                if (value == 'date_range') {
                  _showDateRangePicker();
                } else {
                  setState(() {
                    _selectedFilter = value;
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all',
                  child: Text('Все мероприятия'),
                ),
                const PopupMenuItem(
                  value: 'this_month',
                  child: Text('Этот месяц'),
                ),
                const PopupMenuItem(
                  value: 'last_month',
                  child: Text('Прошлый месяц'),
                ),
                const PopupMenuItem(
                  value: 'this_year',
                  child: Text('Этот год'),
                ),
                const PopupMenuItem(
                  value: 'date_range',
                  child: Text('Выбрать период'),
                ),
              ],
            ),
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
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.user == null) {
              return const Center(
                child: Text('Необходимо войти в систему'),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(authProvider.user!.id, 'all'),
                _buildHistoryList(authProvider.user!.id, 'completed'),
                _buildHistoryList(authProvider.user!.id, 'cancelled'),
              ],
            );
          },
        ),
      );

  Widget _buildHistoryList(String userId, String statusFilter) =>
      StreamBuilder<List<Booking>>(
        stream: _firestoreService.bookingsByCustomerStream(userId),
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
                    'Ошибка загрузки истории: ${snapshot.error}',
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
                case 'completed':
                  return booking.status == BookingStatus.completed;
                case 'cancelled':
                  return booking.status == BookingStatus.cancelled ||
                      booking.status == BookingStatus.rejected;
                default:
                  return true;
              }
            }).toList();
          }

          // Фильтрация по дате
          bookings = _filterByDate(bookings);

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
                  onTap: () => _showEventDetails(booking),
                  showActions: false, // В истории не показываем действия
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
      case 'completed':
        message = 'Нет завершенных мероприятий';
        icon = Icons.done_all;
        break;
      case 'cancelled':
        message = 'Нет отмененных мероприятий';
        icon = Icons.cancel;
        break;
      default:
        message = 'История мероприятий пуста';
        icon = Icons.history;
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

  List<Booking> _filterByDate(List<Booking> bookings) {
    if (_selectedFilter == 'all') {
      return bookings;
    }

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_selectedFilter) {
      case 'this_month':
        startDate = DateTime(now.year, now.month);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'last_month':
        startDate = DateTime(now.year, now.month - 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'this_year':
        startDate = DateTime(now.year);
        endDate = DateTime(now.year, 12, 31);
        break;
      default:
        if (_startDate != null && _endDate != null) {
          startDate = _startDate!;
          endDate = _endDate!;
        } else {
          return bookings;
        }
    }

    return bookings.where((booking) {
      final eventDate = booking.eventDate;
      return eventDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          eventDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  List<Booking> _sortBookings(List<Booking> bookings, String sortOption) {
    switch (sortOption) {
      case 'date_desc':
        bookings.sort((a, b) => b.eventDate.compareTo(a.eventDate));
        break;
      case 'date_asc':
        bookings.sort((a, b) => a.eventDate.compareTo(b.eventDate));
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

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 'custom';
      });
    }
  }

  void _showEventDetails(Booking booking) {
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
                'Специалист',
                booking.specialistName ?? 'Не указан',
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
              _buildDetailRow(
                Icons.schedule,
                'Создано',
                '${booking.createdAt.day}.${booking.createdAt.month}.${booking.createdAt.year}',
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
              if (booking.status == BookingStatus.completed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Мероприятие успешно завершено',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (booking.status == BookingStatus.cancelled ||
                  booking.status == BookingStatus.rejected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Мероприятие отменено',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
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
}
