import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics.dart';

class MonthlyBookingsChart extends StatelessWidget {
  const MonthlyBookingsChart({
    super.key,
    required this.monthlyStats,
  });

  final List<MonthlyStat> monthlyStats;

  @override
  Widget build(BuildContext context) {
    if (monthlyStats.isEmpty) {
      return const Center(
        child: Text('Нет данных для отображения'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= monthlyStats.length) return const Text('');
                final stat = monthlyStats[value.toInt()];
                return Text(
                  '${stat.month}/${stat.year.toString().substring(2)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: monthlyStats.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.bookings.toDouble());
            }).toList(),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyRevenueChart extends StatelessWidget {
  const MonthlyRevenueChart({
    super.key,
    required this.monthlyStats,
  });

  final List<MonthlyStat> monthlyStats;

  @override
  Widget build(BuildContext context) {
    if (monthlyStats.isEmpty) {
      return const Center(
        child: Text('Нет данных для отображения'),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: monthlyStats.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) * 1.1,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toInt()}k',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= monthlyStats.length) return const Text('');
                final stat = monthlyStats[value.toInt()];
                return Text(
                  '${stat.month}/${stat.year.toString().substring(2)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: monthlyStats.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.revenue,
                color: Colors.green,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class MonthlyRatingChart extends StatelessWidget {
  const MonthlyRatingChart({
    super.key,
    required this.monthlyStats,
  });

  final List<MonthlyStat> monthlyStats;

  @override
  Widget build(BuildContext context) {
    if (monthlyStats.isEmpty) {
      return const Center(
        child: Text('Нет данных для отображения'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= monthlyStats.length) return const Text('');
                final stat = monthlyStats[value.toInt()];
                return Text(
                  '${stat.month}/${stat.year.toString().substring(2)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: monthlyStats.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.averageRating);
            }).toList(),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
