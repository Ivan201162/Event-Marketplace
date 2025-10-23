import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import '../providers/payment_providers.dart';

/// Экран для отображения платежей пользователя
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key, this.userId, this.specialistId});

  final String? userId;
  final String? specialistId;

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PaymentFilter _currentFilter = const PaymentFilter();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.specialistId != null
              ? 'Платежи специалиста'
              : 'Мои платежи'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все', icon: Icon(Icons.list)),
              Tab(text: 'Ожидают', icon: Icon(Icons.schedule)),
              Tab(text: 'Оплачены', icon: Icon(Icons.check_circle)),
              Tab(text: 'Предоплаты', icon: Icon(Icons.payment)),
            ],
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog)
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllPaymentsTab(),
            _buildPendingPaymentsTab(),
            _buildCompletedPaymentsTab(),
            _buildPrepaymentsTab(),
          ],
        ),
      );

  Widget _buildAllPaymentsTab() {
    final paymentsAsync = widget.userId != null
        ? ref.watch(userPaymentsProvider(widget.userId!))
        : ref.watch(specialistPaymentsProvider(widget.specialistId!));

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _buildEmptyState('Нет платежей', 'У вас пока нет платежей');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userPaymentsProvider);
            ref.invalidate(specialistPaymentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(payment);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildPendingPaymentsTab() {
    final userId = widget.userId ?? widget.specialistId ?? '';
    final pendingPaymentsAsync = ref.watch(pendingPaymentsProvider(userId));

    return pendingPaymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _buildEmptyState(
              'Нет ожидающих платежей', 'Все платежи обработаны');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingPaymentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(payment);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildCompletedPaymentsTab() {
    final userId = widget.userId ?? widget.specialistId ?? '';
    final completedPaymentsAsync = ref.watch(completedPaymentsProvider(userId));

    return completedPaymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _buildEmptyState(
              'Нет завершенных платежей', 'Завершенные платежи появятся здесь');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(completedPaymentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(payment);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildPrepaymentsTab() {
    final userId = widget.userId ?? widget.specialistId ?? '';
    final prepaymentsAsync = ref.watch(prepaymentsProvider(userId));

    return prepaymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _buildEmptyState('Нет предоплат', 'Предоплаты появятся здесь');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(prepaymentsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(payment);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildPaymentCard(Payment payment) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Text(payment.type.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.type.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (payment.bookingTitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            payment.bookingTitle!,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(payment.status),
                ],
              ),

              const SizedBox(height: 12),

              // Сумма и информация
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Сумма: ${payment.amount.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        if (payment.fee != null && payment.fee! > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Комиссия: ${payment.fee!.toStringAsFixed(0)} ₽',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (payment.status == PaymentStatus.pending)
                    ElevatedButton(
                      onPressed: () => _handlePayment(payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Оплатить'),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Дополнительная информация
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Создан: ${_formatDate(payment.createdAt)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  if (payment.paidAt != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Оплачен: ${_formatDate(payment.paidAt!)}',
                      style: TextStyle(color: Colors.green[500], fontSize: 12),
                    ),
                  ],
                ],
              ),

              // Описание
              ...[
                const SizedBox(height: 8),
                Text(payment.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ],
          ),
        ),
      );

  Widget _buildStatusChip(PaymentStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case PaymentStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        icon = Icons.schedule;
        break;
      case PaymentStatus.partial:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue[700]!;
        icon = Icons.payment;
        break;
      case PaymentStatus.processing:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue[700]!;
        icon = Icons.hourglass_empty;
        break;
      case PaymentStatus.completed:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case PaymentStatus.paid:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case PaymentStatus.failed:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        icon = Icons.error;
        break;
      case PaymentStatus.cancelled:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        icon = Icons.cancel;
        break;
      case PaymentStatus.refunded:
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple[700]!;
        icon = Icons.undo;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
                fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildErrorState(Object error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(userPaymentsProvider);
                ref.invalidate(specialistPaymentsProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Здесь можно добавить фильтры по статусу, типу, дате и т.д.
            Text('Фильтры будут добавлены в следующей версии'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _handlePayment(Payment payment) {
    // В реальном приложении здесь будет переход к платежному провайдеру
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оплата'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Тип: ${payment.type.displayName}'),
            Text('Сумма: ${payment.amount.toStringAsFixed(0)} ₽'),
            ...[
              const SizedBox(height: 8),
              Text('Описание: ${payment.description}')
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Здесь будет логика оплаты
              _simulatePayment(payment);
            },
            child: const Text('Оплатить'),
          ),
        ],
      ),
    );
  }

  void _simulatePayment(Payment payment) {
    // Симуляция успешной оплаты
    final paymentManager = ref.read(paymentManagerProvider.notifier);
    paymentManager.markAsPaid(
      paymentId: payment.id,
      transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Платеж успешно обработан'),
          backgroundColor: Colors.green),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
