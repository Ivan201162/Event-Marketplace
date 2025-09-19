import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist_price_stats.dart';
import '../services/specialist_price_stats_service.dart';
import '../ui/responsive/responsive_widgets.dart';

/// Виджет для отображения статистики цен специалиста
class SpecialistPriceStatsWidget extends ConsumerWidget {
  const SpecialistPriceStatsWidget({
    super.key,
    required this.specialistId,
    this.showOverallStats = true,
  });
  final String specialistId;
  final bool showOverallStats;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Consumer(
        builder: (context, ref, child) => ref
            .watch(specialistPriceStatsProvider(specialistId))
            .when(
              data: (stats) {
                if (stats == null) {
                  return _buildNoDataWidget(context);
                }

                return ResponsiveCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Статистика цен',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _refreshStats(ref),
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Обновить статистику',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Общая статистика
                      if (showOverallStats) ...[
                        _buildOverallStats(context, stats),
                        const SizedBox(height: 16),
                      ],

                      // Статистика по категориям
                      Text(
                        'По категориям',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                      const SizedBox(height: 8),

                      ...stats.categoryStats.values.map(
                        (stats) => _buildCategoryStatsCard(context, stats),
                      ),

                      const SizedBox(height: 16),

                      // Предупреждение о том, что цены зависят от условий
                      _buildDisclaimer(),
                    ],
                  ),
                );
              },
              loading: _buildLoadingWidget,
              error: (error, stack) =>
                  _buildErrorWidget(context, error.toString()),
            ),
      );

  Widget _buildNoDataWidget(BuildContext context) => ResponsiveCard(
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Нет данных о ценах',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Статистика цен будет доступна после завершения первых заказов.',
            ),
          ],
        ),
      );

  Widget _buildLoadingWidget() => const ResponsiveCard(
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка статистики...'),
            ],
          ),
        ),
      );

  Widget _buildErrorWidget(BuildContext context, String error) =>
      ResponsiveCard(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Не удалось загрузить статистику: $error'),
          ],
        ),
      );

  Widget _buildOverallStats(
    BuildContext context,
    SpecialistPriceAggregate stats,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withValues(alpha: 0.1),
              Colors.blue.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Общая статистика',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Средняя цена',
                    '${stats.overallAveragePrice.toStringAsFixed(0)} ₽',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Завершено заказов',
                    '${stats.totalCompletedBookings}',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Общий доход',
                    '${stats.totalRevenue.toStringAsFixed(0)} ₽',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Средний чек',
                    '${stats.overallAverageCheck.toStringAsFixed(0)} ₽',
                    Icons.receipt,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildCategoryStatsCard(
    BuildContext context,
    SpecialistPriceStats stats,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ResponsiveText(
                    stats.categoryName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${stats.completedBookings} заказов',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildCategoryStatItem(
                    'Диапазон',
                    stats.priceRange,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildCategoryStatItem(
                    'Средняя',
                    '${stats.averagePrice.toStringAsFixed(0)} ₽',
                    Icons.analytics,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Expanded(
                  child: _buildCategoryStatItem(
                    'Доход',
                    '${stats.totalRevenue.toStringAsFixed(0)} ₽',
                    Icons.monetization_on,
                  ),
                ),
                Expanded(
                  child: _buildCategoryStatItem(
                    'Средний чек',
                    '${stats.averageCheck.toStringAsFixed(0)} ₽',
                    Icons.receipt,
                  ),
                ),
              ],
            ),

            // Дополнительная информация
            if (stats.additionalStats != null) ...[
              const SizedBox(height: 8),
              _buildAdditionalStats(stats.additionalStats!),
            ],
          ],
        ),
      );

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      );

  Widget _buildCategoryStatItem(String label, String value, IconData icon) =>
      Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildAdditionalStats(Map<String, dynamic> additionalStats) {
    final priceDistribution =
        additionalStats['priceDistribution'] as Map<String, int>?;

    if (priceDistribution == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Распределение цен:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: priceDistribution.entries
              .map(
                (entry) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Цены зависят от сложности заказа, времени проведения, дополнительных услуг и других факторов.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      );

  void _refreshStats(WidgetRef ref) {
    ref.invalidate(specialistPriceStatsProvider(specialistId));
  }
}

/// Виджет для отображения статистики цен в профиле специалиста
class SpecialistProfilePriceStatsWidget extends ConsumerWidget {
  const SpecialistProfilePriceStatsWidget({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Consumer(
        builder: (context, ref, child) => ref
            .watch(specialistPriceStatsProvider(specialistId))
            .when(
              data: (stats) {
                if (stats == null) {
                  return const SizedBox.shrink();
                }

                return ResponsiveCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Средняя стоимость заказов',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Краткая статистика
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickStat(
                              'Средняя цена',
                              '${stats.overallAveragePrice.toStringAsFixed(0)} ₽',
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildQuickStat(
                              'Завершено',
                              '${stats.totalCompletedBookings} заказов',
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Ссылка на подробную статистику
                      TextButton.icon(
                        onPressed: () => _showDetailedStats(context, ref),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Подробная статистика'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
      );

  Widget _buildQuickStat(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      );

  void _showDetailedStats(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика цен'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: SpecialistPriceStatsWidget(
            specialistId: specialistId,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

/// Провайдер для статистики цен специалиста
final specialistPriceStatsProvider =
    FutureProvider.family<SpecialistPriceAggregate?, String>(
        (ref, specialistId) async {
  final service = ref.read(specialistPriceStatsServiceProvider);
  return service.getSpecialistPriceStats(specialistId);
});

/// Провайдер для сервиса статистики цен
final specialistPriceStatsServiceProvider =
    Provider<SpecialistPriceStatsService>(
  (ref) => SpecialistPriceStatsService(),
);
