import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/specialist_analytics_service.dart';

/// Экран аналитики для специалистов
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SpecialistAnalyticsService _analyticsService =
      SpecialistAnalyticsService();
  String? _currentSpecialistId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Аналитика'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Доходы', icon: Icon(Icons.attach_money)),
              Tab(text: 'Отзывы', icon: Icon(Icons.star)),
              Tab(text: 'Сравнение', icon: Icon(Icons.compare)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildIncomeTab(),
            _buildReviewsTab(),
            _buildComparisonTab(),
          ],
        ),
      );

  Widget _buildIncomeTab() => FutureBuilder<SpecialistAnalytics?>(
        future: _getAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки аналитики: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final analytics = snapshot.data;
          if (analytics == null) {
            return const Center(
              child: Text('Аналитика не найдена'),
            );
          }

          final incomeStats = analytics.incomeStats;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIncomeOverview(incomeStats),
                const SizedBox(height: 24),
                _buildIncomeChart(incomeStats),
                const SizedBox(height: 24),
                _buildBookingsChart(incomeStats),
              ],
            ),
          );
        },
      );

  Widget _buildIncomeOverview(SpecialistIncomeStats stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Обзор доходов',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Общий доход',
                      '${stats.totalIncome.toStringAsFixed(0)} ₽',
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'За месяц',
                      '${stats.monthlyIncome.toStringAsFixed(0)} ₽',
                      Icons.calendar_month,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'За неделю',
                      '${stats.weeklyIncome.toStringAsFixed(0)} ₽',
                      Icons.date_range,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Средний чек',
                      '${stats.averageBookingValue.toStringAsFixed(0)} ₽',
                      Icons.receipt,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _buildIncomeChart(SpecialistIncomeStats stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Доходы по месяцам',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _buildBarChart(stats.incomeByMonth, Colors.green),
              ),
            ],
          ),
        ),
      );

  Widget _buildBookingsChart(SpecialistIncomeStats stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Бронирования по месяцам',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _buildBarChart(
                  stats.bookingsByMonth
                      .map((k, v) => MapEntry(k, v.toDouble())),
                  Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Всего', stats.totalBookings.toString()),
                  _buildStatItem(
                      'Завершено', stats.completedBookings.toString()),
                  _buildStatItem(
                      'Отменено', stats.cancelledBookings.toString()),
                  _buildStatItem(
                    'Успешность',
                    '${(stats.completionRate * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildBarChart(Map<String, double> data, Color color) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Нет данных для отображения'),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: entries.map((entry) {
        final height = maxValue > 0 ? (entry.value / maxValue) * 150 : 0.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              entry.value.toStringAsFixed(0),
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.key.split('-').last,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(String label, String value) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );

  Widget _buildReviewsTab() => FutureBuilder<SpecialistAnalytics?>(
        future: _getAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text('Ошибка загрузки отзывов'),
            );
          }

          final reviewStats = snapshot.data!.reviewStats;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRatingOverview(reviewStats),
                const SizedBox(height: 24),
                _buildRatingDistribution(reviewStats),
                const SizedBox(height: 24),
                _buildReviewsChart(reviewStats),
                const SizedBox(height: 24),
                _buildCommonTags(reviewStats),
              ],
            ),
          );
        },
      );

  Widget _buildRatingOverview(SpecialistReviewStats stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Обзор отзывов',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Средний рейтинг',
                      stats.averageRating.toStringAsFixed(1),
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Всего отзывов',
                      stats.totalReviews.toString(),
                      Icons.rate_review,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Процент ответов',
                      '${(stats.responseRate * 100).toStringAsFixed(1)}%',
                      Icons.reply,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Популярные теги',
                      stats.commonTags.length.toString(),
                      Icons.tag,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildRatingDistribution(SpecialistReviewStats stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Распределение оценок',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRatingBar(
                5,
                stats.fiveStarReviews,
                stats.totalReviews,
                Colors.green,
              ),
              _buildRatingBar(
                4,
                stats.fourStarReviews,
                stats.totalReviews,
                Colors.lightGreen,
              ),
              _buildRatingBar(
                3,
                stats.threeStarReviews,
                stats.totalReviews,
                Colors.yellow,
              ),
              _buildRatingBar(
                2,
                stats.twoStarReviews,
                stats.totalReviews,
                Colors.orange,
              ),
              _buildRatingBar(
                1,
                stats.oneStarReviews,
                stats.totalReviews,
                Colors.red,
              ),
            ],
          ),
        ),
      );

  Widget _buildRatingBar(int stars, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text('$stars'),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count'),
        ],
      ),
    );
  }

  Widget _buildReviewsChart(SpecialistReviewStats stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Отзывы по месяцам',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _buildBarChart(
                  stats.reviewsByMonth.map((k, v) => MapEntry(k, v.toDouble())),
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildCommonTags(SpecialistReviewStats stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Популярные теги',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (stats.commonTags.isEmpty)
                const Text('Нет тегов')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stats.commonTags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      );

  Widget _buildComparisonTab() => FutureBuilder<Map<String, dynamic>>(
        future: _getComparativeAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text('Ошибка загрузки сравнения'),
            );
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComparisonOverview(data),
                const SizedBox(height: 24),
                _buildPercentileChart(data),
              ],
            ),
          );
        },
      );

  Widget _buildComparisonOverview(Map<String, dynamic> data) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Сравнение с другими специалистами',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Процентиль по доходам',
                      '${data['incomePercentile']?.toStringAsFixed(1) ?? '0'}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Процентиль по рейтингу',
                      '${data['ratingPercentile']?.toStringAsFixed(1) ?? '0'}%',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Средний доход',
                      '${data['averageIncome']?.toStringAsFixed(0) ?? '0'} ₽',
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Средний рейтинг',
                      '${data['averageRating']?.toStringAsFixed(1) ?? '0'}',
                      Icons.star_half,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildPercentileChart(Map<String, dynamic> data) {
    final incomePercentile = data['incomePercentile'] as double? ?? 0.0;
    final ratingPercentile = data['ratingPercentile'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ваше место среди специалистов',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPercentileBar('Доходы', incomePercentile, Colors.green),
            const SizedBox(height: 16),
            _buildPercentileBar('Рейтинг', ratingPercentile, Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentileBar(String label, double percentile, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${percentile.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentile / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      );

  Future<SpecialistAnalytics?> _getAnalytics() async {
    _currentSpecialistId ??= 'demo_specialist_id';
    return _analyticsService.getSpecialistAnalytics(_currentSpecialistId!);
  }

  Future<Map<String, dynamic>> _getComparativeAnalytics() async {
    _currentSpecialistId ??= 'demo_specialist_id';
    return _analyticsService.getComparativeAnalytics(_currentSpecialistId!);
  }
}
