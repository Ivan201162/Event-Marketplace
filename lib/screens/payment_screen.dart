import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import '../services/payment_service.dart';

/// Экран управления платежами
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PaymentService _paymentService = PaymentService();

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Платежи'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.pending), text: 'Ожидающие'),
              Tab(icon: Icon(Icons.check_circle), text: 'Завершенные'),
              Tab(icon: Icon(Icons.analytics), text: 'Статистика'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPendingPaymentsTab(),
            _buildCompletedPaymentsTab(),
            _buildStatisticsTab(),
          ],
        ),
      );

  Widget _buildPendingPaymentsTab() => FutureBuilder<List<Payment>>(
        future: _getPaymentsForUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final payments = snapshot.data ?? [];
          final pendingPayments = payments
              .where(
                (p) =>
                    p.status == PaymentStatus.pending ||
                    p.status == PaymentStatus.processing,
              )
              .toList();

          if (pendingPayments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет ожидающих платежей',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingPayments.length,
            itemBuilder: (context, index) {
              final payment = pendingPayments[index];
              return _buildPaymentCard(payment, showActions: true);
            },
          );
        },
      );

  Widget _buildCompletedPaymentsTab() => FutureBuilder<List<Payment>>(
        future: _getPaymentsForUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final payments = snapshot.data ?? [];
          final completedPayments = payments
              .where(
                (p) =>
                    p.status == PaymentStatus.completed ||
                    p.status == PaymentStatus.failed ||
                    p.status == PaymentStatus.cancelled,
              )
              .toList();

          if (completedPayments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Нет завершенных платежей',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completedPayments.length,
            itemBuilder: (context, index) {
              final payment = completedPayments[index];
              return _buildPaymentCard(payment, showActions: false);
            },
          );
        },
      );

  Widget _buildStatisticsTab() => FutureBuilder<PaymentStatistics>(
        future: _paymentService.getPaymentStatistics(
          'current_user_id',
        ), // TODO(developer): Получить реальный ID пользователя
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data ??
              const PaymentStatistics(
                totalAmount: 0,
                completedAmount: 0,
                pendingAmount: 0,
                completedCount: 0,
                pendingCount: 0,
                failedCount: 0,
                totalCount: 0,
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Общая статистика',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatCard(
                  title: 'Общая сумма',
                  value: '${stats.totalAmount.toStringAsFixed(2)} RUB',
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: 'Завершенные платежи',
                  value: '${stats.completedAmount.toStringAsFixed(2)} RUB',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: 'Ожидающие платежи',
                  value: '${stats.pendingAmount.toStringAsFixed(2)} RUB',
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Детальная статистика',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailStatCard(
                  title: 'Всего платежей',
                  value: stats.totalCount.toString(),
                  subtitle: 'Завершено: ${stats.completedCount}',
                ),
                const SizedBox(height: 12),
                _buildDetailStatCard(
                  title: 'Ожидающие',
                  value: stats.pendingCount.toString(),
                  subtitle: 'В обработке',
                ),
                const SizedBox(height: 12),
                _buildDetailStatCard(
                  title: 'Неудачные',
                  value: stats.failedCount.toString(),
                  subtitle: 'Требуют внимания',
                ),
                const SizedBox(height: 24),
                _buildProgressCard(
                  title: 'Процент завершенных платежей',
                  progress: stats.completionRate / 100,
                  value: '${stats.completionRate.toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 16),
                _buildProgressCard(
                  title: 'Процент завершенной суммы',
                  progress: stats.amountCompletionRate / 100,
                  value: '${stats.amountCompletionRate.toStringAsFixed(1)}%',
                ),
              ],
            ),
          );
        },
      );

  Widget _buildPaymentCard(Payment payment, {required bool showActions}) =>
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.description ?? 'Платеж',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${payment.id}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: _getStatusColor(payment.status)),
                    ),
                    child: Text(
                      _getStatusText(payment.status),
                      style: TextStyle(
                        color: _getStatusColor(payment.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Сумма: ${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Тип: ${_getTypeText(payment.type)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Создан: ${_formatDate(payment.createdAt)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              if (showActions && payment.status == PaymentStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _processPayment(payment),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Оплатить'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelPayment(payment),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Отменить'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDetailStatCard({
    required String title,
    required String value,
    required String subtitle,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildProgressCard({
    required String title,
    required double progress,
    required String value,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.8
                      ? Colors.green
                      : progress > 0.5
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
        ),
      );

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

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.processing:
        return 'Обрабатывается';
      case PaymentStatus.completed:
        return 'Завершен';
      case PaymentStatus.failed:
        return 'Неудачный';
      case PaymentStatus.cancelled:
        return 'Отменен';
      case PaymentStatus.refunded:
        return 'Возвращен';
    }
  }

  String _getTypeText(PaymentType type) {
    switch (type) {
      case PaymentType.advance:
        return 'Аванс';
      case PaymentType.finalPayment:
        return 'Финальный платеж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
      case PaymentType.refund:
        return 'Возврат';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  Future<List<Payment>> _getPaymentsForUser() async {
    // TODO(developer): Implement getting payments for current user
    // For now, return empty list
    return [];
  }

  void _processPayment(Payment payment) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оплата'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Сумма: ${payment.amount.toStringAsFixed(2)} ${payment.currency}',
            ),
            const SizedBox(height: 16),
            const Text('Выберите способ оплаты:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Банковская карта'),
              onTap: () {
                Navigator.of(context).pop();
                _processPaymentWithProvider(payment, PaymentProvider.yooKassa);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('CloudPayments'),
              onTap: () {
                Navigator.of(context).pop();
                _processPaymentWithProvider(
                  payment,
                  PaymentProvider.cloudPayments,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('Тестовый платеж'),
              onTap: () {
                Navigator.of(context).pop();
                _processPaymentWithProvider(payment, PaymentProvider.mock);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPaymentWithProvider(
    Payment payment,
    PaymentProvider provider,
  ) async {
    try {
      final result = await _paymentService.processPaymentWithProvider(
        paymentId: payment.id,
        provider: provider,
        amount: payment.amount,
        description: payment.description ?? 'Платеж',
        returnUrl: 'https://yourapp.com/payment/return',
        metadata: {
          'bookingId': payment.bookingId,
          'customerId': payment.customerId,
        },
      );

      if (result['success'] == true) {
        // В реальном приложении здесь должен быть переход к платежной странице
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Перенаправление на страницу оплаты...'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${result['error']}')),
        );
      }
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обработки платежа: $e')),
      );
    }
  }

  Future<void> _cancelPayment(Payment payment) async {
    try {
      await _paymentService.cancelPayment(payment.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Платеж отменен')),
      );
      setState(() {});
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отмены платежа: $e')),
      );
    }
  }
}
