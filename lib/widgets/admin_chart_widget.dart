import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'analytics_chart.dart';

/// Тип графика
enum ChartType { line, bar, pie, column }

/// Виджет для отображения графиков в админ-панели
class AdminChartWidget extends StatelessWidget {
  const AdminChartWidget({
    super.key,
    required this.title,
    required this.data,
    required this.chartType,
    this.height = 300,
    this.showLegend = true,
  });

  final String title;
  final List<ChartData> data;
  final ChartType chartType;
  final double height;
  final bool showLegend;

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
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  /// Построение графика в зависимости от типа
  Widget _buildChart() {
    switch (chartType) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.pie:
        return _buildPieChart();
      case ChartType.column:
        return _buildColumnChart();
    }
  }

  /// Линейный график
  Widget _buildLineChart() {
    return SfCartesianChart(
      legend: showLegend ? const Legend(isVisible: true) : const Legend(isVisible: false),
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: const NumericAxis(),
      series: <ChartSeries<ChartData, String>>[
        LineSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          name: title,
          color: Colors.blue,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  /// Столбчатый график
  Widget _buildBarChart() {
    return SfCartesianChart(
      legend: showLegend ? const Legend(isVisible: true) : const Legend(isVisible: false),
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: const NumericAxis(),
      series: <ChartSeries<ChartData, String>>[
        BarSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          name: title,
          color: Colors.blue,
        ),
      ],
    );
  }

  /// Круговая диаграмма
  Widget _buildPieChart() {
    return SfCircularChart(
      legend: showLegend ? const Legend(isVisible: true, position: LegendPosition.bottom) : const Legend(isVisible: false),
      series: <PieSeries<ChartData, String>>[
        PieSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          name: title,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          enableTooltip: true,
        ),
      ],
    );
  }

  /// Колоночный график
  Widget _buildColumnChart() {
    return SfCartesianChart(
      legend: showLegend ? const Legend(isVisible: true) : const Legend(isVisible: false),
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: const NumericAxis(),
      series: <ChartSeries<ChartData, String>>[
        ColumnSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          name: title,
          color: Colors.blue,
        ),
      ],
    );
  }
}
