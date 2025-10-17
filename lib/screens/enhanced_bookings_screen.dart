import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../providers/auth_providers.dart';
import '../services/firestore_service.dart';
import '../widgets/booking_card.dart';
import 'create_booking_screen.dart';

/// Улучшенный экран заявок с полным функционалом
class EnhancedBookingsScreen extends ConsumerStatefulWidget {
  const EnhancedBookingsScreen({super.key});

  @override
  ConsumerState<EnhancedBookingsScreen> createState() => _EnhancedBookingsScreenState();
}

class _EnhancedBookingsScreenState extends ConsumerState<EnhancedBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  BookingStatus? _selectedStatus;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Заявки'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Мои заявки'),
              Tab(text: 'Заявки мне'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Поиск и фильтры
            _buildSearchAndFilters(),

            // Контент
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyBookingsTab(),
                  _buildIncomingBookingsTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createBooking,
          child: const Icon(Icons.add),
        ),
      );

  /// Построить поиск и фильтры
  Widget _buildSearchAndFilters() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Column(
          children: [
            // Поисковая строка
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по заявкам...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Фильтры
            Row(
              children: [
                // Фильтр по статусу
                Expanded(
                  child: DropdownButtonFormField<BookingStatus?>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Статус',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    hint: const Text('Все статусы'),
                    items: [
                      const DropdownMenuItem<BookingStatus?>(
                        child: Text('Все статусы'),
                      ),
                      ...BookingStatus.values.map(
                        (status) => DropdownMenuItem<BookingStatus?>(
                          value: status,
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                size: 16,
                                color: _getStatusColor(status),
                              ),
                              const SizedBox(width: 8),
                              Text(_getStatusText(status)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Фильтр по дате
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                                  : 'Выберите дату',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          if (_selectedDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// Построить вкладку моих заявок
  Widget _buildMyBookingsTab() {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) {
      return const Center(
        child: Text('Необходимо войти в систему'),
      );
    }

    final bookingsStream = ref.watch(
      bookingsByCustomerStreamProvider(currentUser.uid),
    );

    return bookingsStream.when(
      data: (bookings) {
        final filteredBookings = _filterBookings(bookings);

        if (filteredBookings.isEmpty) {
          return _buildEmptyBookingsState('Мои заявки');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bookingsByCustomerStreamProvider(currentUser.uid));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BookingCard(
                  booking: booking,
                  showActions: true,
                  onCancel: () => _cancelBooking(booking),
                  onEdit: () => _editBooking(booking),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка заявок...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text('Ошибка загрузки заявок: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(
                  bookingsByCustomerStreamProvider(currentUser.uid),
                );
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить вкладку входящих заявок
  Widget _buildIncomingBookingsTab() {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) {
      return const Center(
        child: Text('Необходимо войти в систему'),
      );
    }

    final bookingsStream = ref.watch(
      bookingsBySpecialistStreamProvider(currentUser.uid),
    );

    return bookingsStream.when(
      data: (bookings) {
        final filteredBookings = _filterBookings(bookings);

        if (filteredBookings.isEmpty) {
          return _buildEmptyBookingsState('Заявки мне');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bookingsBySpecialistStreamProvider(currentUser.uid));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BookingCard(
                  booking: booking,
                  showActions: true,
                  onApprove: () => _approveBooking(booking),
                  onReject: () => _rejectBooking(booking),
                  onComplete: () => _completeBooking(booking),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка заявок...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text('Ошибка загрузки заявок: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(
                  bookingsBySpecialistStreamProvider(currentUser.uid),
                );
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить пустое состояние заявок
  Widget _buildEmptyBookingsState(String title) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет заявок',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              title == 'Мои заявки' ? 'Создайте первую заявку' : 'Заявки появятся здесь',
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (title == 'Мои заявки') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createBooking,
                icon: const Icon(Icons.add),
                label: const Text('Создать заявку'),
              ),
            ],
          ],
        ),
      );

  /// Фильтровать заявки
  List<Booking> _filterBookings(List<Booking> bookings) {
    var filtered = bookings;

    // Фильтр по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (booking) =>
                (booking.title?.toLowerCase().contains(searchLower) ?? false) ||
                (booking.customerName?.toLowerCase().contains(searchLower) ?? false) ||
                (booking.specialistName?.toLowerCase().contains(searchLower) ?? false) ||
                (booking.message.toLowerCase().contains(searchLower)),
          )
          .toList();
    }

    // Фильтр по статусу
    if (_selectedStatus != null) {
      filtered = filtered.where((booking) => booking.status == _selectedStatus).toList();
    }

    // Фильтр по дате
    if (_selectedDate != null) {
      filtered = filtered
          .where(
            (booking) =>
                booking.eventDate.year == _selectedDate!.year &&
                booking.eventDate.month == _selectedDate!.month &&
                booking.eventDate.day == _selectedDate!.day,
          )
          .toList();
    }

    return filtered;
  }

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

  /// Выбрать дату
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  /// Создать заявку
  void _createBooking() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CreateBookingScreen(),
      ),
    );
  }

  /// Редактировать заявку
  void _editBooking(Booking booking) {
    // TODO: Реализовать редактирование заявки
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование заявки будет реализовано')),
    );
  }

  /// Отменить заявку
  void _cancelBooking(Booking booking) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заявку'),
        content: const Text('Вы уверены, что хотите отменить эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(firestoreServiceProvider).updateBookingStatus(
                      booking.id,
                      BookingStatus.cancelled,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заявка отменена')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
  }

  /// Подтвердить заявку
  void _approveBooking(Booking booking) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердить заявку'),
        content: const Text('Вы подтверждаете эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(firestoreServiceProvider).updateBookingStatus(
                      booking.id,
                      BookingStatus.confirmed,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заявка подтверждена')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  /// Отклонить заявку
  void _rejectBooking(Booking booking) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить заявку'),
        content: const Text('Вы отклоняете эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(firestoreServiceProvider).updateBookingStatus(
                      booking.id,
                      BookingStatus.rejected,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заявка отклонена')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }

  /// Завершить заявку
  void _completeBooking(Booking booking) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить заявку'),
        content: const Text('Вы завершаете эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(firestoreServiceProvider).updateBookingStatus(
                      booking.id,
                      BookingStatus.completed,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заявка завершена')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
  }
}

/// Провайдер для потока заявок по заказчику
final bookingsByCustomerStreamProvider =
    StreamProvider.family<List<Booking>, String>((ref, customerId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.bookingsByCustomerStream(customerId);
});

/// Провайдер для потока заявок по специалисту
final bookingsBySpecialistStreamProvider =
    StreamProvider.family<List<Booking>, String>((ref, specialistId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.bookingsBySpecialistStream(specialistId);
});

/// Провайдер для сервиса Firestore
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
