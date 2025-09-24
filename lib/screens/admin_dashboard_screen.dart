import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mixins/analytics_mixin.dart';
import '../providers/app_statistics_providers.dart';
import '../widgets/admin_statistics_card.dart';
import '../widgets/admin_chart_widget.dart';
import '../widgets/admin_metrics_overview.dart';
import '../widgets/analytics_chart.dart';

/// Экран админ-панели для просмотра глобальной статистики
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with AnalyticsMixin, TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Отслеживание просмотра админ-панели
    WidgetsBinding.instance.addPostFrameCallback((_) {
      trackEvent(name: 'admin_dashboard_viewed');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardStatisticsProvider);
              trackUserAction(action: 'refresh_statistics');
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Обзор', icon: Icon(Icons.dashboard)),
            Tab(text: 'Пользователи', icon: Icon(Icons.people)),
            Tab(text: 'Заявки', icon: Icon(Icons.assignment)),
            Tab(text: 'Доходы', icon: Icon(Icons.attach_money)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildBookingsTab(),
          _buildRevenueTab(),
        ],
      ),
    );
  }

  /// Вкладка обзора
  Widget _buildOverviewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(dashboardStatisticsProvider);
        
        return statisticsAsync.when(
          data: (statistics) => _buildOverviewContent(statistics),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error.toString()),
        );
      },
    );
  }

  /// Контент обзора
  Widget _buildOverviewContent(Map<String, dynamic> statistics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Период
          _buildPeriodInfo(),
          const SizedBox(height: 16),
          
          // Основные метрики
          AdminMetricsOverview(statistics: statistics),
          const SizedBox(height: 24),
          
          // Графики
          Row(
            children: [
              Expanded(
                child: AdminChartWidget(
                  title: 'Пользователи по дням',
                  data: _getUsersChartData(statistics),
                  chartType: ChartType.line,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminChartWidget(
                  title: 'Заявки по статусам',
                  data: _getBookingsChartData(statistics),
                  chartType: ChartType.pie,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Топ категории
          AdminChartWidget(
            title: 'Популярные категории',
            data: _getCategoriesChartData(statistics),
            chartType: ChartType.bar,
          ),
        ],
      ),
    );
  }

  /// Вкладка пользователей
  Widget _buildUsersTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(dashboardStatisticsProvider);
        
        return statisticsAsync.when(
          data: (statistics) => _buildUsersContent(statistics),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error.toString()),
        );
      },
    );
  }

  /// Контент пользователей
  Widget _buildUsersContent(Map<String, dynamic> statistics) {
    final usersData = statistics['month']['users'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статистика пользователей
          Row(
            children: [
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Всего пользователей',
                  value: usersData['total'].toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Новых пользователей',
                  value: usersData['new'].toString(),
                  icon: Icons.person_add,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Активных пользователей',
                  value: usersData['active'].toString(),
                  icon: Icons.person_pin,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Retention Rate',
                  value: '${usersData['retention_rate']}%',
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // График пользователей
          AdminChartWidget(
            title: 'Рост пользователей',
            data: _getUsersGrowthChartData(statistics),
            chartType: ChartType.line,
          ),
          const SizedBox(height: 24),
          
          // Типы пользователей
          AdminChartWidget(
            title: 'Распределение по типам',
            data: _getUserTypesChartData(statistics),
            chartType: ChartType.pie,
          ),
        ],
      ),
    );
  }

  /// Вкладка заявок
  Widget _buildBookingsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(dashboardStatisticsProvider);
        
        return statisticsAsync.when(
          data: (statistics) => _buildBookingsContent(statistics),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error.toString()),
        );
      },
    );
  }

  /// Контент заявок
  Widget _buildBookingsContent(Map<String, dynamic> statistics) {
    final bookingsData = statistics['month']['bookings'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статистика заявок
          Row(
            children: [
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Всего заявок',
                  value: bookingsData['total'].toString(),
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Завершенных',
                  value: bookingsData['statuses']['completed'].toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Конверсия',
                  value: '${bookingsData['completion_rate']}%',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Отменено',
                  value: '${bookingsData['cancellation_rate']}%',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Статусы заявок
          AdminChartWidget(
            title: 'Статусы заявок',
            data: _getBookingStatusesChartData(statistics),
            chartType: ChartType.pie,
          ),
          const SizedBox(height: 24),
          
          // Заявки по категориям
          AdminChartWidget(
            title: 'Заявки по категориям',
            data: _getBookingsByCategoryChartData(statistics),
            chartType: ChartType.bar,
          ),
        ],
      ),
    );
  }

  /// Вкладка доходов
  Widget _buildRevenueTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(dashboardStatisticsProvider);
        
        return statisticsAsync.when(
          data: (statistics) => _buildRevenueContent(statistics),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error.toString()),
        );
      },
    );
  }

  /// Контент доходов
  Widget _buildRevenueContent(Map<String, dynamic> statistics) {
    final revenueData = statistics['month']['revenue'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статистика доходов
          Row(
            children: [
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Общий доход',
                  value: '₽${revenueData['total'].toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Средний платеж',
                  value: '₽${revenueData['average_payment'].toStringAsFixed(0)}',
                  icon: Icons.payment,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Количество платежей',
                  value: revenueData['payment_count'].toString(),
                  icon: Icons.receipt,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminStatisticsCard(
                  title: 'Доход за день',
                  value: '₽${statistics['today']['revenue']['total'].toStringAsFixed(0)}',
                  icon: Icons.today,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Доходы по месяцам
          AdminChartWidget(
            title: 'Доходы по месяцам',
            data: _getMonthlyRevenueChartData(statistics),
            chartType: ChartType.line,
          ),
          const SizedBox(height: 24),
          
          // Доходы по категориям
          AdminChartWidget(
            title: 'Доходы по категориям',
            data: _getRevenueByCategoryChartData(statistics),
            chartType: ChartType.bar,
          ),
        ],
      ),
    );
  }

  /// Информация о периоде
  Widget _buildPeriodInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              'Период: ${_formatDate(_selectedStartDate)} - ${_formatDate(_selectedEndDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Виджет ошибки
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки данных',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(dashboardStatisticsProvider);
              trackUserAction(action: 'retry_after_error');
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  /// Показать выбор диапазона дат
  void _showDateRangePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate,
        end: _selectedEndDate,
      ),
    );

    if (range != null) {
      setState(() {
        _selectedStartDate = range.start;
        _selectedEndDate = range.end;
      });
      
      trackUserAction(action: 'date_range_changed', parameters: {
        'start_date': range.start.toIso8601String(),
        'end_date': range.end.toIso8601String(),
      });
    }
  }

  /// Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // === МЕТОДЫ ДЛЯ ПОДГОТОВКИ ДАННЫХ ГРАФИКОВ ===

  List<ChartData> _getUsersChartData(Map<String, dynamic> statistics) {
    // Здесь должна быть логика для получения данных пользователей по дням
    // Пока возвращаем заглушку
    return [
      const ChartData(label: 'Пн', value: 10),
      const ChartData(label: 'Вт', value: 15),
      const ChartData(label: 'Ср', value: 8),
      const ChartData(label: 'Чт', value: 20),
      const ChartData(label: 'Пт', value: 25),
      const ChartData(label: 'Сб', value: 12),
      const ChartData(label: 'Вс', value: 18),
    ];
  }

  List<ChartData> _getBookingsChartData(Map<String, dynamic> statistics) {
    final bookingsData = statistics['month']['bookings'] as Map<String, dynamic>;
    final statuses = bookingsData['statuses'] as Map<String, dynamic>;
    
    return [
      ChartData(label: 'Завершено', value: (statuses['completed'] as num? ?? 0).toDouble()),
      ChartData(label: 'В процессе', value: (statuses['confirmed'] as num? ?? 0).toDouble()),
      ChartData(label: 'Ожидает', value: (statuses['pending'] as num? ?? 0).toDouble()),
      ChartData(label: 'Отменено', value: (statuses['cancelled'] as num? ?? 0).toDouble()),
    ];
  }

  List<ChartData> _getCategoriesChartData(Map<String, dynamic> statistics) {
    final bookingsData = statistics['month']['bookings'] as Map<String, dynamic>;
    final services = bookingsData['services'] as Map<String, dynamic>;
    
    return services.entries
        .map((entry) => ChartData(label: entry.key, value: (entry.value as num).toDouble()))
        .toList();
  }

  List<ChartData> _getUsersGrowthChartData(Map<String, dynamic> statistics) {
    // Заглушка для графика роста пользователей
    return [
      const ChartData(label: 'Неделя 1', value: 100),
      const ChartData(label: 'Неделя 2', value: 150),
      const ChartData(label: 'Неделя 3', value: 200),
      const ChartData(label: 'Неделя 4', value: 250),
    ];
  }

  List<ChartData> _getUserTypesChartData(Map<String, dynamic> statistics) {
    final usersData = statistics['month']['users'] as Map<String, dynamic>;
    final types = usersData['types'] as Map<String, dynamic>;
    
    return types.entries
        .map((entry) => ChartData(label: entry.key, value: (entry.value as num).toDouble()))
        .toList();
  }

  List<ChartData> _getBookingStatusesChartData(Map<String, dynamic> statistics) {
    final bookingsData = statistics['month']['bookings'] as Map<String, dynamic>;
    final statuses = bookingsData['statuses'] as Map<String, dynamic>;
    
    return statuses.entries
        .map((entry) => ChartData(label: entry.key, value: (entry.value as num).toDouble()))
        .toList();
  }

  List<ChartData> _getBookingsByCategoryChartData(Map<String, dynamic> statistics) {
    final bookingsData = statistics['month']['bookings'] as Map<String, dynamic>;
    final services = bookingsData['services'] as Map<String, dynamic>;
    
    return services.entries
        .map((entry) => ChartData(label: entry.key, value: (entry.value as num).toDouble()))
        .toList();
  }

  List<ChartData> _getMonthlyRevenueChartData(Map<String, dynamic> statistics) {
    final revenueData = statistics['month']['revenue'] as Map<String, dynamic>;
    final monthlyRevenue = revenueData['monthly_revenue'] as Map<String, dynamic>;
    
    return monthlyRevenue.entries
        .map((entry) => ChartData(label: entry.key, value: (entry.value as num).toDouble()))
        .toList();
  }

  List<ChartData> _getRevenueByCategoryChartData(Map<String, dynamic> statistics) {
    final categoriesData = statistics['month']['categories'] as Map<String, dynamic>;
    
    return categoriesData.entries
        .map((entry) => ChartData(label: entry.key, value: ((entry.value as Map)['revenue'] ?? 0.0).toDouble()))
        .toList();
  }
}
