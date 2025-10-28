import 'package:event_marketplace_app/models/pro_subscription.dart';
import 'package:event_marketplace_app/providers/pro_subscription_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Виджет планов подписки
class SubscriptionPlansWidget extends ConsumerWidget {
  const SubscriptionPlansWidget(
      {required this.userId, required this.onPlanSelected, super.key,});
  final String userId;
  final void Function(SubscriptionPlan) onPlanSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(availablePlansProvider);
    final subscriptionAsync = ref.watch(userSubscriptionProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите план подписки',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        subscriptionAsync.when(
          data: (subscription) => Column(
            children: plansAsync.map((plan) {
              final isCurrentPlan = subscription?.plan == plan;
              final isPopular = plan == SubscriptionPlan.pro;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isCurrentPlan
                        ? Theme.of(context).primaryColor
                        : isPopular
                            ? Colors.orange
                            : Colors.grey.shade300,
                    width: isCurrentPlan || isPopular ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isCurrentPlan
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
                child: Column(
                  children: [
                    if (isPopular)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'ПОПУЛЯРНЫЙ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                plan.displayName,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold,),
                              ),
                              if (isCurrentPlan)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4,),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ТЕКУЩИЙ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 0).format(plan.monthlyPrice)}/месяц',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...plan.features.map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20,),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(feature,
                                        style: const TextStyle(fontSize: 14),),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isCurrentPlan
                                  ? null
                                  : () => onPlanSelected(plan),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCurrentPlan
                                    ? Colors.grey
                                    : Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                isCurrentPlan ? 'Текущий план' : 'Выбрать план',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600,),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Ошибка: $error'),
        ),
      ],
    );
  }
}

/// Виджет текущей подписки
class CurrentSubscriptionWidget extends ConsumerWidget {
  const CurrentSubscriptionWidget({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(userSubscriptionProvider(userId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: subscriptionAsync.when(
          data: (subscription) {
            if (subscription == null) {
              return Column(
                children: [
                  const Icon(Icons.star_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'У вас нет активной подписки',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Оформите PRO подписку для доступа к расширенным функциям',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Навигация к планам подписки
                    },
                    child: const Text('Оформить подписку'),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subscription.plan.displayName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold,),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,),
                      decoration: BoxDecoration(
                        color: _getStatusColor(subscription.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        subscription.status.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Стоимость',
                  '${NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 0).format(subscription.price)}/месяц',
                ),
                _buildInfoRow(
                  'Действует до',
                  DateFormat('dd.MM.yyyy').format(subscription.endDate),
                ),
                if (subscription.trialEndDate != null)
                  _buildInfoRow(
                    'Пробный период до',
                    DateFormat('dd.MM.yyyy').format(subscription.trialEndDate!),
                  ),
                _buildInfoRow('Автопродление',
                    subscription.autoRenew ? 'Включено' : 'Отключено',),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Навигация к управлению подпиской
                        },
                        child: const Text('Управление'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: subscription.status ==
                                SubscriptionStatus.active
                            ? () =>
                                _showCancelDialog(context, ref, subscription.id)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Отменить'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Ошибка: $error'),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 14),),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),),
          ],
        ),
      );

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.trial:
        return Colors.blue;
      case SubscriptionStatus.cancelled:
        return Colors.red;
      case SubscriptionStatus.expired:
        return Colors.orange;
      case SubscriptionStatus.pending:
        return Colors.grey;
    }
  }

  void _showCancelDialog(
      BuildContext context, WidgetRef ref, String subscriptionId,) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить подписку'),
        content: const Text(
          'Вы уверены, что хотите отменить подписку? '
          'Доступ к PRO функциям будет прекращен в конце текущего периода.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(subscriptionStateProvider.notifier)
                  .cancelSubscription(subscriptionId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
  }
}

/// Виджет истории платежей
class PaymentHistoryWidget extends ConsumerWidget {
  const PaymentHistoryWidget({required this.subscriptionId, super.key});
  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentHistoryAsync =
        ref.watch(paymentHistoryProvider(subscriptionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('История платежей',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        const SizedBox(height: 16),
        paymentHistoryAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return const Center(
                child: Text('История платежей пуста',
                    style: TextStyle(color: Colors.grey),),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      _getPaymentIcon(payment.status),
                      color: _getPaymentColor(payment.status),
                    ),
                    title: Text(
                      '${NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 0).format(payment.amount)} ${payment.currency.toUpperCase()}',
                    ),
                    subtitle: Text(DateFormat('dd.MM.yyyy HH:mm')
                        .format(payment.createdAt),),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,),
                      decoration: BoxDecoration(
                        color: _getPaymentColor(payment.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.status.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Ошибка: $error'),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.undo;
    }
  }

  Color _getPaymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
    }
  }
}

/// Виджет статистики подписок (для администраторов)
class SubscriptionStatsWidget extends ConsumerWidget {
  const SubscriptionStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(subscriptionStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика подписок',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  _buildStatRow(
                    'Всего подписок',
                    stats['totalSubscriptions'].toString(),
                    Icons.subscriptions,
                  ),
                  _buildStatRow(
                    'Активных подписок',
                    stats['activeSubscriptions'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatRow(
                    'Пробных подписок',
                    stats['trialSubscriptions'].toString(),
                    Icons.schedule,
                    Colors.blue,
                  ),
                  _buildStatRow(
                    'Общий доход',
                    NumberFormat.currency(
                      locale: 'ru',
                      symbol: '₽',
                      decimalDigits: 0,
                    ).format(stats['totalRevenue']),
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Ошибка: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon,
          [Color? color,]) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),),
            ),
            Text(
              value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color,),
            ),
          ],
        ),
      );
}
