import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/specialist_report_service.dart';
import '../widgets/report_chart_widget.dart';

/// Экран отчетов по специалистам
class SpecialistReportsScreen extends ConsumerStatefulWidget {
  const SpecialistReportsScreen({super.key});

  @override
  ConsumerState<SpecialistReportsScreen> createState() => _SpecialistReportsScreenState();
}

class _SpecialistReportsScreenState extends ConsumerState<SpecialistReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SpecialistReportService _reportService = SpecialistReportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Отчеты по специалистам'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Общая статистика'),
              Tab(text: 'По категориям'),
              Tab(text: 'По рейтингам'),
              Tab(text: 'По доходам'),
              Tab(text: 'По активности'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {});
              },
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralStatsTab(),
            _buildCategoryStatsTab(),
            _buildRatingStatsTab(),
            _buildEarningsStatsTab(),
            _buildActivityStatsTab(),
          ],
        ),
      );

  Widget _buildGeneralStatsTab() => FutureBuilder<SpecialistReport>(
        future: _reportService.generateSpecialistReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки отчета',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final report = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportHeader('Общая статистика', report.generatedAt),
                const SizedBox(height: 24),

                // Основные метрики
                _buildMetricsGrid(report),
                const SizedBox(height: 24),

                // Топ категории
                _buildTopCategoriesCard(report),
                const SizedBox(height: 24),

                // Диаграмма распределения
                _buildDistributionChart(report),
              ],
            ),
          );
        },
      );

  Widget _buildCategoryStatsTab() => FutureBuilder<CategoryReport>(
        future: _reportService.generateCategoryReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final report = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportHeader(
                  'Статистика по категориям',
                  report.generatedAt,
                ),
                const SizedBox(height: 24),

                // Список категорий
                ...report.categoryStats.entries.map((entry) {
                  final stats = entry.value;
                  return _buildCategoryStatsCard(stats);
                }),
              ],
            ),
          );
        },
      );

  Widget _buildRatingStatsTab() => FutureBuilder<RatingReport>(
        future: _reportService.generateRatingReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final report = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportHeader(
                  'Статистика по рейтингам',
                  report.generatedAt,
                ),
                const SizedBox(height: 24),

                // Средний рейтинг
                _buildAverageRatingCard(report.averageRating),
                const SizedBox(height: 24),

                // Распределение рейтингов
                _buildRatingDistributionCard(report.ratingDistribution),
                const SizedBox(height: 24),

                // Топ специалисты
                _buildTopRatedSpecialistsCard(report.topRatedSpecialists),
              ],
            ),
          );
        },
      );

  Widget _buildEarningsStatsTab() => FutureBuilder<EarningsReport>(
        future: _reportService.generateEarningsReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final report = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportHeader('Статистика по доходам', report.generatedAt),
                const SizedBox(height: 24),

                // Общие доходы
                _buildEarningsSummaryCard(report),
                const SizedBox(height: 24),

                // Топ зарабатывающие
                _buildTopEarnersCard(report.topEarners),
              ],
            ),
          );
        },
      );

  Widget _buildActivityStatsTab() => FutureBuilder<ActivityReport>(
        future: _reportService.generateActivityReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final report = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportHeader(
                  'Статистика по активности',
                  report.generatedAt,
                ),
                const SizedBox(height: 24),

                // Активность
                _buildActivitySummaryCard(report),
              ],
            ),
          );
        },
      );

  Widget _buildReportHeader(String title, DateTime generatedAt) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Сгенерировано: ${_formatDateTime(generatedAt)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMetricsGrid(SpecialistReport report) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildMetricCard(
            'Всего специалистов',
            report.totalSpecialists.toString(),
            Icons.people,
            Colors.blue,
          ),
          _buildMetricCard(
            'Верифицированных',
            report.verifiedSpecialists.toString(),
            Icons.verified,
            Colors.green,
          ),
          _buildMetricCard(
            'Доступных',
            report.availableSpecialists.toString(),
            Icons.check_circle,
            Colors.orange,
          ),
          _buildMetricCard(
            'Средний рейтинг',
            report.averageRating.toStringAsFixed(1),
            Icons.star,
            Colors.amber,
          ),
          _buildMetricCard(
            'Средняя ставка',
            '${report.averageHourlyRate.toStringAsFixed(0)} ₽/ч',
            Icons.attach_money,
            Colors.purple,
          ),
          _buildMetricCard(
            'Категорий',
            report.totalCategories.toString(),
            Icons.category,
            Colors.teal,
          ),
        ],
      );

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildTopCategoriesCard(SpecialistReport report) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Топ категории',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...report.topCategories.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDistributionChart(SpecialistReport report) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Распределение специалистов',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // Здесь можно добавить диаграмму
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Диаграмма распределения'),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildCategoryStatsCard(CategoryStats stats) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats.categoryName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Специалистов',
                      stats.specialistCount.toString(),
                      Icons.people,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Средний рейтинг',
                      stats.averageRating.toStringAsFixed(1),
                      Icons.star,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Средняя ставка',
                      '${stats.averageHourlyRate.toStringAsFixed(0)} ₽/ч',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Отзывов',
                      stats.totalReviews.toString(),
                      Icons.reviews,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatItem(String label, String value, IconData icon) => Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildAverageRatingCard(double averageRating) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Средний рейтинг',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < averageRating.floor()
                          ? Icons.star
                          : index < averageRating
                              ? Icons.star_half
                              : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildRatingDistributionCard(Map<int, int> distribution) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Распределение рейтингов',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...distribution.entries.map((entry) {
                final total = distribution.values.reduce((a, b) => a + b);
                final percentage = total > 0 ? entry.value / total : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text('${entry.key} звезд'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${entry.value}'),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );

  Widget _buildTopRatedSpecialistsCard(List<SpecialistProfile> specialists) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Топ специалисты по рейтингу',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...specialists.take(5).map(
                    (specialist) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: specialist.photoURL != null
                                ? NetworkImage(specialist.photoURL!)
                                : null,
                            child: specialist.photoURL == null
                                ? Text(
                                    specialist.name?.substring(0, 1).toUpperCase() ?? '?',
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  specialist.name ?? 'Без имени',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  specialist.categoryDisplayNames.join(', '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(specialist.rating.toStringAsFixed(1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );

  Widget _buildEarningsSummaryCard(EarningsReport report) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Общие доходы',
                      '${report.totalEarnings.toStringAsFixed(0)} ₽',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Средние доходы',
                      '${report.averageEarnings.toStringAsFixed(0)} ₽',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildTopEarnersCard(
    List<MapEntry<SpecialistProfile, double>> topEarners,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Топ зарабатывающие специалисты',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...topEarners.take(5).map((entry) {
                final specialist = entry.key;
                final earnings = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            specialist.photoURL != null ? NetworkImage(specialist.photoURL!) : null,
                        child: specialist.photoURL == null
                            ? Text(
                                specialist.name?.substring(0, 1).toUpperCase() ?? '?',
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              specialist.name ?? 'Без имени',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              specialist.categoryDisplayNames.join(', '),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${earnings.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );

  Widget _buildActivitySummaryCard(ActivityReport report) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Активность специалистов',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Активных',
                      report.activeSpecialists.toString(),
                      Icons.check_circle,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Неактивных',
                      report.inactiveSpecialists.toString(),
                      Icons.cancel,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Новых за месяц',
                      report.recentlyJoined.toString(),
                      Icons.new_releases,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки отчета',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
}
