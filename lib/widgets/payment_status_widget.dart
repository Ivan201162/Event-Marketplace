import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';

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
      data: (payments) {
        if (payments.isEmpty) {
          return _buildNoPayments(context);
        }

        final prepayment = payments.where((p) => p.type == PaymentType.prepayment).firstOrNull;
        final finalPayment = payments.where((p) => p.type == PaymentType.finalPayment).firstOrNull;

        if (compact) {
          return _buildCompactStatus(context, prepayment, finalPayment);
        } else {
          return _buildDetailedStatus(
            context,
            payments,
            prepayment,
            finalPayment,
          );
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildCompactStatus(
    BuildContext context,
    Payment? prepayment,
    Payment? finalPayment,
  ) {
    if (prepayment != null) {
      return _buildPaymentStatusChip(
        context,
        prepayment.status,
        prepayment.type,
        prepayment.amount,
      );
    } else if (finalPayment != null) {
      return _buildPaymentStatusChip(
        context,
        finalPayment.status,
        finalPayment.type,
        finalPayment.amount,
      );
    }

    return _buildNoPayments(context);
  }

  Widget _buildDetailedStatus(
    BuildContext context,
    List<Payment> payments,
    Payment? prepayment,
    Payment? finalPayment,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Предоплата
          if (prepayment != null) ...[
            _buildPaymentCard(context, prepayment),
            const SizedBox(height: 8),
          ],

          // Финальный платеж
          if (finalPayment != null) ...[
            _buildPaymentCard(context, finalPayment),
            const SizedBox(height: 8),
          ],

          // Общая информация
          if (showDetails) ...[
            _buildPaymentSummary(context, payments),
          ],
        ],
      );

  Widget _buildPaymentStatusChip(
    BuildContext context,
    PaymentStatus status,
    PaymentType type,
    double amount,
  ) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case PaymentStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        icon = Icons.schedule;
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
      case PaymentStatus.disputed:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        icon = Icons.gavel;
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
            '${type.icon} ${amount.toStringAsFixed(0)} ₽',
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок платежа
              Row(
                children: [
                  Icon(
                    payment.type.icon,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.type.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${payment.amount.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
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
                  payment.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Даты
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Создан: ${_formatDate(payment.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                  if (payment.paidAt != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Оплачен: ${_formatDate(payment.paidAt!)}',
                      style: TextStyle(
                        color: Colors.green[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatusChip(BuildContext context, PaymentStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case PaymentStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        break;
      case PaymentStatus.processing:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue[700]!;
        break;
      case PaymentStatus.completed:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        break;
      case PaymentStatus.failed:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        break;
      case PaymentStatus.cancelled:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        break;
      case PaymentStatus.refunded:
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple[700]!;
        break;
      case PaymentStatus.disputed:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
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
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, List<Payment> payments) {
    final totalAmount = payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final completedAmount = payments
        .where((p) => p.isCompleted)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final pendingAmount =
        payments.where((p) => p.isPending).fold<double>(0, (sum, payment) => sum + payment.amount);

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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Общая сумма',
            '${totalAmount.toStringAsFixed(0)} ₽',
          ),
          _buildSummaryRow(
            'Оплачено',
            '${completedAmount.toStringAsFixed(0)} ₽',
            Colors.green,
          ),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
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
  const CompactPaymentStatusWidget({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  Widget build(BuildContext context) => PaymentStatusWidget(
        bookingId: bookingId,
        compact: true,
      );
}

/// Виджет для отображения кнопки оплаты
class PaymentButtonWidget extends ConsumerWidget {
  const PaymentButtonWidget({
    super.key,
    required this.bookingId,
    this.onPaymentPressed,
  });

  final String bookingId;
  final VoidCallback? onPaymentPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(bookingPaymentsProvider(bookingId));

    return paymentsAsync.when(
      data: (payments) {
        final pendingPayment = payments.where((p) => p.status == PaymentStatus.pending).firstOrNull;

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

  void _handlePayment(BuildContext context, Payment payment) {
    // В реальном приложении здесь будет переход к платежному провайдеру
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оплата'),
        content: Text('Переход к оплате ${payment.amount.toStringAsFixed(0)} ₽'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
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
