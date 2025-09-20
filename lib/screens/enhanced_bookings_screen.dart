import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../models/booking.dart';
import '../models/booking_status.dart';
import '../widgets/enhanced_page_transition.dart';
import '../widgets/responsive_layout.dart';

/// Улучшенный экран бронирований с вкладками
class EnhancedBookingsScreen extends ConsumerStatefulWidget {
  const EnhancedBookingsScreen({super.key});

  @override
  ConsumerState<EnhancedBookingsScreen> createState() =>
      _EnhancedBookingsScreenState();
}

class _EnhancedBookingsScreenState extends ConsumerState<EnhancedBookingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
        largeDesktop: _buildLargeDesktopLayout(),
      );

  Widget _buildMobileLayout() => Scaffold(
        body: CustomScrollView(
          slivers: [
            // AppBar с вкладками
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Мои бронирования',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6200EE), Color(0xFF3700B3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                onTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tabs: const [
                  Tab(text: 'Все'),
                  Tab(text: 'На рассмотрении'),
                  Tab(text: 'Подтверждено'),
                  Tab(text: 'Завершено'),
                ],
              ),
            ),
            // Контент с вкладками
            SliverFillRemaining(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  _tabController.animateTo(index);
                },
                children: [
                  _buildAllBookingsTab(),
                  _buildPendingBookingsTab(),
                  _buildConfirmedBookingsTab(),
                  _buildCompletedBookingsTab(),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTabletLayout() => Scaffold(
        body: ResponsiveContainer(
          child: Column(
            children: [
              // AppBar
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6200EE), Color(0xFF3700B3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Мои бронирования',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Вкладки
              TabBar(
                controller: _tabController,
                isScrollable: true,
                onTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tabs: const [
                  Tab(text: 'Все'),
                  Tab(text: 'На рассмотрении'),
                  Tab(text: 'Подтверждено'),
                  Tab(text: 'Завершено'),
                ],
              ),
              // Контент
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _tabController.animateTo(index);
                  },
                  children: [
                    _buildAllBookingsTab(),
                    _buildPendingBookingsTab(),
                    _buildConfirmedBookingsTab(),
                    _buildCompletedBookingsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDesktopLayout() => Scaffold(
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Боковая панель с вкладками
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Мои бронирования',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Вертикальные вкладки
                    Expanded(
                      child: ListView(
                        children: [
                          _buildDesktopTabItem(0, 'Все', Icons.list),
                          _buildDesktopTabItem(
                            1,
                            'На рассмотрении',
                            Icons.schedule,
                          ),
                          _buildDesktopTabItem(
                            2,
                            'Подтверждено',
                            Icons.check_circle_outline,
                          ),
                          _buildDesktopTabItem(
                            3,
                            'Завершено',
                            Icons.check_circle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Основной контент
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _tabController.animateTo(index);
                  },
                  children: [
                    _buildAllBookingsTab(),
                    _buildPendingBookingsTab(),
                    _buildConfirmedBookingsTab(),
                    _buildCompletedBookingsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLargeDesktopLayout() => Scaffold(
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Боковая панель с вкладками
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Мои бронирования',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Вертикальные вкладки
                    Expanded(
                      child: ListView(
                        children: [
                          _buildDesktopTabItem(0, 'Все', Icons.list),
                          _buildDesktopTabItem(
                            1,
                            'На рассмотрении',
                            Icons.schedule,
                          ),
                          _buildDesktopTabItem(
                            2,
                            'Подтверждено',
                            Icons.check_circle_outline,
                          ),
                          _buildDesktopTabItem(
                            3,
                            'Завершено',
                            Icons.check_circle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Основной контент
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _tabController.animateTo(index);
                  },
                  children: [
                    _buildAllBookingsTab(),
                    _buildPendingBookingsTab(),
                    _buildConfirmedBookingsTab(),
                    _buildCompletedBookingsTab(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Правая панель с фильтрами и статистикой
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildFiltersPanel(),
                    const SizedBox(height: 24),
                    _buildStatsPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDesktopTabItem(int index, String title, IconData icon) {
    final isSelected = _tabController.index == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllBookingsTab() => _buildBookingsList([
        _createMockBooking('1', 'Фотограф на свадьбу', BookingStatus.pending),
        _createMockBooking(
          '2',
          'Видеограф на корпоратив',
          BookingStatus.confirmed,
        ),
        _createMockBooking(
          '3',
          'Диджей на день рождения',
          BookingStatus.completed,
        ),
        _createMockBooking('4', 'Ведущий на юбилей', BookingStatus.cancelled),
      ]);

  Widget _buildPendingBookingsTab() => _buildBookingsList([
        _createMockBooking('1', 'Фотограф на свадьбу', BookingStatus.pending),
      ]);

  Widget _buildConfirmedBookingsTab() => _buildBookingsList([
        _createMockBooking(
          '2',
          'Видеограф на корпоратив',
          BookingStatus.confirmed,
        ),
      ]);

  Widget _buildCompletedBookingsTab() => _buildBookingsList([
        _createMockBooking(
          '3',
          'Диджей на день рождения',
          BookingStatus.completed,
        ),
      ]);

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyState();
    }

    return ResponsiveList(
      children: bookings.map(_buildBookingCard).toList(),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final statusInfo = BookingStatusUtils.getStatusInfo(booking.status);
    final availableActions =
        BookingStatusUtils.getAvailableActions(booking.status);

    return AnimatedContent(
      delay: Duration(milliseconds: bookings.indexOf(booking) * 100),
      type: AnimationType.slideUp,
      child: ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с статусом
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        booking.specialistName,
                        isTitle: true,
                      ),
                      const SizedBox(height: 4),
                      ResponsiveText(
                        booking.eventType,
                        isSubtitle: true,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusInfo.color),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusInfo.icon,
                        size: 16,
                        color: statusInfo.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo.name,
                        style: TextStyle(
                          color: statusInfo.color,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Детали бронирования
            _buildBookingDetails(booking),
            const SizedBox(height: 16),
            // Действия
            if (availableActions.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableActions
                    .map((action) => _buildActionButton(action, booking))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails(Booking booking) => Column(
        children: [
          _buildDetailRow('Дата', _formatDate(booking.startTime)),
          _buildDetailRow('Время', _formatTime(booking.startTime)),
          _buildDetailRow('Длительность', '${booking.duration.inHours} ч'),
          _buildDetailRow('Стоимость', '${booking.totalPrice} ₽'),
          if (booking.location.isNotEmpty)
            _buildDetailRow('Место', booking.location),
        ],
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(
              label,
              isSubtitle: true,
            ),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildActionButton(BookingAction action, Booking booking) =>
      AnimatedButton(
        onPressed: () => _handleAction(action, booking),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: action.color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                size: 16,
                color: action.color,
              ),
              const SizedBox(width: 4),
              Text(
                action.name,
                style: TextStyle(
                  color: action.color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const ResponsiveText(
              'Нет бронирований',
              isTitle: true,
            ),
            const SizedBox(height: 8),
            const ResponsiveText(
              'Здесь будут отображаться ваши бронирования',
              isSubtitle: true,
            ),
          ],
        ),
      );

  Widget _buildFiltersPanel() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Фильтры',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            // Фильтры по дате
            _buildFilterChip('Сегодня', false),
            _buildFilterChip('На этой неделе', false),
            _buildFilterChip('В этом месяце', false),
            const SizedBox(height: 16),
            // Фильтры по типу события
            _buildFilterChip('Свадьба', false),
            _buildFilterChip('Корпоратив', false),
            _buildFilterChip('День рождения', false),
          ],
        ),
      );

  Widget _buildFilterChip(String label, bool isSelected) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            // TODO: Реализовать фильтрацию
          },
        ),
      );

  Widget _buildStatsPanel() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Статистика',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildStatItem('Всего бронирований', '12'),
            _buildStatItem('На рассмотрении', '3'),
            _buildStatItem('Подтверждено', '5'),
            _buildStatItem('Завершено', '4'),
            const SizedBox(height: 16),
            _buildStatItem('Общая сумма', '45,000 ₽'),
            _buildStatItem('Средний чек', '3,750 ₽'),
          ],
        ),
      );

  Widget _buildStatItem(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(label, isSubtitle: true),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  void _handleAction(BookingAction action, Booking booking) {
    switch (action) {
      case BookingAction.confirm:
        _showConfirmDialog(booking);
        break;
      case BookingAction.reject:
        _showRejectDialog(booking);
        break;
      case BookingAction.cancel:
        _showCancelDialog(booking);
        break;
      case BookingAction.complete:
        _showCompleteDialog(booking);
        break;
      case BookingAction.view:
        _viewBooking(booking);
        break;
      case BookingAction.edit:
        _editBooking(booking);
        break;
      case BookingAction.delete:
        _showDeleteDialog(booking);
        break;
    }
  }

  void _showConfirmDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Подтвердить бронирование',
        child: Text(
          'Вы уверены, что хотите подтвердить бронирование "${booking.specialistName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Бронирование подтверждено')),
              );
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Отклонить бронирование',
        child: Text(
          'Вы уверены, что хотите отклонить бронирование "${booking.specialistName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Бронирование отклонено')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Отменить бронирование',
        child: Text(
          'Вы уверены, что хотите отменить бронирование "${booking.specialistName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Бронирование отменено')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Завершить бронирование',
        child: Text(
          'Вы уверены, что хотите завершить бронирование "${booking.specialistName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Бронирование завершено')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Удалить бронирование',
        child: Text(
          'Вы уверены, что хотите удалить бронирование "${booking.specialistName}"? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Бронирование удалено')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _viewBooking(Booking booking) {
    // TODO: Реализовать просмотр деталей бронирования
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Просмотр бронирования: ${booking.specialistName}'),
      ),
    );
  }

  void _editBooking(Booking booking) {
    // TODO: Реализовать редактирование бронирования
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Редактирование бронирования: ${booking.specialistName}'),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Booking _createMockBooking(
    String id,
    String specialistName,
    BookingStatus status,
  ) =>
      Booking(
        id: id,
        customerId: 'customer_1',
        specialistId: 'specialist_$id',
        specialistName: specialistName,
        eventType: 'Свадьба',
        startTime: DateTime.now().add(Duration(days: int.parse(id))),
        eventTime: DateTime.now()
            .add(Duration(days: int.parse(id), hours: 4))
            .toIso8601String(),
        duration: const Duration(hours: 4),
        totalPrice: 15000,
        status: status,
        location: 'Москва, ул. Примерная, д. 1',
        notes: 'Дополнительные пожелания',
        createdAt: DateTime.now().subtract(Duration(days: int.parse(id))),
        updatedAt: DateTime.now().subtract(Duration(days: int.parse(id))),
      );
}
