import 'package:flutter/material.dart';
import '../services/specialist_pricing_service.dart';

/// Виджет для отображения среднего прайса специалиста
class SpecialistAveragePriceWidget extends StatefulWidget {
  const SpecialistAveragePriceWidget({
    super.key,
    required this.specialistId,
    this.showHistory = false,
  });

  final String specialistId;
  final bool showHistory;

  @override
  State<SpecialistAveragePriceWidget> createState() => _SpecialistAveragePriceWidgetState();
}

class _SpecialistAveragePriceWidgetState extends State<SpecialistAveragePriceWidget> {
  final SpecialistPricingService _service = SpecialistPricingService();
  SpecialistPricingStats? _stats;
  List<PriceHistoryEntry> _history = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPricingData();
  }

  Future<void> _loadPricingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _service.getSpecialistPricingStats(widget.specialistId);

      var history = <PriceHistoryEntry>[];
      if (widget.showHistory) {
        history = await _service.getSpecialistPriceHistory(widget.specialistId);
      }

      setState(() {
        _stats = stats;
        _history = history;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _PricingLoadingWidget();
    }

    if (_error != null) {
      return _PricingErrorWidget(error: _error!, onRetry: _loadPricingData);
    }

    if (_stats == null || _stats!.totalOrders == 0) {
      return const _NoPricingDataWidget();
    }

    return _PricingStatsWidget(stats: _stats!, history: _history, showHistory: widget.showHistory);
  }
}

/// Виджет загрузки
class _PricingLoadingWidget extends StatelessWidget {
  const _PricingLoadingWidget();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    child: const Row(
      children: [
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 12),
        Text('Загружаем статистику цен...'),
      ],
    ),
  );
}

/// Виджет ошибки
class _PricingErrorWidget extends StatelessWidget {
  const _PricingErrorWidget({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ошибка загрузки статистики цен',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 8),
        Text(error, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
      ],
    ),
  );
}

/// Виджет отсутствия данных
class _NoPricingDataWidget extends StatelessWidget {
  const _NoPricingDataWidget();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Colors.grey, size: 20),
        SizedBox(width: 12),
        Text('Нет данных о завершенных заказах', style: TextStyle(color: Colors.grey)),
      ],
    ),
  );
}

/// Виджет статистики цен
class _PricingStatsWidget extends StatelessWidget {
  const _PricingStatsWidget({
    required this.stats,
    required this.history,
    required this.showHistory,
  });

  final SpecialistPricingStats stats;
  final List<PriceHistoryEntry> history;
  final bool showHistory;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Средний прайс по заказам',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        _PricingStatsCard(stats: stats),
        if (showHistory && history.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PricingHistoryWidget(history: history),
        ],
      ],
    ),
  );
}

/// Карточка статистики цен
class _PricingStatsCard extends StatelessWidget {
  const _PricingStatsCard({required this.stats});

  final SpecialistPricingStats stats;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _PricingStatItem(
                    label: 'Средний прайс',
                    value: stats.averagePrice,
                    color: Colors.blue,
                    isMain: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PricingStatItem(
                    label: 'Заказов',
                    value: stats.totalOrders.toDouble(),
                    color: Colors.green,
                    isCount: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PricingStatItem(
                    label: 'Минимальный',
                    value: stats.minPrice,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PricingStatItem(
                    label: 'Максимальный',
                    value: stats.maxPrice,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PricingStatItem(
                    label: 'Медианный',
                    value: stats.medianPrice,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Обновлено: ${_formatDate(stats.lastUpdated)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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

/// Элемент статистики цены
class _PricingStatItem extends StatelessWidget {
  const _PricingStatItem({
    required this.label,
    required this.value,
    required this.color,
    this.isMain = false,
    this.isCount = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool isMain;
  final bool isCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: isMain ? 12 : 10, color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          isCount ? value.toInt().toString() : '${value.toStringAsFixed(0)} ₽',
          style: TextStyle(fontSize: isMain ? 16 : 12, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

/// Виджет истории цен
class _PricingHistoryWidget extends StatelessWidget {
  const _PricingHistoryWidget({required this.history});

  final List<PriceHistoryEntry> history;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История цен (последние месяцы)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...history.take(6).map((entry) => _HistoryEntryWidget(entry: entry)),
          ],
        ),
      ),
    ),
  );
}

/// Виджет записи истории
class _HistoryEntryWidget extends StatelessWidget {
  const _HistoryEntryWidget({required this.entry});

  final PriceHistoryEntry entry;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            _formatMonth(entry.month),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          '${entry.averagePrice.toStringAsFixed(0)} ₽',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(width: 8),
        Text(
          '(${entry.orderCount} зак.)',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    ),
  );
}

/// Форматирование даты
String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

/// Форматирование месяца
String _formatMonth(String month) {
  final parts = month.split('-');
  if (parts.length == 2) {
    final year = parts[0];
    final monthNum = int.tryParse(parts[1]) ?? 1;
    final monthNames = [
      '',
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
      'Дек',
    ];
    return '${monthNames[monthNum]} $year';
  }
  return month;
}
