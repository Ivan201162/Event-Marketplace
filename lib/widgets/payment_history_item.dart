import 'package:event_marketplace_app/models/payment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentHistoryItem extends StatelessWidget {
  const PaymentHistoryItem({required this.payment, super.key, this.onTap});
  final Payment payment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Payment info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.typeDisplayName ?? 'Платеж',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payment.methodDisplayName ?? 'Не указан',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${payment.amount.toStringAsFixed(0)} ₽',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getAmountColor(payment.status, theme),
                        ),
                      ),
                      if ((payment.taxAmount ?? 0.0) > 0)
                        Text(
                          'налог: ${(payment.taxAmount ?? 0.0).toStringAsFixed(0)} ₽',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status and date row
              Row(
                children: [
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(payment.status)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusDisplayName(payment.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(payment.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Date
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(payment.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),

              // Failure reason if failed
              if (payment.status == PaymentStatus.failed &&
                  payment.failureReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 16, color: theme.colorScheme.error,),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payment.failureReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
      case PaymentStatus.disputed:
        return Colors.amber;
    }
  }

  Color _getAmountColor(PaymentStatus status, ThemeData theme) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green.shade700;
      case PaymentStatus.failed:
        return theme.colorScheme.error;
      case PaymentStatus.refunded:
        return Colors.purple.shade700;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  String _getStatusDisplayName(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.processing:
        return 'Обрабатывается';
      case PaymentStatus.completed:
        return 'Завершена';
      case PaymentStatus.failed:
        return 'Неудачная';
      case PaymentStatus.cancelled:
        return 'Отменена';
      case PaymentStatus.refunded:
        return 'Возвращена';
      case PaymentStatus.disputed:
        return 'Спор';
    }
  }
}
