import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_event.dart';
import '../services/analytics_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран дашборда аналитики
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsStatistics? _statistics;
  bool _isLoading = true;
  DateTime _selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        title: 'Аналитика приложения',
        body: Column(
          children: [
            // Фильтры по дате
            _buildDateFilters(),

            // Основная статистика
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_statistics != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMainStats(),
                      const SizedBox(height: 16),
                      _buildCharts(),
                      const SizedBox(height: 16),
                      _buildTopScreens(),
                      const SizedBox(height: 16),
                      _buildTopEvents(),
                    ],
                  ),
                ),
              )
            else
              const Center(child: Text('Ошибка загрузки данных')),
          ],
        ),
      );

  Widget _buildDateFilters() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Начальная дата'),
                subtitle: Text(
                  '${_selectedStartDate.day}.${_selectedStartDate.month}.${_selectedStartDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartDate,
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('Конечная дата'),
                subtitle: Text(
                  '${_selectedEndDate.day}.${_selectedEndDate.month}.${_selectedEndDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndDate,
              ),
            ),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: const Text('Обновить'),
            ),
          ],
        ),
      );

  Widget _buildMainStats() {
    if (_statistics == null) return const SizedBox.shrink();

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Основная статистика',
            isTitle: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Всего событий',
                  '${_statistics!.totalEvents}',
                  Colors.blue,
                  Icons.analytics,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Уникальных пользователей',
                  '${_statistics!.uniqueUsers}',
                  Colors.green,
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Активных сессий',
                  '${_statistics!.activeSessions}',
                  Colors.orange,
                  Icons.sessions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Среднее событий на пользователя',
                  _statistics!.averageEventsPerUser.toStringAsFixed(1),
                  Colors.purple,
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Среднее событий на сессию',
                  _statistics!.averageEventsPerSession.toStringAsFixed(1),
                  Colors.teal,
                  Icons.timeline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildCharts() {
    if (_statistics == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildCategoryChart(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPlatformChart(),
        ),
      ],
    );
  }

  Widget _buildCategoryChart() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'События по категориям',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            ..._statistics!.eventsByCategory.entries.map((entry) {
              final percentage = _statistics!.totalEvents > 0
                  ? (entry.value / _statistics!.totalEvents) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );

  Widget _buildPlatformChart() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'События по платформам',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            ..._statistics!.eventsByPlatform.entries.map((entry) {
              final percentage = _statistics!.totalEvents > 0
                  ? (entry.value / _statistics!.totalEvents) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPlatformColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );

  Widget _buildTopScreens() {
    if (_statistics == null) return const SizedBox.shrink();

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Топ экранов',
            isTitle: true,
          ),
          const SizedBox(height: 16),
          ..._statistics!.eventsByScreen.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))
            ..take(10)
                .map(
                  (entry) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                      child: Text(
                        '${_statistics!.eventsByScreen.entries.toList().indexOf(entry) + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                    subtitle: LinearProgressIndicator(
                      value: entry.value /
                          _statistics!.eventsByScreen.values
                              .reduce((a, b) => a > b ? a : b),
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  Widget _buildTopEvents() => FutureBuilder<List<MapEntry<String, int>>>(
        future: _analyticsService.getTopEvents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final topEvents = snapshot.data!;

          return ResponsiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Топ событий',
                  isTitle: true,
                ),
                const SizedBox(height: 16),
                ...topEvents.map(
                  (entry) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.2),
                      child: Text(
                        '${topEvents.indexOf(entry) + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'navigation':
        return Colors.blue;
      case 'authentication':
        return Colors.green;
      case 'booking':
        return Colors.orange;
      case 'payment':
        return Colors.red;
      case 'search':
        return Colors.purple;
      case 'review':
        return Colors.teal;
      case 'communication':
        return Colors.pink;
      case 'profile':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'android':
        return Colors.green;
      case 'ios':
        return Colors.blue;
      case 'web':
        return Colors.orange;
      case 'windows':
        return Colors.blue;
      case 'macos':
        return Colors.grey;
      case 'linux':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedStartDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedEndDate = date;
      });
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statistics = await _analyticsService.getAnalyticsStatistics(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );

      setState(() {
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки статистики: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
