import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/transaction.dart';

class RevenueChart extends StatelessWidget {
  const RevenueChart({
    super.key,
    required this.transactions,
    required this.period,
  });
  final List<Transaction> transactions;
  final String period;

  @override
  Widget build(BuildContext context) {
    final chartData = _prepareChartData();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  _getBottomTitle(value),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}k',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          minX: 0,
          maxX: chartData.length - 1.toDouble(),
          minY: 0,
          maxY: _getMaxY(chartData),
          lineBarsData: [
            LineChartBarData(
              spots: chartData
                  .asMap()
                  .entries
                  .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                  .toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.indigo],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _prepareChartData() {
    // For demo purposes, generate sample data
    // In a real app, this would process actual transaction data
    switch (period) {
      case 'week':
        return [1.2, 2.1, 1.8, 3.2, 2.5, 4.1, 3.8];
      case 'month':
        return [
          5.2,
          7.1,
          6.8,
          9.2,
          8.5,
          11.1,
          10.8,
          12.5,
          14.2,
          13.8,
          16.1,
          15.5,
          18.2,
          17.8,
          20.1,
          19.5,
          22.2,
          21.8,
          24.1,
          23.5,
          26.2,
          25.8,
          28.1,
          27.5,
          30.2,
          29.8,
          32.1,
          31.5,
          34.2,
          33.8
        ];
      case 'year':
        return [120, 150, 180, 200, 220, 250, 280, 300, 320, 350, 380, 400];
      default:
        return [1.2, 2.1, 1.8, 3.2, 2.5, 4.1, 3.8];
    }
  }

  String _getBottomTitle(double value) {
    switch (period) {
      case 'week':
        final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
        return days[value.toInt() % days.length];
      case 'month':
        return '${(value + 1).toInt()}';
      case 'year':
        final months = [
          'Янв',
          'Фев',
          'Мар',
          'Апр',
          'Май',
          'Июн',
          'Июл',
          'Авг',
          'Сен',
          'Окт',
          'Ноя',
          'Дек'
        ];
        return months[value.toInt() % months.length];
      default:
        return '${(value + 1).toInt()}';
    }
  }

  double _getMaxY(List<double> data) {
    final max = data.reduce((a, b) => a > b ? a : b);
    return (max * 1.2).ceilToDouble();
  }
}
