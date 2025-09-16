import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';
import '../widgets/animated_page_transition.dart' as custom;

/// Экран настроек уведомлений
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final settingsNotifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки уведомлений'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: custom.AnimatedList(
        children: [
          _buildSectionHeader(context, 'Уведомления о событиях'),
          _buildNotificationSwitch(
            context,
            title: 'Новые отзывы',
            subtitle: 'Получать уведомления о новых отзывах',
            value: settings.reviewNotifications,
            onChanged: settingsNotifier.updateReviewNotifications,
            icon: Icons.star,
          ),
          _buildNotificationSwitch(
            context,
            title: 'Бронирования',
            subtitle: 'Получать уведомления о статусе бронирований',
            value: settings.bookingNotifications,
            onChanged: settingsNotifier.updateBookingNotifications,
            icon: Icons.event,
          ),
          _buildNotificationSwitch(
            context,
            title: 'Оплаты',
            subtitle: 'Получать уведомления об оплатах',
            value: settings.paymentNotifications,
            onChanged: settingsNotifier.updatePaymentNotifications,
            icon: Icons.payment,
          ),
          _buildNotificationSwitch(
            context,
            title: 'Напоминания',
            subtitle: 'Получать напоминания о предстоящих событиях',
            value: settings.reminderNotifications,
            onChanged: settingsNotifier.updateReminderNotifications,
            icon: Icons.schedule,
          ),
          _buildNotificationSwitch(
            context,
            title: 'Маркетинг',
            subtitle: 'Получать рекламные уведомления и предложения',
            value: settings.marketingNotifications,
            onChanged: settingsNotifier.updateMarketingNotifications,
            icon: Icons.campaign,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Настройки напоминаний'),
          _buildReminderTimeSelector(
            context,
            title: 'Время напоминания',
            subtitle: 'За сколько часов до события напоминать',
            value: settings.reminderHoursBefore,
            onChanged: settingsNotifier.updateReminderHours,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Управление'),
          _buildActionButton(
            context,
            title: 'Очистить все уведомления',
            subtitle: 'Удалить все уведомления из истории',
            icon: Icons.clear_all,
            onTap: () => _showClearNotificationsDialog(context, ref),
          ),
          _buildActionButton(
            context,
            title: 'Тестовое уведомление',
            subtitle: 'Отправить тестовое уведомление',
            icon: Icons.notifications_active,
            onTap: () => _sendTestNotification(context, ref),
          ),
        ],
      ),
    );
  }

  /// Создаёт заголовок секции
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// Создаёт переключатель уведомления
  Widget _buildNotificationSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return custom.AnimatedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  /// Создаёт селектор времени напоминания
  Widget _buildReminderTimeSelector(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final options = [1, 2, 6, 12, 24, 48, 72];

    return custom.AnimatedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((hours) {
              final isSelected = value == hours;
              return custom.AnimatedButton(
                onPressed: () => onChanged(hours),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _formatHours(hours),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Создаёт кнопку действия
  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return custom.AnimatedCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  /// Форматирует часы для отображения
  String _formatHours(int hours) {
    if (hours < 24) {
      return '$hours ч';
    } else {
      final days = hours ~/ 24;
      return '$days д';
    }
  }

  /// Показывает диалог очистки уведомлений
  void _showClearNotificationsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить уведомления'),
        content: const Text(
          'Вы уверены, что хотите удалить все уведомления? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              // Здесь будет логика очистки уведомлений
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Уведомления очищены')),
              );
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  /// Отправляет тестовое уведомление
  void _sendTestNotification(BuildContext context, WidgetRef ref) {
    // final service = ref.read(notificationServiceProvider);

    // Здесь будет логика отправки тестового уведомления
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Тестовое уведомление отправлено')),
    );
  }
}
