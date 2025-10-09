import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/auth_gate.dart';
import '../widgets/back_button_handler.dart';
import '../widgets/booking_card.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();

  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _selectedFilter = 'Все';

  late TabController _tabController;

  final List<String> _filters = [
    'Все',
    'Ожидают подтверждения',
    'Подтверждены',
    'Выполнены',
    'Отменены',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем текущего пользователя
      final currentUserAsync = ref.read(currentUserProvider);
      final currentUser = currentUserAsync.value;
      
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Загружаем заявки из Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final bookings = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return Booking.fromMap({...data, 'id': doc.id});
      }).toList();

      // Если заявок нет, создаем тестовые данные
      if (bookings.isEmpty) {
        await _createTestBookings(currentUser.uid);
        // Перезагружаем после создания тестовых данных
        final newQuerySnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('customerId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .get();

        final newBookings = newQuerySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return Booking.fromMap({...data, 'id': doc.id});
        }).toList();

        setState(() {
          _bookings = newBookings;
          _isLoading = false;
        });
      } else {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки заявок: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTestBookings(String uid) async {
    try {
      // Создаем тестовые заявки
      await FirebaseFirestore.instance.collection('bookings').add({
        'customerId': uid,
        'specialistId': 'spec_test_1',
        'eventDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'status': 'pending',
        'details': 'Тестовая заявка на фотосессию',
        'totalPrice': 15000.0,
        'createdAt': Timestamp.now(),
        'eventTitle': 'Фотосессия на природе',
        'customerName': 'Тестовый клиент',
        'customerPhone': '+7 (999) 123-45-67',
      });

      await FirebaseFirestore.instance.collection('bookings').add({
        'customerId': uid,
        'specialistId': 'spec_test_2',
        'eventDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
        'status': 'confirmed',
        'details': 'Тестовая заявка на видеосъемку',
        'totalPrice': 25000.0,
        'createdAt': Timestamp.now(),
        'eventTitle': 'Видеосъемка свадьбы',
        'customerName': 'Тестовый клиент',
        'customerPhone': '+7 (999) 123-45-67',
      });

      await FirebaseFirestore.instance.collection('bookings').add({
        'customerId': uid,
        'specialistId': 'spec_test_3',
        'eventDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
        'status': 'completed',
        'details': 'Завершенная тестовая заявка',
        'totalPrice': 10000.0,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
        'eventTitle': 'Фотосессия в студии',
        'customerName': 'Тестовый клиент',
        'customerPhone': '+7 (999) 123-45-67',
      });
    } on Exception catch (e) {
      print('Ошибка создания тестовых заявок: $e');
    }
  }

  List<Booking> get _filteredBookings {
    if (_selectedFilter == 'Все') {
      return _bookings;
    }

    BookingStatus? status;
    switch (_selectedFilter) {
      case 'Ожидают подтверждения':
        status = BookingStatus.pending;
        break;
      case 'Подтверждены':
        status = BookingStatus.confirmed;
        break;
      case 'Выполнены':
        status = BookingStatus.completed;
        break;
      case 'Отменены':
        status = BookingStatus.cancelled;
        break;
    }

    return _bookings.where((booking) => booking.status == status).toList();
  }

  Future<void> _cancelBooking(Booking booking) async {
    final result = await showDialog<bool>(
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
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      try {
        await _bookingService.cancelBooking(booking.id);
        await _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заявка отменена'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка отмены заявки: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showBookingDetails(Booking booking) async {
    await showModalBottomSheet<void>(
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
              // Заголовок
              Row(
                children: [
                  const Text(
                    'Детали заявки',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Содержимое
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Название',
                        booking.eventTitle ?? 'Не указано',
                      ),
                      _buildDetailRow('Дата', _formatDate(booking.eventDate)),
                      _buildDetailRow('Время', _formatTime(booking.eventDate)),
                      _buildDetailRow('Адрес', booking.address ?? 'Не указан'),
                      _buildDetailRow(
                        'Участники',
                        '${booking.participantsCount} чел.',
                      ),
                      _buildDetailRow(
                        'Стоимость',
                        '${booking.totalPrice.toInt() ?? 0}₽',
                      ),
                      _buildDetailRow('Статус', _getStatusText(booking.status)),
                      if (booking.description != null &&
                          booking.description!.isNotEmpty)
                        _buildDetailRow('Описание', booking.description!),
                      if (booking.comment != null &&
                          booking.comment!.isNotEmpty)
                        _buildDetailRow('Комментарий', booking.comment!),
                      if (booking.advancePaid == true)
                        _buildDetailRow(
                          'Аванс',
                          '${booking.advanceAmount?.toInt() ?? 0}₽',
                        ),
                    ],
                  ),
                ),
              ),

              // Кнопки действий
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // TODO(developer): Реализовать чат с специалистом
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Чат будет доступен после реализации',
                              ),
                            ),
                          );
                        },
                        child: const Text('Написать'),
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

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  String _formatDate(DateTime? date) {
    if (date == null) return 'Не указана';
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Не указано';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает подтверждения';
      case BookingStatus.confirmed:
        return 'Подтверждена';
      case BookingStatus.completed:
        return 'Выполнена';
      case BookingStatus.cancelled:
        return 'Отменена';
      case BookingStatus.rejected:
        return 'Отклонена';
    }
  }

  @override
  Widget build(BuildContext context) => BackButtonHandler(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Мои заявки'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Активные'),
                Tab(text: 'Завершенные'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Фильтры
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              // Список заявок
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(
                      _filteredBookings
                          .where(
                            (b) =>
                                b.status == BookingStatus.pending ||
                                b.status == BookingStatus.confirmed,
                          )
                          .toList(),
                    ),
                    _buildBookingsList(
                      _filteredBookings
                          .where(
                            (b) =>
                                b.status == BookingStatus.completed ||
                                b.status == BookingStatus.cancelled ||
                                b.status == BookingStatus.rejected,
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.push('/create_booking');
            },
            child: const Icon(Icons.add),
          ),
        ),
      );

  Widget _buildBookingsList(List<Booking> bookings) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Заявки не найдены',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте новую заявку, найдя специалиста',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/search'),
              child: const Text('Найти специалиста'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BookingCard(
              booking: booking,
              onTap: () => _showBookingDetails(booking),
              onCancel: booking.status == BookingStatus.pending ||
                      booking.status == BookingStatus.confirmed
                  ? () => _cancelBooking(booking)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
