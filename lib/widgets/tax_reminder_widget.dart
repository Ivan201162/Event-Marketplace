import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tax_info.dart';
import '../services/tax_reminder_service.dart';

/// Виджет для отображения напоминаний о налогах
class TaxReminderWidget extends ConsumerStatefulWidget {
  const TaxReminderWidget({super.key});

  @override
  ConsumerState<TaxReminderWidget> createState() => _TaxReminderWidgetState();
}

class _TaxReminderWidgetState extends ConsumerState<TaxReminderWidget> {
  final TaxReminderService _reminderService = TaxReminderService();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<TaxInfo>>(
        future: _reminderService.getTaxesNeedingReminder(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      'Ошибка загрузки напоминаний: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final reminders = snapshot.data ?? [];

          if (reminders.isEmpty) {
            return const SizedBox.shrink();
          }

          return Card(
            margin: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Напоминания о налогах',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'У вас ${reminders.length} ${_getReminderText(reminders.length)} требуют внимания',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ...reminders.take(3).map(_buildReminderItem),
                  if (reminders.length > 3) ...[
                    const SizedBox(height: 8),
                    Text(
                      'И ещё ${reminders.length - 3} напоминаний...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAllReminders(reminders),
                      icon: const Icon(Icons.list),
                      label: const Text('Посмотреть все'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _buildReminderItem(TaxInfo taxInfo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(
              taxInfo.taxTypeIcon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${taxInfo.taxTypeDisplayName} - ${taxInfo.period}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'К доплате: ${taxInfo.formattedTaxAmount}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _sendReminder(taxInfo),
              icon: const Icon(Icons.send, size: 16),
              tooltip: 'Отправить напоминание',
            ),
          ],
        ),
      );

  String _getReminderText(int count) {
    if (count == 1) return 'налог';
    if (count >= 2 && count <= 4) return 'налога';
    return 'налогов';
  }

  void _showAllReminders(List<TaxInfo> reminders) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Все напоминания'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(
                    reminder.taxTypeIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(reminder.taxTypeDisplayName),
                  subtitle: Text('Период: ${reminder.period}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        reminder.formattedTaxAmount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        'К доплате',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _sendReminder(reminder),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReminder(TaxInfo taxInfo) async {
    try {
      await _reminderService.sendTaxReminder(taxInfo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Напоминание отправлено'),
            backgroundColor: Colors.green,
          ),
        );
        // Обновляем виджет
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки напоминания: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Виджет для отображения статистики напоминаний
class TaxReminderStatsWidget extends ConsumerWidget {
  const TaxReminderStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FutureBuilder<Map<String, dynamic>>(
        future: TaxReminderService().getReminderStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ошибка загрузки статистики: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final stats = snapshot.data ?? {};
          final recentReminders = stats['recentRemindersCount'] as int? ?? 0;
          final overdueTaxes = stats['overdueTaxesCount'] as int? ?? 0;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Статистика напоминаний',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Отправлено за неделю',
                          recentReminders.toString(),
                          Icons.send,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Просрочено',
                          overdueTaxes.toString(),
                          Icons.warning,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
            textAlign: TextAlign.center,
          ),
        ],
      );
}
