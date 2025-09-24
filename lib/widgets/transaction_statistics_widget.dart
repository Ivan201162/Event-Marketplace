import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/transaction_history_service.dart';

/// Виджет статистики транзакций
class TransactionStatisticsWidget extends StatelessWidget {
  const TransactionStatisticsWidget({
    super.key,
    required this.statistics,
    required this.monthlyData,
    required this.onPeriodChanged,
  });

  final TransactionStatistics statistics;
  final List<MonthlyTransactionData> monthlyData;
  final void Function(DateTime?, DateTime?) onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Период и фильтры
          _buildPeriodSelector(context),
          
          const SizedBox(height: 16),
          
          // Основные метрики
          _buildMetricsCards(context),
          
          const SizedBox(height: 16),
          
          // График доходов
          if (monthlyData.isNotEmpty) ...[
            _buildIncomeChart(context),
            const SizedBox(height: 16),
          ],
          
          // Детальная статистика
          _buildDetailedStatistics(context),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Период',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      statistics.period.startDate != null
                          ? _formatDate(statistics.period.startDate!)
                          : 'Начальная дата',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('—'),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      statistics.period.endDate != null
                          ? _formatDate(statistics.period.endDate!)
                          : 'Конечная дата',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCards(BuildContext context) {
    final theme = Theme.of(context);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildMetricCard(
          context,
          'Общий доход',
          '${statistics.totalIncome.toStringAsFixed(2)} ₽',
          Icons.trending_up,
          Colors.green,
        ),
        _buildMetricCard(
          context,
          'Возвраты',
          '${statistics.totalRefunds.toStringAsFixed(2)} ₽',
          Icons.trending_down,
          Colors.red,
        ),
        _buildMetricCard(
          context,
          'Чистый доход',
          '${statistics.netIncome.toStringAsFixed(2)} ₽',
          Icons.account_balance_wallet,
          Colors.blue,
        ),
        _buildMetricCard(
          context,
          'Успешность',
          '${statistics.successRate.toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeChart(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Доходы по месяцам',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}k',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < monthlyData.length) {
                            final month = monthlyData[value.toInt()].month;
                            return Text(
                              '${month.month}/${month.year.toString().substring(2)}',
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.income / 1000, // Конвертируем в тысячи
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
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
  }

  Widget _buildDetailedStatistics(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Детальная статистика',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatisticRow(
              context,
              'Всего транзакций',
              statistics.totalTransactions.toString(),
            ),
            _buildStatisticRow(
              context,
              'Завершенных',
              statistics.completedTransactions.toString(),
              Colors.green,
            ),
            _buildStatisticRow(
              context,
              'Неудачных',
              statistics.failedTransactions.toString(),
              Colors.red,
            ),
            _buildStatisticRow(
              context,
              'Ожидающих',
              statistics.pendingTransactions.toString(),
              Colors.orange,
            ),
            _buildStatisticRow(
              context,
              'Средняя сумма',
              '${statistics.averageTransactionAmount.toStringAsFixed(2)} ₽',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticRow(
    BuildContext context,
    String label,
    String value, [
    Color? valueColor,
  ]) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (statistics.period.startDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (statistics.period.endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      if (isStartDate) {
        onPeriodChanged(selectedDate, statistics.period.endDate);
      } else {
        onPeriodChanged(statistics.period.startDate, selectedDate);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
           '${date.month.toString().padLeft(2, '0')}.'
           '${date.year}';
  }
}
