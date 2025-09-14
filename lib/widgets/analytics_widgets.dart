import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics.dart';

/// Виджет KPI
class KPIWidget extends StatelessWidget {
  final KPI kpi;

  const KPIWidget({
    super.key,
    required this.kpi,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    kpi.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusIcon(kpi.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  kpi.value.toStringAsFixed(kpi.unit == '%' ? 1 : 0),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  kpi.unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildProgressBar(context, kpi.targetAchievement),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Цель: ${kpi.target.toStringAsFixed(0)} ${kpi.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                _buildChangeIndicator(context, kpi.percentageChange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Построить иконку статуса
  Widget _buildStatusIcon(KPIStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case KPIStatus.excellent:
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case KPIStatus.good:
        icon = Icons.trending_flat;
        color = Colors.blue;
        break;
      case KPIStatus.average:
        icon = Icons.trending_down;
        color = Colors.orange;
        break;
      case KPIStatus.poor:
        icon = Icons.trending_down;
        color = Colors.red;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }

  /// Построить прогресс-бар
  Widget _buildProgressBar(BuildContext context, double percentage) {
    return LinearProgressIndicator(
      value: percentage / 100,
      backgroundColor: Colors.grey.withOpacity(0.3),
      valueColor: AlwaysStoppedAnimation<Color>(
        percentage >= 100 ? Colors.green : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Построить индикатор изменения
  Widget _buildChangeIndicator(BuildContext context, double change) {
    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 2),
        Text(
          '${change.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Виджет метрики
class MetricWidget extends StatelessWidget {
  final String name;
  final double value;
  final String unit;
  final double? previousValue;
  final IconData? icon;
  final Color? color;

  const MetricWidget({
    super.key,
    required this.name,
    required this.value,
    required this.unit,
    this.previousValue,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final change = previousValue != null ? ((value - previousValue!) / previousValue!) * 100 : 0.0;
    final isPositive = change >= 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: color ?? Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (previousValue != null)
                  _buildChangeIndicator(context, change, isPositive),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(unit == '%' ? 1 : 0)} $unit',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить индикатор изменения
  Widget _buildChangeIndicator(BuildContext context, double change, bool isPositive) {
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 2),
        Text(
          '${change.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Виджет статистики за период
class PeriodStatisticsWidget extends StatelessWidget {
  final PeriodStatistics statistics;

  const PeriodStatisticsWidget({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика за ${_getPeriodName(statistics.period)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_formatDate(statistics.startDate)} - ${_formatDate(statistics.endDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                MetricWidget(
                  name: 'Заявки',
                  value: statistics.getMetric('total_bookings'),
                  unit: 'шт',
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
                MetricWidget(
                  name: 'Подтвержденные',
                  value: statistics.getMetric('confirmed_bookings'),
                  unit: 'шт',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                MetricWidget(
                  name: 'Доход',
                  value: statistics.getMetric('total_revenue'),
                  unit: '₽',
                  icon: Icons.attach_money,
                  color: Colors.amber,
                ),
                MetricWidget(
                  name: 'Рейтинг',
                  value: statistics.getMetric('average_rating'),
                  unit: 'звезд',
                  icon: Icons.star,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Получить название периода
  String _getPeriodName(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.day:
        return 'день';
      case AnalyticsPeriod.week:
        return 'неделю';
      case AnalyticsPeriod.month:
        return 'месяц';
      case AnalyticsPeriod.quarter:
        return 'квартал';
      case AnalyticsPeriod.year:
        return 'год';
    }
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Виджет отчета
class ReportWidget extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;

  const ReportWidget({
    super.key,
    required this.report,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTypeChip(context, report.type),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatDate(report.startDate)} - ${_formatDate(report.endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  /// Построить чип типа отчета
  Widget _buildTypeChip(BuildContext context, ReportType type) {
    Color color;
    String label;

    switch (type) {
      case ReportType.summary:
        color = Colors.blue;
        label = 'Сводный';
        break;
      case ReportType.financial:
        color = Colors.green;
        label = 'Финансовый';
        break;
      case ReportType.performance:
        color = Colors.orange;
        label = 'Производительность';
        break;
      case ReportType.userActivity:
        color = Colors.purple;
        label = 'Активность';
        break;
      case ReportType.custom:
        color = Colors.grey;
        label = 'Пользовательский';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Виджет дашборда
class DashboardWidget extends StatelessWidget {
  final Dashboard dashboard;
  final VoidCallback? onTap;

  const DashboardWidget({
    super.key,
    required this.dashboard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dashboard.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (dashboard.isPublic)
                    Icon(
                      Icons.public,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dashboard.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${dashboard.widgets.length} виджетов',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    _formatDate(dashboard.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Виджет формы отчета
class ReportFormWidget extends ConsumerStatefulWidget {
  final Function(ReportType type, AnalyticsPeriod period, DateTime date)? onSubmit;

  const ReportFormWidget({
    super.key,
    this.onSubmit,
  });

  @override
  ConsumerState<ReportFormWidget> createState() => _ReportFormWidgetState();
}

class _ReportFormWidgetState extends ConsumerState<ReportFormWidget> {
  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(reportFormProvider);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Создать отчет',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Тип отчета
            const Text(
              'Тип отчета',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReportType>(
              value: formState.selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ReportType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getReportTypeName(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(reportFormProvider.notifier).selectType(value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Период
            const Text(
              'Период',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AnalyticsPeriod>(
              value: formState.selectedPeriod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: AnalyticsPeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(_getPeriodName(period)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(reportFormProvider.notifier).selectPeriod(value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Дата
            const Text(
              'Дата',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
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
                    Text(_formatDate(formState.selectedDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Ошибка
            if (formState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formState.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Кнопка создания
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: formState.isGenerating
                    ? null
                    : () => _createReport(),
                child: formState.isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Создать отчет'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Выбрать дату
  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: ref.read(reportFormProvider).selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      ref.read(reportFormProvider.notifier).selectDate(date);
    }
  }

  /// Создать отчет
  void _createReport() {
    final formState = ref.read(reportFormProvider);
    widget.onSubmit?.call(
      formState.selectedType,
      formState.selectedPeriod,
      formState.selectedDate,
    );
  }

  /// Получить название типа отчета
  String _getReportTypeName(ReportType type) {
    switch (type) {
      case ReportType.summary:
        return 'Сводный отчет';
      case ReportType.financial:
        return 'Финансовый отчет';
      case ReportType.performance:
        return 'Отчет по производительности';
      case ReportType.userActivity:
        return 'Отчет по активности пользователей';
      case ReportType.custom:
        return 'Пользовательский отчет';
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
