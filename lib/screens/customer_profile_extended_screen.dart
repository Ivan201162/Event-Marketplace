import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/booking.dart';
import '../models/customer.dart';
import '../models/specialist.dart';
import '../services/booking_service.dart';
import '../services/customer_service.dart';
import '../services/specialist_service.dart';
import '../widgets/anniversary_widget.dart';
import '../widgets/back_button_handler.dart';
import '../widgets/booking_card_widget.dart';
import '../widgets/specialist_card_widget.dart';

/// Расширенный экран профиля заказчика с историей заявок, избранным и годовщинами
class CustomerProfileExtendedScreen extends ConsumerStatefulWidget {
  const CustomerProfileExtendedScreen({super.key});

  @override
  ConsumerState<CustomerProfileExtendedScreen> createState() =>
      _CustomerProfileExtendedScreenState();
}

class _CustomerProfileExtendedScreenState
    extends ConsumerState<CustomerProfileExtendedScreen>
    with TickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  final BookingService _bookingService = BookingService();
  final SpecialistService _specialistService = SpecialistService();

  Customer? _customer;
  List<Booking> _bookings = [];
  List<Specialist> _favoriteSpecialists = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    try {
      // TODO(developer): Получить реальный customerId из AuthService
      const customerId = 'current_customer_id';

      final results = await Future.wait([
        _customerService.getCustomerById(customerId),
        _bookingService.getUserBookings(customerId),
        _customerService.getFavoriteSpecialists(customerId),
      ]);

      final customer = results[0] as Customer?;
      final bookings = results[1] as List<Booking>;
      final favoriteIds = results[2] as List<String>;

      // Загружаем данные избранных специалистов
      final favoriteSpecialists = <Specialist>[];
      for (final specialistId in favoriteIds) {
        try {
          final specialist =
              await _specialistService.getSpecialistById(specialistId);
          if (specialist != null) {
            favoriteSpecialists.add(specialist);
          }
        } on Exception {
          // Игнорируем ошибки загрузки отдельных специалистов
        }
      }

      setState(() {
        _customer = customer;
        _bookings = bookings;
        _favoriteSpecialists = favoriteSpecialists;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки профиля: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavoriteSpecialist(String specialistId) async {
    try {
      // TODO(developer): Реализовать добавление/удаление из избранного
      setState(() {
        if (_customer!.favoriteSpecialists.contains(specialistId)) {
          // Удаляем из избранного
          _customer = _customer!.copyWith(
            favoriteSpecialists: _customer!.favoriteSpecialists
                .where((id) => id != specialistId)
                .toList(),
          );
          _favoriteSpecialists.removeWhere((s) => s.id == specialistId);
        } else {
          // Добавляем в избранное
          _customer = _customer!.copyWith(
            favoriteSpecialists: [
              ..._customer!.favoriteSpecialists,
              specialistId,
            ],
          );
          // Загружаем данные специалиста
          final specialist =
              await _specialistService.getSpecialistById(specialistId);
          if (specialist != null) {
            _favoriteSpecialists.add(specialist);
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _customer!.favoriteSpecialists.contains(specialistId)
                ? 'Добавлено в избранное'
                : 'Удалено из избранного',
          ),
        ),
      );
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addAnniversary() async {
    // TODO(developer): Реализовать добавление годовщины
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Добавление годовщины будет реализовано')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Профиль заказчика'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Заказчик не найден'),
        ),
      );
    }

    return BackButtonHandler(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мой профиль'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO(developer): Реализовать редактирование профиля
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Редактирование профиля будет реализовано'),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildProfileHeader(),
            _buildTabBar(),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
        ),
        child: Column(
          children: [
            // Аватар
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: _customer!.avatarUrl != null
                  ? NetworkImage(_customer!.avatarUrl!)
                  : null,
              child: _customer!.avatarUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),

            // Имя и статус
            Text(
              _customer!.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _customer!.maritalStatus.displayName,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),

            // Годовщина
            if (_customer!.weddingDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Годовщина: ${_customer!.yearsMarried} лет',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Статистика
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Заявки', '${_bookings.length}'),
                _buildStatItem('Избранное', '${_favoriteSpecialists.length}'),
                _buildStatItem(
                  'Годовщины',
                  '${_customer!.anniversaries.length}',
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatItem(String label, String value) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      );

  Widget _buildTabBar() => Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'История заявок'),
            Tab(text: 'Избранное'),
            Tab(text: 'Годовщины'),
          ],
        ),
      );

  Widget _buildTabContent() => TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsTab(),
          _buildFavoritesTab(),
          _buildAnniversariesTab(),
        ],
      );

  Widget _buildBookingsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История заявок',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_bookings.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.event_note, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Заявок пока нет',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Создайте первую заявку для бронирования специалиста',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._bookings.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BookingCardWidget(
                    booking: booking,
                    onTap: () {
                      // TODO(developer): Переход к деталям заявки
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Переход к заявке: ${booking.id}'),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildFavoritesTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Избранные специалисты',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_favoriteSpecialists.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Избранных специалистов нет',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Добавьте специалистов в избранное для быстрого доступа',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._favoriteSpecialists.map(
                (specialist) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SpecialistCardWidget(
                    specialist: specialist,
                    isFavorite: true,
                    onFavoriteToggle: () =>
                        _toggleFavoriteSpecialist(specialist.id),
                    onTap: () {
                      context.go('/specialist/${specialist.id}');
                    },
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildAnniversariesTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Годовщины и праздники',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addAnniversary,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Добавить годовщину',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Годовщина свадьбы
            if (_customer!.weddingDate != null)
              AnniversaryWidget(
                title: 'Годовщина свадьбы',
                date: _customer!.weddingDate!,
                partnerName: _customer!.partnerName,
                yearsMarried: _customer!.yearsMarried ?? 0,
              ),

            // Дополнительные годовщины
            if (_customer!.anniversaries.isNotEmpty)
              ..._customer!.anniversaries.map(
                (anniversary) => AnniversaryWidget(
                  title: anniversary['title'] ?? 'Годовщина',
                  date: anniversary['date'] is DateTime
                      ? anniversary['date'] as DateTime
                      : DateTime.parse(anniversary['date'].toString()),
                  description: anniversary['description'],
                ),
              ),

            if (_customer!.weddingDate == null &&
                _customer!.anniversaries.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.cake, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Годовщин пока нет',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Добавьте важные даты для напоминаний',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}
