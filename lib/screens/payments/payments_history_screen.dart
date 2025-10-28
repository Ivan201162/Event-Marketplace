import 'package:event_marketplace_app/models/payment.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/providers/payment_providers.dart';
import 'package:event_marketplace_app/widgets/payment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for displaying payment history
class PaymentsHistoryScreen extends ConsumerStatefulWidget {
  const PaymentsHistoryScreen({super.key});

  @override
  ConsumerState<PaymentsHistoryScreen> createState() =>
      _PaymentsHistoryScreenState();
}

class _PaymentsHistoryScreenState extends ConsumerState<PaymentsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('История платежей'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все', icon: Icon(Icons.list)),
            Tab(text: 'Успешные', icon: Icon(Icons.check_circle)),
            Tab(text: 'Неудачные', icon: Icon(Icons.error)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh payments
              ref.invalidate(userPaymentsProvider);
            },
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllPaymentsTab(user.id),
              _buildSuccessfulPaymentsTab(user.id),
              _buildFailedPaymentsTab(user.id),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllPaymentsTab(String userId) {
    final paymentsAsync = ref.watch(userPaymentsStreamProvider(userId));

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.payment,
            title: 'Нет платежей',
            subtitle: 'Здесь будут отображаться ваши платежи',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userPaymentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return PaymentCard(
                  payment: payment, onTap: () => _showPaymentDetails(payment),);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildSuccessfulPaymentsTab(String userId) {
    final successfulPaymentsAsync =
        ref.watch(successfulPaymentsProvider(userId));

    return successfulPaymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle,
            title: 'Нет успешных платежей',
            subtitle: 'Здесь будут отображаться успешно завершенные платежи',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(successfulPaymentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return PaymentCard(
                  payment: payment, onTap: () => _showPaymentDetails(payment),);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildFailedPaymentsTab(String userId) {
    final failedPaymentsAsync = ref.watch(failedPaymentsProvider(userId));

    return failedPaymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.error_outline,
            title: 'Нет неудачных платежей',
            subtitle: 'Здесь будут отображаться неудачные платежи',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(failedPaymentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return PaymentCard(
                  payment: payment, onTap: () => _showPaymentDetails(payment),);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Ошибка загрузки платежей'),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(userPaymentsProvider);
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PaymentDetailsSheet(payment: payment),
    );
  }
}

/// Bottom sheet for displaying payment details
class PaymentDetailsSheet extends StatelessWidget {

  const PaymentDetailsSheet({required this.payment, super.key});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _getPaymentTypeIcon(payment.type),
                      size: 32,
                      color: _getStatusColor(payment.status),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(payment.description,
                              style: Theme.of(context).textTheme.titleLarge,),
                          Text(
                            payment.formattedAmount,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: _getStatusColor(payment.status),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6,),
                      decoration: BoxDecoration(
                        color: _getStatusColor(payment.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        payment.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(payment.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDetailRow('ID платежа', payment.id),
                    _buildDetailRow('Тип', payment.type.displayName),
                    _buildDetailRow(
                        'Способ оплаты', payment.method.displayName,),
                    _buildDetailRow('Сумма', payment.formattedAmount),
                    _buildDetailRow('Комиссия', payment.formattedCommission),
                    _buildDetailRow('К получению', payment.formattedNetAmount),
                    _buildDetailRow('Валюта', payment.currency),
                    _buildDetailRow(
                        'Создан', _formatDateTime(payment.createdAt),),
                    if (payment.completedAt != null)
                      _buildDetailRow(
                          'Завершен', _formatDateTime(payment.completedAt!),),
                    if (payment.failedAt != null)
                      _buildDetailRow(
                          'Неудачен', _formatDateTime(payment.failedAt!),),
                    if (payment.failureReason != null)
                      _buildDetailRow('Причина ошибки', payment.failureReason!),
                    if (payment.stripePaymentIntentId != null)
                      _buildDetailRow(
                          'Stripe ID', payment.stripePaymentIntentId!,),
                  ],
                ),
              ),
              // Actions
              if (payment.canBeRefunded)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement refund
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Функция возврата в разработке'),),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Запросить возврат'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500,),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500),),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentTypeIcon(PaymentType type) {
    switch (type) {
      case PaymentType.booking:
        return Icons.calendar_today;
      case PaymentType.commission:
        return Icons.percent;
      case PaymentType.refund:
        return Icons.undo;
      case PaymentType.payout:
        return Icons.account_balance_wallet;
      case PaymentType.subscription:
        return Icons.subscriptions;
      case PaymentType.premium:
        return Icons.star;
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
