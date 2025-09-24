import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';
import '../widgets/analytics_card.dart';
import '../widgets/chart_widgets.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.specialistId,
  });

  final String specialistId;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  
  final AnalyticsService _analyticsService = AnalyticsService();
  late TabController _tabController;
  
  SpecialistAnalytics? _analytics;
  List<MonthlyStat> _monthlyStats = [];
  List<ServiceStat> _topServices = [];
  Map<String, double> _comparison = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _analyticsService.getSpecialistAnalytics(widget.specialistId),
        _analyticsService.getMonthlyStats(widget.specialistId),
        _analyticsService.getTopServices(widget.specialistId),
        _analyticsService.getComparisonWithPreviousPeriod(widget.specialistId),
      ]);

      setState(() {
        _analytics = results[0] as SpecialistAnalytics?;
        _monthlyStats = results[1] as List<MonthlyStat>;
        _topServices = results[2] as List<ServiceStat>;
        _comparison = results[3] as Map<String, double>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Обзор'),
            Tab(text: 'Графики'),
            Tab(text: 'Услуги'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _analytics == null
                  ? _buildNoDataWidget()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildChartsTab(),
                        _buildServicesTab(),
                      ],
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки аналитики',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Недостаточно данных',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Данные появятся после первых заказов',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final analytics = _analytics!;
    
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основные метрики
            Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    title: 'Заказы',
                    value: analytics.totalBookings.toString(),
                    subtitle: 'Всего заказов',
                    icon: Icons.event_note,
                    color: Colors.blue,
                    change: _comparison['bookingsChange'],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    title: 'Рейтинг',
                    value: analytics.averageRating.toStringAsFixed(1),
                    subtitle: '${analytics.totalReviews} отзывов',
                    icon: Icons.star,
                    color: Colors.orange,
                    change: _comparison['ratingChange'],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    title: 'Доход',
                    value: '${analytics.totalRevenue.toStringAsFixed(0)} ₽',
                    subtitle: 'Общий доход',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    change: _comparison['revenueChange'],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    title: 'Средний чек',
                    value: '${analytics.averagePrice.toStringAsFixed(0)} ₽',
                    subtitle: 'За заказ',
                    icon: Icons.receipt_long,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Дополнительные метрики
            Text(
              'Детальная статистика',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Завершенные заказы',
                      '${analytics.completedBookings}',
                      '${_calculateCompletionRate(analytics)}%',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Отмененные заказы',
                      '${analytics.cancelledBookings}',
                      '${_calculateCancellationRate(analytics)}%',
                      Icons.cancel_outlined,
                      Colors.red,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Конверсия',
                      '${analytics.conversionRate.toStringAsFixed(1)}%',
                      'Подтверждения',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Время ответа',
                      '${analytics.responseTime} мин',
                      'Среднее',
                      Icons.access_time,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // График заказов по месяцам
            Text(
              'Заказы по месяцам',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 300,
                  child: MonthlyBookingsChart(monthlyStats: _monthlyStats),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // График доходов
            Text(
              'Доходы по месяцам',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 300,
                  child: MonthlyRevenueChart(monthlyStats: _monthlyStats),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // График рейтинга
            Text(
              'Рейтинг по месяцам',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 300,
                  child: MonthlyRatingChart(monthlyStats: _monthlyStats),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Популярные услуги',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            if (_topServices.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет данных об услугах',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _topServices.length,
                itemBuilder: (context, index) {
                  final service = _topServices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(service.serviceName),
                      subtitle: Text(
                        '${service.bookingCount} заказов • Рейтинг ${service.averageRating.toStringAsFixed(1)}',
                      ),
                      trailing: Text(
                        '${service.revenue.toStringAsFixed(0)} ₽',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateCompletionRate(SpecialistAnalytics analytics) {
    if (analytics.totalBookings == 0) return 0.0;
    return (analytics.completedBookings / analytics.totalBookings) * 100;
  }

  double _calculateCancellationRate(SpecialistAnalytics analytics) {
    if (analytics.totalBookings == 0) return 0.0;
    return (analytics.cancelledBookings / analytics.totalBookings) * 100;
  }
}