import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/booking.dart';
import '../models/review.dart';
import '../models/specialist.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../services/specialist_service.dart';
import '../widgets/availability_calendar_widget.dart';
import '../widgets/back_button_handler.dart';
import '../widgets/portfolio_grid_widget.dart';
import '../widgets/price_list_widget.dart';
import '../widgets/rating_summary_widget.dart';
import '../widgets/review_card.dart';

/// Расширенный экран профиля специалиста с портфолио, отзывами, прайс-листом и календарем
class SpecialistProfileExtendedScreen extends ConsumerStatefulWidget {
  const SpecialistProfileExtendedScreen({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  ConsumerState<SpecialistProfileExtendedScreen> createState() =>
      _SpecialistProfileExtendedScreenState();
}

class _SpecialistProfileExtendedScreenState
    extends ConsumerState<SpecialistProfileExtendedScreen>
    with TickerProviderStateMixin {
  final SpecialistService _specialistService = SpecialistService();
  final ReviewService _reviewService = ReviewService();
  final BookingService _bookingService = BookingService();

  Specialist? _specialist;
  List<Review> _reviews = [];
  List<Booking> _recentBookings = [];
  bool _isLoading = true;
  bool _isFavorite = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSpecialistData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialistData() async {
    try {
      setState(() => _isLoading = true);

      // Загружаем данные параллельно
      final results = await Future.wait([
        _specialistService.getSpecialistById(widget.specialistId),
        _reviewService.getSpecialistReviews(widget.specialistId, limit: 10),
        _bookingService.getSpecialistBookings(widget.specialistId, limit: 5),
      ]);

      setState(() {
        _specialist = results[0] as Specialist?;
        _reviews = results[1] as List<Review>;
        _recentBookings = results[2] as List<Booking>;
        _isLoading = false;
      });
    } catch (e) {
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

  Future<void> _toggleFavorite() async {
    try {
      // TODO(developer): Реализовать добавление/удаление из избранного
      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Добавлено в избранное' : 'Удалено из избранного',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addPortfolioItem() async {
    // TODO(developer): Реализовать добавление работы в портфолио
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Добавление работы в портфолио будет реализовано'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_specialist == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Профиль специалиста'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Специалист не найден'),
        ),
      );
    }

    return BackButtonHandler(
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(),
            _buildProfileHeader(),
            _buildTabBar(),
          ],
          body: _buildTabContent(),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildSliverAppBar() => SliverAppBar(
        expandedHeight: 300,
        pinned: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO(developer): Реализовать шаринг профиля
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Функция шаринга в разработке')),
              );
            },
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: _specialist!.imageUrlValue != null
              ? Image.network(
                  _specialist!.imageUrlValue!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultHeader(),
                )
              : _buildDefaultHeader(),
        ),
      );

  Widget _buildDefaultHeader() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text(
                  _specialist!.name.isNotEmpty
                      ? _specialist!.name[0].toUpperCase()
                      : 'С',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _specialist!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildProfileHeader() => SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _specialist!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _specialist!.category.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _specialist!.avgRating > 0
                                  ? _specialist!.avgRating.toStringAsFixed(1)
                                  : _specialist!.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_reviews.length} отзывов)',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_specialist!.price.toInt()}₽',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'за час',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Дополнительная информация
              if (_specialist!.location != null &&
                  _specialist!.location!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _specialist!.location!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              if (_specialist!.yearsOfExperience > 0) ...[
                Row(
                  children: [
                    Icon(Icons.work, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${_specialist!.yearsOfExperience} лет опыта',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Описание
              if (_specialist!.description != null &&
                  _specialist!.description!.isNotEmpty) ...[
                Text(
                  _specialist!.description!,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      );

  Widget _buildTabBar() => SliverToBoxAdapter(
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Портфолио'),
              Tab(text: 'Отзывы'),
              Tab(text: 'Прайс-лист'),
              Tab(text: 'Календарь'),
            ],
          ),
        ),
      );

  Widget _buildTabContent() => TabBarView(
        controller: _tabController,
        children: [
          _buildPortfolioTab(),
          _buildReviewsTab(),
          _buildPriceListTab(),
          _buildCalendarTab(),
        ],
      );

  Widget _buildPortfolioTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Портфолио',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_specialist!.userId ==
                    'current_user_id') // TODO(developer): Проверить, что это профиль текущего пользователя
                  IconButton(
                    onPressed: _addPortfolioItem,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Добавить работу',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_specialist!.portfolioItems.isEmpty &&
                _specialist!.portfolioImages.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_library, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Портфолио пусто',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Специалист еще не добавил работы в портфолио',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              PortfolioGridWidget(
                portfolioItems: _specialist!.portfolioItems,
                portfolioImages: _specialist!.portfolioImages,
              ),
          ],
        ),
      );

  Widget _buildReviewsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Отзывы',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Сводка по рейтингу
            if (_reviews.isNotEmpty)
              RatingSummaryWidget(
                averageRating: _specialist!.avgRating > 0
                    ? _specialist!.avgRating
                    : _specialist!.rating,
                totalReviews: _reviews.length,
                ratingDistribution: _getRatingDistribution(),
              ),

            const SizedBox(height: 16),

            // Список отзывов
            if (_reviews.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Отзывов пока нет',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Станьте первым, кто оставит отзыв',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReviewCard(review: review),
                ),
              ),

            if (_reviews.length >= 10)
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO(developer): Переход к полному списку отзывов
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Переход к полному списку отзывов'),
                      ),
                    );
                  },
                  child: const Text('Показать все отзывы'),
                ),
              ),
          ],
        ),
      );

  Widget _buildPriceListTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Прайс-лист',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PriceListWidget(
              servicesWithPrices: _specialist!.servicesWithPrices,
              hourlyRate: _specialist!.hourlyRate,
              price: _specialist!.price,
            ),
          ],
        ),
      );

  Widget _buildCalendarTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Календарь занятости',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AvailabilityCalendarWidget(
              busyDates: _specialist!.busyDates,
              availableDates: _specialist!.availableDates,
            ),
          ],
        ),
      );

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  // TODO(developer): Получить реальный chatId из ChatService
                  const chatId = 'temp_chat_id';
                  context.go(
                    '/chat/$chatId?specialistName=${widget.specialistId}',
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Написать'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go('/booking/${widget.specialistId}');
                },
                icon: const Icon(Icons.event_available),
                label: const Text('Забронировать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  Map<int, int> _getRatingDistribution() {
    final distribution = <int, int>{};
    for (var i = 1; i <= 5; i++) {
      distribution[i] = _reviews.where((r) => r.rating == i).length;
    }
    return distribution;
  }
}
