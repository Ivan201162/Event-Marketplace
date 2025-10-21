import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/analytics.dart';

/// Виджет для отображения графиков аналитики
class AnalyticsChartWidget extends StatelessWidget {
  const AnalyticsChartWidget({
    super.key,
    required this.data,
    required this.type,
    required this.title,
    this.subtitle,
  });
  final List<ChartData> data;
  final ChartType type;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
          const SizedBox(height: 16),

          // График
          SizedBox(height: _getChartHeight(), child: _buildChart()),

          const SizedBox(height: 16),

          // Легенда
          if (type == ChartType.pie) _buildLegend(),
        ],
      ),
    ),
  );

  Widget _buildChart() {
    switch (type) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.pie:
        return _buildPieChart();
    }
  }

  Widget _buildLineChart() {
    if (data.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) =>
                  Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < data.length) {
                  return Text(data[value.toInt()].label, style: const TextStyle(fontSize: 12));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
                .toList(),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (data.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) =>
                  Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < data.length) {
                  return Text(data[value.toInt()].label, style: const TextStyle(fontSize: 12));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: true),
        barGroups: data
            .asMap()
            .entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.value,
                    color: entry.value.color ?? Theme.of(context).primaryColor,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPieChart() {
    if (data.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final total = data.fold(0, (sum, item) => sum + item.value);

    return PieChart(
      PieChartData(
        sections: data.map((item) {
          final percentage = (item.value / total) * 100;
          return PieChartSectionData(
            color: item.color ?? Theme.of(context).primaryColor,
            value: item.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildLegend() => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: data
        .map(
          (item) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.color ?? Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(item.label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        )
        .toList(),
  );

  double _getChartHeight() => switch (type) {
    ChartType.line || ChartType.bar => 200,
    ChartType.pie => 250,
  };
}

/// Тип графика
enum ChartType { line, bar, pie }

/// Виджет для отображения статистики
class AnalyticsStatsWidget extends StatelessWidget {
  const AnalyticsStatsWidget({super.key, required this.stats, this.onViewDetails});
  final IncomeExpenseStats stats;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Статистика', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (onViewDetails != null)
                TextButton(onPressed: onViewDetails, child: const Text('Подробнее')),
            ],
          ),
          const SizedBox(height: 16),

          // Основные показатели
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Доходы', stats.totalIncome, Colors.green, Icons.trending_up),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Расходы',
                  stats.totalExpense,
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Чистый доход',
                  stats.netIncome,
                  stats.netIncome >= 0 ? Colors.green : Colors.red,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Транзакции',
                  stats.transactionCount.toDouble(),
                  Colors.blue,
                  Icons.receipt,
                  isCount: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Рост
          if (stats.monthlyData.length >= 2) ...[
            Row(
              children: [
                Expanded(
                  child: _buildGrowthCard(
                    'Рост доходов',
                    stats.incomeGrowthPercentage,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGrowthCard(
                    'Рост расходов',
                    stats.expenseGrowthPercentage,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildStatCard(
    String title,
    double value,
    Color color,
    IconData icon, {
    bool isCount = false,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isCount ? value.toInt().toString() : '${value.toStringAsFixed(0)} ₽',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    ),
  );

  Widget _buildGrowthCard(String title, double percentage, IconData icon) {
    final isPositive = percentage >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения целей
class BudgetGoalsWidget extends StatelessWidget {
  const BudgetGoalsWidget({super.key, required this.goals, this.onAddGoal});
  final List<BudgetGoal> goals;
  final VoidCallback? onAddGoal;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Цели и бюджеты',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (onAddGoal != null)
                IconButton(
                  onPressed: onAddGoal,
                  icon: const Icon(Icons.add),
                  tooltip: 'Добавить цель',
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (goals.isEmpty)
            const Center(child: Text('Нет активных целей'))
          else
            ...goals.map(_buildGoalCard),
        ],
      ),
    ),
  );

  Widget _buildGoalCard(BudgetGoal goal) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getGoalTypeColor(goal.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getGoalTypeText(goal.type),
                style: TextStyle(
                  fontSize: 12,
                  color: _getGoalTypeColor(goal.type),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        if (goal.description != null) ...[
          const SizedBox(height: 4),
          Text(goal.description!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],

        const SizedBox(height: 12),

        // Прогресс
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${goal.currentAmount.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: goal.progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.isAchieved ? Colors.green : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${goal.progressPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: goal.isAchieved ? Colors.green : Colors.grey[600],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          'Цель до: ${_formatDate(goal.targetDate)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    ),
  );

  Color _getGoalTypeColor(BudgetType type) {
    switch (type) {
      case BudgetType.income:
        return Colors.green;
      case BudgetType.expense:
        return Colors.red;
      case BudgetType.savings:
        return Colors.blue;
    }
  }

  String _getGoalTypeText(BudgetType type) {
    switch (type) {
      case BudgetType.income:
        return 'Доход';
      case BudgetType.expense:
        return 'Расход';
      case BudgetType.savings:
        return 'Накопления';
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
