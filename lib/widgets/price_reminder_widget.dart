import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/price_reminder_provider.dart';
import 'responsive_layout.dart';

/// Виджет для отображения напоминаний об обновлении цен
class PriceReminderWidget extends ConsumerWidget {
  const PriceReminderWidget({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Consumer(
        builder: (context, ref, child) {
          final service = ref.read(priceReminderServiceProvider);

          return FutureBuilder<Map<String, int>>(
            future: service.getReminderStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final stats = snapshot.data ?? {};
              final needReminder = stats['needReminder'] ?? 0;

              if (needReminder == 0) {
                return const SizedBox.shrink();
              }

              return ResponsiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Обновите цены на услуги',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _dismissReminder(context, ref),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ваши цены не обновлялись более 30 дней. Обновите их для привлечения клиентов.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updatePrices(context, ref),
                            icon: const Icon(Icons.edit),
                            label: const Text('Обновить цены'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _dismissReminder(context, ref),
                          icon: const Icon(Icons.snooze),
                          label: const Text('Напомнить позже'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

  void _updatePrices(BuildContext context, WidgetRef ref) {
    // Навигация к экрану обновления цен
    Navigator.pushNamed(context, '/specialist/services');
  }

  void _dismissReminder(BuildContext context, WidgetRef ref) {
    // Скрыть напоминание на 7 дней
    final service = ref.read(priceReminderServiceProvider);
    service.markPricesUpdated(specialistId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Напоминание скрыто на 7 дней')),
    );
  }
}

/// Виджет для админки - управление напоминаниями
class PriceReminderAdminWidget extends ConsumerWidget {
  const PriceReminderAdminWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.price_check),
                const SizedBox(width: 8),
                Text(
                  'Управление напоминаниями о ценах',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Статистика
            Consumer(
              builder: (context, ref, child) =>
                  ref.watch(priceReminderStatsProvider).when(
                        data: _buildStatsWidget,
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Ошибка: $error'),
                      ),
            ),

            const SizedBox(height: 16),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendBulkReminders(context, ref),
                    icon: const Icon(Icons.send),
                    label: const Text('Отправить напоминания'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showSpecialistsList(context, ref),
                  icon: const Icon(Icons.list),
                  label: const Text('Список специалистов'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatsWidget(Map<String, int> stats) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Нужно напомнить',
                  stats['needReminder'] ?? 0,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Уже напомнили',
                  stats['reminded'] ?? 0,
                  Colors.green,
                ),
                _buildStatItem('Всего', stats['total'] ?? 0, Colors.blue),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatItem(String label, int value, Color color) => Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Future<void> _sendBulkReminders(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(priceReminderServiceProvider);
      await service.sendBulkPriceUpdateReminders();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напоминания отправлены')),
      );

      // Обновляем данные
      ref.invalidate(priceReminderStatsProvider);
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _showSpecialistsList(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Специалисты с устаревшими ценами'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Consumer(
            builder: (context, ref, child) =>
                ref.watch(specialistsWithOutdatedPricesProvider).when(
                      data: (specialists) => ListView.builder(
                        itemCount: specialists.length,
                        itemBuilder: (context, index) {
                          final specialist = specialists[index];
                          return ListTile(
                            title: Text(specialist['name'] as String? ?? ''),
                            subtitle: Text(
                              '${specialist['daysSinceUpdate']} дней назад',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _sendReminderToSpecialist(
                                context,
                                ref,
                                specialist['id'] as String,
                              ),
                              child: const Text('Напомнить'),
                            ),
                          );
                        },
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text('Ошибка: $error'),
                    ),
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

  Future<void> _sendReminderToSpecialist(
    BuildContext context,
    WidgetRef ref,
    String specialistId,
  ) async {
    try {
      final service = ref.read(priceReminderServiceProvider);
      await service.sendPriceUpdateReminder(specialistId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напоминание отправлено')),
      );

      // Обновляем данные
      ref.invalidate(specialistsWithOutdatedPricesProvider);
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
}
