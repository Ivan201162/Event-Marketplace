import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/price_reminder_provider.dart';
import '../services/price_reminder_service.dart';
import 'responsive_layout.dart';

/// Виджет для отображения напоминаний об обновлении цен
class PriceReminderWidget extends ConsumerWidget {
  final String specialistId;

  const PriceReminderWidget({
    super.key,
    required this.specialistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
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
                        child: ResponsiveText(
                          'Обновите цены на услуги',
                          isTitle: true,
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
  }

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
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.price_check),
              const SizedBox(width: 8),
              ResponsiveText(
                'Управление напоминаниями о ценах',
                isTitle: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Статистика
          Consumer(
            builder: (context, ref, child) {
              return ref.watch(priceReminderStatsProvider).when(
                    data: (stats) => _buildStatsWidget(stats),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Ошибка: $error'),
                  );
            },
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
  }

  Widget _buildStatsWidget(Map<String, int> stats) {
    return Container(
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
                  'Нужно напомнить', stats['needReminder'] ?? 0, Colors.orange),
              _buildStatItem(
                  'Уже напомнили', stats['reminded'] ?? 0, Colors.green),
              _buildStatItem('Всего', stats['total'] ?? 0, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
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
  }

  void _sendBulkReminders(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(priceReminderServiceProvider);
      await service.sendBulkPriceUpdateReminders();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напоминания отправлены')),
      );

      // Обновляем данные
      ref.invalidate(priceReminderStatsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _showSpecialistsList(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Специалисты с устаревшими ценами'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Consumer(
            builder: (context, ref, child) {
              return ref.watch(specialistsWithOutdatedPricesProvider).when(
                    data: (specialists) => ListView.builder(
                      itemCount: specialists.length,
                      itemBuilder: (context, index) {
                        final specialist = specialists[index];
                        return ListTile(
                          title: Text(specialist['name'] ?? ''),
                          subtitle: Text(
                              '${specialist['daysSinceUpdate']} дней назад'),
                          trailing: ElevatedButton(
                            onPressed: () => _sendReminderToSpecialist(
                                context, ref, specialist['id']),
                            child: const Text('Напомнить'),
                          ),
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Ошибка: $error'),
                  );
            },
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

  void _sendReminderToSpecialist(
      BuildContext context, WidgetRef ref, String specialistId) async {
    try {
      final service = ref.read(priceReminderServiceProvider);
      await service.sendPriceUpdateReminder(specialistId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напоминание отправлено')),
      );

      // Обновляем данные
      ref.invalidate(specialistsWithOutdatedPricesProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
}
