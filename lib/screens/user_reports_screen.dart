import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import '../services/weekly_reports_service.dart';

/// Экран отчётов пользователя
class UserReportsScreen extends ConsumerStatefulWidget {
  const UserReportsScreen({super.key});

  @override
  ConsumerState<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends ConsumerState<UserReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final WeeklyReportsService _reportsService = WeeklyReportsService();
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, dynamic>? _miniReport;
  List<Map<String, dynamic>> _reportsHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();

    // Логируем просмотр экрана отчётов
    _analyticsService.logScreenView('user_reports_screen');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Пользователь не авторизован';
          _isLoading = false;
        });
        return;
      }

      final results = await Future.wait([
        _reportsService.getMiniReport(user.uid),
        _reportsService.getUserReportsHistory(user.uid),
      ]);

      setState(() {
        _miniReport = results[0] as Map<String, dynamic>?;
        _reportsHistory = results[1]! as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки отчётов: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Мои отчёты'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.analytics), text: 'Текущий период'),
              Tab(icon: Icon(Icons.history), text: 'История'),
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
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _loadReports,
                            child: const Text('Повторить')),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [_buildCurrentPeriodTab(), _buildHistoryTab()],
                  ),
      );

  Widget _buildCurrentPeriodTab() {
    if (_miniReport == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет данных за текущий период'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
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
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.analytics,
                            color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Статистика за ${_miniReport!['period']}',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Обновлено: ${_formatDate(_miniReport!['generatedAt'])}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Основные метрики
          _buildMetricsGrid(),

          const SizedBox(height: 16),

          // Дополнительная информация
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_reportsHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('История отчётов пуста'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reportsHistory.length,
      itemBuilder: (context, index) {
        final report = _reportsHistory[index];
        return _buildHistoryReportCard(report);
      },
    );
  }

  Widget _buildMetricsGrid() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Основные показатели',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMetricCard(
                    title: 'Просмотры',
                    value: '${_miniReport!['views']}',
                    icon: Icons.visibility,
                    color: Colors.blue,
                  ),
                  _buildMetricCard(
                    title: 'Заявки',
                    value: '${_miniReport!['requests']}',
                    icon: Icons.request_page,
                    color: Colors.green,
                  ),
                  _buildMetricCard(
                    title: 'Сообщения',
                    value: '${_miniReport!['messages']}',
                    icon: Icons.message,
                    color: Colors.orange,
                  ),
                  _buildMetricCard(
                    title: 'Лайки',
                    value: '${_miniReport!['likes']}',
                    icon: Icons.favorite,
                    color: Colors.pink,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              )
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      );

  Widget _buildAdditionalInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Дополнительная информация',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                'Средняя активность в день',
                '${_calculateDailyActivity()}',
                Icons.calendar_today,
              ),
              _buildInfoItem(
                'Конверсия просмотров',
                '${_calculateConversionRate()}%',
                Icons.trending_up,
              ),
              _buildInfoItem('Рейтинг активности',
                  '${_calculateActivityRating()}/10', Icons.star),
            ],
          ),
        ),
      );

  Widget _buildInfoItem(String title, String value, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.bodyMedium)),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildHistoryReportCard(Map<String, dynamic> report) {
    final reportType = report['type'] as String?;
    final isSpecialist = reportType == 'specialist_weekly';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: (isSpecialist ? Colors.amber : Colors.blue)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSpecialist ? Icons.star : Icons.person,
                    color: isSpecialist ? Colors.amber : Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSpecialist ? 'Отчёт специалиста' : 'Отчёт заказчика',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(report['createdAt']),
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSpecialist) ...[
              _buildHistoryMetric(
                  'Просмотры профиля', '${report['views'] ?? 0}'),
              _buildHistoryMetric(
                  'Получено заявок', '${report['requests'] ?? 0}'),
              _buildHistoryMetric('Сообщений', '${report['messages'] ?? 0}'),
              _buildHistoryMetric('Лайков', '${report['likes'] ?? 0}'),
            ] else ...[
              _buildHistoryMetric(
                  'Создано заявок', '${report['totalRequests'] ?? 0}'),
              _buildHistoryMetric('Просмотрено специалистами',
                  '${report['viewedRequests'] ?? 0}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryMetric(String title, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.bodyMedium)),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  String _formatDate(date) {
    if (date == null) return 'Неизвестно';
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        dateTime = date as DateTime;
      }
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    } catch (e) {
      return 'Неизвестно';
    }
  }

  double _calculateDailyActivity() {
    final views = _miniReport!['views'] as int;
    final requests = _miniReport!['requests'] as int;
    final messages = _miniReport!['messages'] as int;
    final likes = _miniReport!['likes'] as int;

    final totalActivity = views + requests + messages + likes;
    return (totalActivity / 7).roundToDouble();
  }

  double _calculateConversionRate() {
    final views = _miniReport!['views'] as int;
    final requests = _miniReport!['requests'] as int;

    if (views == 0) return 0;
    return (requests / views * 100).roundToDouble();
  }

  double _calculateActivityRating() {
    final dailyActivity = _calculateDailyActivity();
    if (dailyActivity >= 20) return 10;
    if (dailyActivity >= 15) return 8;
    if (dailyActivity >= 10) return 6;
    if (dailyActivity >= 5) return 4;
    return 2;
  }
}
