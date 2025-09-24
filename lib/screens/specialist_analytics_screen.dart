import 'package:flutter/material.dart';

import '../models/specialist_analytics.dart';
import '../services/specialist_analytics_service.dart';
import '../widgets/analytics_card.dart';
import '../widgets/analytics_chart.dart';

/// Экран аналитики для специалистов
class SpecialistAnalyticsScreen extends StatefulWidget {
  const SpecialistAnalyticsScreen({
    super.key,
    required this.specialistId,
  });

  final String specialistId;

  @override
  State<SpecialistAnalyticsScreen> createState() => _SpecialistAnalyticsScreenState();
}

class _SpecialistAnalyticsScreenState extends State<SpecialistAnalyticsScreen>
    with TickerProviderStateMixin {
  final SpecialistAnalyticsService _analyticsService = SpecialistAnalyticsService();
  
  late TabController _tabController;
  
  SpecialistAnalytics? _analytics;
  bool _isLoading = true;
  String _selectedPeriod = '3months';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final period = _getPeriodDates(_selectedPeriod);
      final analytics = await _analyticsService.getSpecialistAnalytics(
        specialistId: widget.specialistId,
        startDate: period['start'],
        endDate: period['end'],
      );

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки аналитики: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, DateTime?> _getPeriodDates(String period) {
    final now = DateTime.now();
    switch (period) {
      case '1month':
        return {
          'start': DateTime(now.year, now.month - 1, now.day),
          'end': now,
        };
      case '3months':
        return {
          'start': DateTime(now.year, now.month - 3, now.day),
          'end': now,
        };
      case '6months':
        return {
          'start': DateTime(now.year, now.month - 6, now.day),
          'end': now,
        };
      case '1year':
        return {
          'start': DateTime(now.year - 1, now.month, now.day),
          'end': now,
        };
      default:
        return {
          'start': DateTime(now.year, now.month - 3, now.day),
          'end': now,
        };
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '1month',
                child: Text('1 месяц'),
              ),
              const PopupMenuItem(
                value: '3months',
                child: Text('3 месяца'),
              ),
              const PopupMenuItem(
                value: '6months',
                child: Text('6 месяцев'),
              ),
              const PopupMenuItem(
                value: '1year',
                child: Text('1 год'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.visibility),
              text: 'Просмотры',
            ),
            Tab(
              icon: Icon(Icons.book_online),
              text: 'Заявки',
            ),
            Tab(
              icon: Icon(Icons.attach_money),
              text: 'Доходы',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Отзывы',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(
                  child: Text('Нет данных для отображения'),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileViewsTab(),
                    _buildBookingsTab(),
                    _buildRevenueTab(),
                    _buildReviewsTab(),
                  ],
                ),
    );

  Widget _buildProfileViewsTab() {
    final views = _analytics!.profileViews;
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AnalyticsCard(
            title: 'Общие просмотры',
            value: views.total.toString(),
            subtitle: 'Всего просмотров профиля',
            icon: Icons.visibility,
            color: Colors.blue,
            trend: views.trend,
          ),
          const SizedBox(height: 16),
          AnalyticsCard(
            title: 'Уникальные просмотры',
            value: views.unique.toString(),
            subtitle: 'Уникальных посетителей',
            icon: Icons.people,
            color: Colors.green,
            trend: views.trend,
          ),
          const SizedBox(height: 16),
          if (views.dailyViews.isNotEmpty) ...[
            const Text(
              'Просмотры по дням',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AnalyticsChart(
              data: views.dailyViews.map((v) => ChartData(
                label: '${v.date.day}/${v.date.month}',
                value: v.count.toDouble(),
              )).toList(),
              color: Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    final bookings = _analytics!.bookings;
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AnalyticsCard(
            title: 'Всего заявок',
            value: bookings.total.toString(),
            subtitle: 'Заявок за период',
            icon: Icons.book_online,
            color: Colors.blue,
            trend: bookings.trend,
          ),
          const SizedBox(height: 16),
          AnalyticsCard(
            title: 'Завершенные',
            value: bookings.completed.toString(),
            subtitle: 'Успешно выполненные заявки',
            icon: Icons.check_circle,
            color: Colors.green,
            trend: 0.0,
          ),
          const SizedBox(height: 16),
          AnalyticsCard(
            title: 'Отмененные',
            value: bookings.cancelled.toString(),
            subtitle: 'Отмененные заявки',
            icon: Icons.cancel,
            color: Colors.red,
            trend: 0.0,
          ),
          const SizedBox(height: 16),
          AnalyticsCard(
            title: 'Конверсия',
            value: '${bookings.conversionRate.toStringAsFixed(1)}%',
            subtitle: 'Процент успешных заявок',
            icon: Icons.trending_up,
            color: Colors.orange,
            trend: 0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    final revenue = _analytics!.revenue;
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AnalyticsCard(
            title: 'Общий доход',
            value: '${revenue.totalRevenue.toInt()} ₽',
            subtitle: 'Доход за период',
            icon: Icons.attach_money,
            color: Colors.green,
            trend: revenue.trend,
          ),
          const SizedBox(height: 16),
          AnalyticsCard(
            title: 'Средний чек',
            value: '${revenue.averageCheck.toInt()} ₽',
            subtitle: 'Средняя стоимость заявки',
            icon: Icons.receipt,
            color: Colors.blue,
            trend: 0.0,
          ),
          const SizedBox(height: 16),
          if (revenue.monthlyRevenue.isNotEmpty) ...[
            const Text(
              'Доходы по месяцам',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AnalyticsChart(
              data: revenue.monthlyRevenue.entries.map((e) => ChartData(
                label: e.key,
                value: e.value,
              )).toList(),
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    final reviews = _analytics!.reviews;
    final performance = _analytics!.performance;
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AnalyticsCard(
            title: 'Всего отзывов',
            value: reviews.total.toString(),
            subtitle: 'Отзывов за период',
            icon: Icons.star,
            color: Colors.amber,
            trend: 0.0,
          ),
          const SizedBox(height: 16),
          AnalyticsCard(
            title: 'Средний рейтинг',
            value: reviews.averageRating.toStringAsFixed(1),
            subtitle: 'Средняя оценка',
            icon: Icons.star_rate,
            color: Colors.orange,
            trend: 0.0,
          ),
          const SizedBox(height: 16),
          AnalyticsCard(
            title: 'Время ответа',
            value: '${performance.responseTime.toStringAsFixed(1)} ч',
            subtitle: 'Среднее время ответа на заявку',
            icon: Icons.access_time,
            color: Colors.blue,
            trend: 0.0,
          ),
          const SizedBox(height: 16),
          AnalyticsCard(
            title: 'Постоянные клиенты',
            value: performance.repeatCustomers.toString(),
            subtitle: 'Клиентов с повторными заявками',
            icon: Icons.people,
            color: Colors.purple,
            trend: 0.0,
          ),
          const SizedBox(height: 16),
          if (reviews.recentReviews.isNotEmpty) ...[
            const Text(
              'Последние отзывы',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...reviews.recentReviews.map((review) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Text(
                    review.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(review.customerName),
                subtitle: Text(review.comment),
                trailing: Text(
                  '${review.createdAt.day}/${review.createdAt.month}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}