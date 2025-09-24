import 'package:flutter/material.dart';

/// Виджет для отображения основных метрик в админ-панели
class AdminMetricsOverview extends StatelessWidget {
  const AdminMetricsOverview({
    super.key,
    required this.statistics,
  });

  final Map<String, dynamic> statistics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Основные метрики',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Сегодня
        _buildPeriodSection(
          context,
          'Сегодня',
          statistics['today'] as Map<String, dynamic>,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        
        // За неделю
        _buildPeriodSection(
          context,
          'За неделю',
          statistics['week'] as Map<String, dynamic>,
          Colors.green,
        ),
        const SizedBox(height: 16),
        
        // За месяц
        _buildPeriodSection(
          context,
          'За месяц',
          statistics['month'] as Map<String, dynamic>,
          Colors.orange,
        ),
      ],
    );
  }

  /// Секция для периода
  Widget _buildPeriodSection(
    BuildContext context,
    String periodName,
    Map<String, dynamic> periodData,
    Color color,
  ) {
    final users = periodData['users'] as Map<String, dynamic>;
    final bookings = periodData['bookings'] as Map<String, dynamic>;
    final revenue = periodData['revenue'] as Map<String, dynamic>;
    final specialists = periodData['specialists'] as Map<String, dynamic>;

    return Card(
      color: color.withValues(alpha: 0.05),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  periodName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Метрики в сетке
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricItem(
                  context,
                  'Пользователи',
                  users['total'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildMetricItem(
                  context,
                  'Специалисты',
                  specialists['total'].toString(),
                  Icons.person_pin,
                  Colors.green,
                ),
                _buildMetricItem(
                  context,
                  'Заявки',
                  bookings['total'].toString(),
                  Icons.assignment,
                  Colors.orange,
                ),
                _buildMetricItem(
                  context,
                  'Доход',
                  '₽${revenue['total'].toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Элемент метрики
  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
