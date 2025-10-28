import 'package:event_marketplace_app/models/subscription_plan.dart';
import 'package:event_marketplace_app/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<UserSubscription> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?['id'];

      if (userId != null) {
        final subscriptions =
            await _subscriptionService.getUserSubscriptions(userId);
        setState(() {
          _subscriptions = subscriptions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки подписок: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои подписки'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = _subscriptions[index];
                    return _buildSubscriptionCard(subscription);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subscriptions_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'У вас нет подписок',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Оформите подписку для расширения возможностей',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Выбрать план'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(UserSubscription subscription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: _getStatusColor(subscription.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(subscription.status),
                    color: _getStatusColor(subscription.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Подписка #${subscription.id.substring(0, 8)}',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getStatusText(subscription.status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getStatusColor(subscription.status),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(subscription.status),
              ],
            ),
            const SizedBox(height: 16),

            // Детали подписки
            _buildDetailRow('Начало:', _formatDate(subscription.startDate)),
            _buildDetailRow('Окончание:', _formatDate(subscription.endDate)),
            _buildDetailRow('Автопродление:',
                subscription.autoRenew ? 'Включено' : 'Выключено',),

            if (subscription.isActive) ...[
              const SizedBox(height: 12),
              _buildProgressBar(subscription),
            ],

            const SizedBox(height: 16),

            // Действия
            if (subscription.isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _toggleAutoRenew(subscription),
                      child: Text(
                        subscription.autoRenew
                            ? 'Отключить автопродление'
                            : 'Включить автопродление',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _cancelSubscription(subscription),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Отменить'),
                    ),
                  ),
                ],
              ),
            ] else if (subscription.status == SubscriptionStatus.expired) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _renewSubscription(subscription),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Продлить подписку'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(UserSubscription subscription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Осталось дней: ${subscription.daysRemaining}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              '${(subscription.progressPercentage * 100).toInt()}%',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: subscription.progressPercentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            subscription.isExpiringSoon ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(SubscriptionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
            color: _getStatusColor(status),
            fontWeight: FontWeight.w500,
            fontSize: 12,),
      ),
    );
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.expired:
        return Colors.orange;
      case SubscriptionStatus.cancelled:
        return Colors.red;
      case SubscriptionStatus.pending:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Icons.check_circle;
      case SubscriptionStatus.expired:
        return Icons.schedule;
      case SubscriptionStatus.cancelled:
        return Icons.cancel;
      case SubscriptionStatus.pending:
        return Icons.pending;
    }
  }

  String _getStatusText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Активна';
      case SubscriptionStatus.expired:
        return 'Истекла';
      case SubscriptionStatus.cancelled:
        return 'Отменена';
      case SubscriptionStatus.pending:
        return 'Ожидает';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _toggleAutoRenew(UserSubscription subscription) async {
    try {
      // TODO: Реализовать переключение автопродления
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Функция автопродления будет реализована в следующей версии',),),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _cancelSubscription(UserSubscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить подписку'),
        content: const Text(
          'Вы уверены, что хотите отменить подписку? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Нет'),),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        final success =
            await _subscriptionService.cancelSubscription(subscription.id);
        if (success) {
          await _loadSubscriptions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Подписка успешно отменена'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Не удалось отменить подписку');
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _renewSubscription(UserSubscription subscription) async {
    try {
      final success =
          await _subscriptionService.renewSubscription(subscription.id);
      if (success) {
        await _loadSubscriptions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Подписка успешно продлена'),
              backgroundColor: Colors.green,),
        );
      } else {
        throw Exception('Не удалось продлить подписку');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }
}
