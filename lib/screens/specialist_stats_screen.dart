import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';

/// Экран статистики для специалистов
class SpecialistStatsScreen extends ConsumerStatefulWidget {
  const SpecialistStatsScreen({super.key});

  @override
  ConsumerState<SpecialistStatsScreen> createState() =>
      _SpecialistStatsScreenState();
}

class _SpecialistStatsScreenState extends ConsumerState<SpecialistStatsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserStats();

    // Логируем просмотр экрана статистики
    _analyticsService.logScreenView('specialist_stats_screen');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final stats = await _analyticsService.getUserStats(user.uid);
        setState(() {
          _userStats = stats;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Пользователь не авторизован';
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      setState(() {
        _error = 'Ошибка загрузки статистики: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Статистика'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.analytics), text: 'Общая'),
              Tab(icon: Icon(Icons.trending_up), text: 'Графики'),
              Tab(icon: Icon(Icons.insights), text: 'Аналитика'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUserStats,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralStatsTab(),
                      _buildChartsTab(),
                      _buildAnalyticsTab(),
                    ],
                  ),
      );

  Widget _buildGeneralStatsTab() {
    final stats = _userStats ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основные метрики
          _buildStatsCard(
            title: 'Основные показатели',
            children: [
              _buildStatItem(
                icon: Icons.visibility,
                title: 'Просмотры профиля',
                value: '${stats['views'] ?? 0}',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.request_page,
                title: 'Получено заявок',
                value: '${stats['requests'] ?? 0}',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.cancel,
                title: 'Отклонено заявок',
                value: '${stats['rejected_requests'] ?? 0}',
                color: Colors.red,
              ),
              _buildStatItem(
                icon: Icons.message,
                title: 'Сообщений',
                value: '${stats['messages'] ?? 0}',
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Социальные метрики
          _buildStatsCard(
            title: 'Социальная активность',
            children: [
              _buildStatItem(
                icon: Icons.favorite,
                title: 'Лайки',
                value: '${stats['likes'] ?? 0}',
                color: Colors.pink,
              ),
              _buildStatItem(
                icon: Icons.comment,
                title: 'Комментарии',
                value: '${stats['comments'] ?? 0}',
                color: Colors.purple,
              ),
              _buildStatItem(
                icon: Icons.bookmark,
                title: 'Сохранения',
                value: '${stats['saves'] ?? 0}',
                color: Colors.indigo,
              ),
              _buildStatItem(
                icon: Icons.people,
                title: 'Подписчики',
                value: '${stats['followers'] ?? 0}',
                color: Colors.teal,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Временные метрики
          _buildStatsCard(
            title: 'Временные показатели',
            children: [
              _buildStatItem(
                icon: Icons.timer,
                title: 'Среднее время ответа',
                value: '${stats['averageResponseTime'] ?? 0} ч',
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: Icons.calendar_today,
                title: 'Последний просмотр',
                value: _formatDate(stats['lastViewDate']),
                color: Colors.cyan,
              ),
              _buildStatItem(
                icon: Icons.schedule,
                title: 'Последняя заявка',
                value: _formatDate(stats['lastRequestDate']),
                color: Colors.deepOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    final stats = _userStats ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // График просмотров по дням
          _buildChartCard(
            title: 'Просмотры профиля (7 дней)',
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: AxisTitles(),
                    rightTitles: AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateViewsData(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Круговая диаграмма заявок
          _buildChartCard(
            title: 'Распределение заявок',
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: (stats['requests'] ?? 0).toDouble(),
                      title: 'Принято',
                      color: Colors.green,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: (stats['rejected_requests'] ?? 0).toDouble(),
                      title: 'Отклонено',
                      color: Colors.red,
                      radius: 50,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Столбчатая диаграмма активности
          _buildChartCard(
            title: 'Активность по типам',
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: const BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = [
                            'Просмотры',
                            'Заявки',
                            'Сообщения',
                            'Лайки',
                          ];
                          return Text(titles[value.toInt() % titles.length]);
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateActivityData(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final stats = _userStats ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аналитические карточки
          _buildAnalyticsCard(
            title: 'Эффективность профиля',
            icon: Icons.analytics,
            color: Colors.blue,
            children: [
              _buildAnalyticsItem(
                'Конверсия просмотров в заявки',
                '${_calculateConversionRate(stats)}%',
                Icons.trending_up,
              ),
              _buildAnalyticsItem(
                'Средняя активность в день',
                '${_calculateDailyActivity(stats)}',
                Icons.calendar_today,
              ),
              _buildAnalyticsItem(
                'Рейтинг отклика',
                '${_calculateResponseRating(stats)}/10',
                Icons.star,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildAnalyticsCard(
            title: 'Рекомендации',
            icon: Icons.lightbulb,
            color: Colors.amber,
            children: [
              _buildRecommendationItem(
                'Увеличьте количество постов в ленте',
                'Регулярные публикации повышают видимость профиля',
                Icons.feed,
              ),
              _buildRecommendationItem(
                'Обновите портфолио',
                'Добавьте новые работы для привлечения клиентов',
                Icons.photo_library,
              ),
              _buildRecommendationItem(
                'Улучшите время ответа',
                'Быстрые ответы повышают конверсию',
                Icons.speed,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildAnalyticsCard(
            title: 'Сравнение с другими',
            icon: Icons.compare,
            color: Colors.purple,
            children: [
              _buildAnalyticsItem(
                'Просмотры (среднее по платформе)',
                '${stats['views'] ?? 0} / 150',
                Icons.visibility,
              ),
              _buildAnalyticsItem(
                'Заявки (среднее по платформе)',
                '${stats['requests'] ?? 0} / 25',
                Icons.request_page,
              ),
              _buildAnalyticsItem(
                'Активность (среднее по платформе)',
                '${_calculateActivityScore(stats)} / 7.5',
                Icons.dynamic_feed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required List<Widget> children,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildChartCard({
    required String title,
    required Widget child,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      );

  Widget _buildAnalyticsCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  Widget _buildAnalyticsItem(String title, String value, IconData icon) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );

  Widget _buildRecommendationItem(
    String title,
    String description,
    IconData icon,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.amber[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  List<FlSpot> _generateViewsData() {
    // Генерируем тестовые данные для графика просмотров
    return List.generate(7, (index) {
      final baseViews = (_userStats?['views'] ?? 0) / 7;
      final variation = (index % 3 - 1) * 0.2;
      return FlSpot(index.toDouble(), baseViews * (1 + variation));
    });
  }

  List<BarChartGroupData> _generateActivityData() {
    final stats = _userStats ?? {};
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: (stats['views'] ?? 0).toDouble(),
            color: Colors.blue,
            width: 20,
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: (stats['requests'] ?? 0).toDouble(),
            color: Colors.green,
            width: 20,
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: (stats['messages'] ?? 0).toDouble(),
            color: Colors.orange,
            width: 20,
          ),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(
            toY: (stats['likes'] ?? 0).toDouble(),
            color: Colors.pink,
            width: 20,
          ),
        ],
      ),
    ];
  }

  String _formatDate(date) {
    if (date == null) return 'Никогда';
    try {
      final dateTime =
          date is Timestamp ? date.toDate() : DateTime.parse(date.toString());
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    } on Exception {
      return 'Неизвестно';
    }
  }

  double _calculateConversionRate(Map<String, dynamic> stats) {
    final views = (stats['views'] as int?) ?? 0;
    final requests = (stats['requests'] as int?) ?? 0;
    if (views == 0) return 0;
    return (requests / views * 100).roundToDouble();
  }

  double _calculateDailyActivity(Map<String, dynamic> stats) {
    final totalActivity = ((stats['views'] as int?) ?? 0) +
        ((stats['requests'] as int?) ?? 0) +
        ((stats['messages'] as int?) ?? 0) +
        ((stats['likes'] as int?) ?? 0);
    return (totalActivity / 30).roundToDouble(); // Предполагаем 30 дней
  }

  double _calculateResponseRating(Map<String, dynamic> stats) {
    final responseTime = (stats['averageResponseTime'] as num?) ?? 24;
    if (responseTime <= 1) return 10;
    if (responseTime <= 6) return 8;
    if (responseTime <= 12) return 6;
    if (responseTime <= 24) return 4;
    return 2;
  }

  double _calculateActivityScore(Map<String, dynamic> stats) {
    final totalActivity = ((stats['views'] as int?) ?? 0) +
        ((stats['requests'] as int?) ?? 0) +
        ((stats['messages'] as int?) ?? 0) +
        ((stats['likes'] as int?) ?? 0);
    return (totalActivity / 10).roundToDouble();
  }
}
