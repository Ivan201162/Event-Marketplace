import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/booking_payments_provider.dart';

/// Виджет для отображения статуса платежа
class PaymentStatusWidget extends ConsumerWidget {
  const PaymentStatusWidget({
    super.key,
    required this.bookingId,
    this.showDetails = false,
    this.compact = false,
  });

  final String bookingId;
  final bool showDetails;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(bookingPaymentsProvider(bookingId));

    return paymentsAsync.when(
      data: (payment) {
        if (payment == null) {
          return _buildNoPayments(context);
        }

        if (compact) {
          return _buildCompactStatus(context, payment);
        } else {
          return _buildDetailedStatus(context, payment);
        }
      },
      loading: () => _buildLoading(context),
      error: (error, stack) => _buildError(context, error),
    );
  }

  Widget _buildNoPayments(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Платеж не создан',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildLoading(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Загрузка...',
              style: TextStyle(fontSize: 12, color: Colors.blue[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildError(BuildContext context, Object error) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red[600]),
            const SizedBox(width: 4),
            Text(
              'Ошибка загрузки',
              style: TextStyle(fontSize: 12, color: Colors.red[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildCompactStatus(BuildContext context, BookingPayment payment) {
    return _buildPaymentStatusChip(
      context,
      payment.status,
      payment.amount,
    );
  }

  Widget _buildDetailedStatus(
    BuildContext context,
    BookingPayment payment,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(Icons.payment, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Статус оплаты',
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Информация о платеже
          _buildPaymentCard(context, payment),
          const SizedBox(height: 8),

          // Общая информация
          if (showDetails) ...[_buildPaymentSummary(context, payment)],
        ],
      );

  Widget _buildPaymentStatusChip(
    BuildContext context,
    String status,
    double amount,
  ) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        icon = Icons.schedule;
        break;
      case 'processing':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue[700]!;
        icon = Icons.hourglass_empty;
        break;
      case 'paid':
      case 'completed':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case 'failed':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        icon = Icons.error;
        break;
      case 'cancelled':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        icon = Icons.cancel;
        break;
      case 'refunded':
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple[700]!;
        icon = Icons.undo;
        break;
      case 'disputed':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        icon = Icons.gavel;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        icon = Icons.help;
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
            '${amount.toStringAsFixed(0)} ₽',
            style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, BookingPayment payment) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок платежа
              Row(
                children: [
                  Icon(Icons.payment, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Платеж',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${payment.amount.toStringAsFixed(0)} ₽',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context, payment.status),
                ],
              ),

              const SizedBox(height: 8),

              // Дополнительная информация
              ...[
                Text(
                  'Платеж',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
              ],

              // Даты
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Создан: ${_formatDate(payment.updatedAt)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  if (payment.status == 'paid' || payment.status == 'completed') ...[
                    const SizedBox(width: 12),
                    Icon(Icons.check_circle, size: 14, color: Colors.green[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Оплачен: ${_formatDate(payment.updatedAt)}',
                      style: TextStyle(color: Colors.green[500], fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatusChip(BuildContext context, String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        break;
      case 'processing':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue[700]!;
        break;
      case 'paid':
      case 'completed':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        break;
      case 'failed':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        break;
      case 'cancelled':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        break;
      case 'refunded':
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple[700]!;
        break;
      case 'disputed':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getStatusDisplayName(status),
        style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Ожидает';
      case 'processing':
        return 'Обрабатывается';
      case 'paid':
      case 'completed':
        return 'Оплачен';
      case 'failed':
        return 'Ошибка';
      case 'cancelled':
        return 'Отменен';
      case 'refunded':
        return 'Возврат';
      case 'disputed':
        return 'Спор';
      default:
        return 'Неизвестно';
    }
  }

  Widget _buildPaymentSummary(BuildContext context, BookingPayment payment) {
    final totalAmount = payment.amount;
    final isCompleted = payment.status == 'paid' || payment.status == 'completed';
    final completedAmount = isCompleted ? payment.amount : 0.0;
    final pendingAmount = isCompleted ? 0.0 : payment.amount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сводка по платежам',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Общая сумма', '${totalAmount.toStringAsFixed(0)} ₽'),
          _buildSummaryRow('Оплачено', '${completedAmount.toStringAsFixed(0)} ₽', Colors.green),
          if (pendingAmount > 0)
            _buildSummaryRow(
              'Ожидает оплаты',
              '${pendingAmount.toStringAsFixed(0)} ₽',
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, [Color? valueColor]) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.grey[800],
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

/// Компактный виджет статуса платежа для списков
class CompactPaymentStatusWidget extends StatelessWidget {
  const CompactPaymentStatusWidget({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) => PaymentStatusWidget(bookingId: bookingId, compact: true);
}

/// Виджет для отображения кнопки оплаты
class PaymentButtonWidget extends ConsumerWidget {
  const PaymentButtonWidget({super.key, required this.bookingId, this.onPaymentPressed});

  final String bookingId;
  final VoidCallback? onPaymentPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(bookingPaymentsProvider(bookingId));

    return paymentsAsync.when(
      data: (payments) {
        final pendingPayment = payments?.status == 'pending' ? payments : null;

        if (pendingPayment == null) {
          return const SizedBox.shrink();
        }

        return ElevatedButton.icon(
          onPressed: onPaymentPressed ?? () => _handlePayment(context, pendingPayment),
          icon: const Icon(Icons.payment, size: 18),
          label: Text('Оплатить ${pendingPayment.amount.toStringAsFixed(0)} ₽'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _handlePayment(BuildContext context, BookingPayment payment) {
    // В реальном приложении здесь будет переход к платежному провайдеру
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оплата'),
        content: Text('Переход к оплате ${payment.amount.toStringAsFixed(0)} ₽'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Здесь будет логика оплаты
            },
            child: const Text('Оплатить'),
          ),
        ],
      ),
    );
  }
}
