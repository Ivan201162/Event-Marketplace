import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_providers.dart';
import '../providers/auth_providers.dart';
import '../widgets/analytics_widgets.dart';
import '../models/analytics.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Дашборд'),
            Tab(icon: Icon(Icons.analytics), text: 'KPI'),
            Tab(icon: Icon(Icons.assessment), text: 'Отчеты'),
            Tab(icon: Icon(Icons.timeline), text: 'Статистика'),
          ],
        ),
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Необходима авторизация',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(user.id),
              _buildKPITab(user.id),
              _buildReportsTab(user.id),
              _buildStatisticsTab(user.id),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
            ],
          ),
        ),
      ),
    );
  }

  /// Вкладка дашборда
  Widget _buildDashboardTab(String userId) {
    final dashboardsAsync = ref.watch(userDashboardsProvider(userId));

    return dashboardsAsync.when(
      data: (dashboards) {
        if (dashboards.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет дашбордов',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Создайте дашборд для отслеживания ключевых метрик',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dashboards.length,
          itemBuilder: (context, index) {
            final dashboard = dashboards[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DashboardWidget(
                dashboard: dashboard,
                onTap: () => _viewDashboard(context, dashboard),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки дашбордов: $error'),
          ],
        ),
      ),
    );
  }

  /// Вкладка KPI
  Widget _buildKPITab(String userId) {
    final kpiAsync = ref.watch(kpiProvider(userId));

    return kpiAsync.when(
      data: (kpis) {
        if (kpis.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет данных KPI',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'KPI появятся после накопления данных',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Общий KPI
              Text(
                'Ключевые показатели эффективности',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Сетка KPI
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: kpis.length,
                itemBuilder: (context, index) {
                  final kpi = kpis[index];
                  return KPIWidget(kpi: kpi);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки KPI: $error'),
          ],
        ),
      ),
    );
  }

  /// Вкладка отчетов
  Widget _buildReportsTab(String userId) {
    final reportsAsync = ref.watch(userReportsProvider(userId));

    return reportsAsync.when(
      data: (reports) {
        return Column(
          children: [
            // Форма создания отчета
            Padding(
              padding: const EdgeInsets.all(16),
              child: ReportFormWidget(
                onSubmit: (type, period, date) => _createReport(type, period, date, userId),
              ),
            ),
            
            // Список отчетов
            Expanded(
              child: reports.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assessment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Нет отчетов',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Создайте отчет для анализа данных',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ReportWidget(
                            report: report,
                            onTap: () => _viewReport(context, report),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки отчетов: $error'),
          ],
        ),
      ),
    );
  }

  /// Вкладка статистики
  Widget _buildStatisticsTab(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Выбор периода
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          
          // Статистика за период
          _buildPeriodStatistics(userId),
        ],
      ),
    );
  }

  /// Селектор периода
  Widget _buildPeriodSelector() {
    AnalyticsPeriod selectedPeriod = AnalyticsPeriod.month;
    DateTime selectedDate = DateTime.now();

    return StatefulBuilder(
      builder: (context, setState) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите период',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AnalyticsPeriod>(
                      value: selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Период',
                        border: OutlineInputBorder(),
                      ),
                      items: AnalyticsPeriod.values.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(_getPeriodName(period)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedPeriod = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, selectedDate, (date) {
                        setState(() => selectedDate = date);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Text(_formatDate(selectedDate)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Статистика за период
  Widget _buildPeriodStatistics(String userId) {
    final statisticsAsync = ref.watch(periodStatisticsProvider(PeriodStatisticsParams(
      period: AnalyticsPeriod.month,
      date: DateTime.now(),
      userId: userId,
    )));

    return statisticsAsync.when(
      data: (statistics) {
        return PeriodStatisticsWidget(statistics: statistics);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки статистики: $error'),
          ],
        ),
      ),
    );
  }

  /// Просмотреть дашборд
  void _viewDashboard(BuildContext context, Dashboard dashboard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dashboard.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dashboard.description),
            const SizedBox(height: 16),
            Text('Виджетов: ${dashboard.widgets.length}'),
            Text('Обновлен: ${_formatDate(dashboard.updatedAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Просмотреть отчет
  void _viewReport(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.description),
              const SizedBox(height: 16),
              Text('Тип: ${_getReportTypeName(report.type)}'),
              Text('Период: ${_getPeriodName(report.period)}'),
              Text('Дата создания: ${_formatDate(report.createdAt)}'),
              const SizedBox(height: 16),
              const Text('Данные отчета:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(report.data.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Создать отчет
  Future<void> _createReport(ReportType type, AnalyticsPeriod period, DateTime date, String userId) async {
    ref.read(reportFormProvider.notifier).startGenerating();

    try {
      Report? report;
      
      switch (type) {
        case ReportType.summary:
          report = await ref.read(analyticsStateProvider.notifier).createSummaryReport(
            period: period,
            date: date,
            userId: userId,
          );
          break;
        case ReportType.financial:
          report = await ref.read(analyticsStateProvider.notifier).createFinancialReport(
            period: period,
            date: date,
            userId: userId,
          );
          break;
        case ReportType.performance:
          report = await ref.read(analyticsStateProvider.notifier).createPerformanceReport(
            period: period,
            date: date,
            userId: userId,
          );
          break;
        default:
          throw Exception('Неподдерживаемый тип отчета');
      }

      ref.read(reportFormProvider.notifier).finishGenerating();
      
      if (report != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отчет создан успешно')),
        );
      }
    } catch (e) {
      ref.read(reportFormProvider.notifier).setError(e.toString());
    }
  }

  /// Выбрать дату
  Future<void> _selectDate(BuildContext context, DateTime initialDate, Function(DateTime) onDateSelected) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      onDateSelected(date);
    }
  }

  /// Получить название типа отчета
  String _getReportTypeName(ReportType type) {
    switch (type) {
      case ReportType.summary:
        return 'Сводный';
      case ReportType.financial:
        return 'Финансовый';
      case ReportType.performance:
        return 'Производительность';
      case ReportType.userActivity:
        return 'Активность пользователей';
      case ReportType.custom:
        return 'Пользовательский';
    }
  }

  /// Получить название периода
  String _getPeriodName(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.day:
        return 'День';
      case AnalyticsPeriod.week:
        return 'Неделя';
      case AnalyticsPeriod.month:
        return 'Месяц';
      case AnalyticsPeriod.quarter:
        return 'Квартал';
      case AnalyticsPeriod.year:
        return 'Год';
    }
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
