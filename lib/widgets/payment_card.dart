import 'package:flutter/material.dart';

import '../models/payment.dart';

/// Widget for displaying a payment card
class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status).withValues(alpha:(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPaymentTypeIcon(payment.type),
                      color: _getStatusColor(payment.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.description,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payment.type.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        payment.formattedAmount,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _getStatusColor(payment.status),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(payment.status).withValues(alpha:(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          payment.status.displayName,
                          style: TextStyle(
                            color: _getStatusColor(payment.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Details
              Row(
                children: [
                  Icon(
                    Icons.payment,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    payment.method.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(payment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              // Commission info
              if (payment.commission > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha:(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.percent,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Комиссия: ${payment.formattedCommission}',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'К получению: ${payment.formattedNetAmount}',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Duration for completed payments
              if (payment.isSuccessful && payment.duration != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Обработано за ${payment.formattedDuration}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
              // Failure reason
              if (payment.isFailed && payment.failureReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha:(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          payment.failureReason!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
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
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Сегодня в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
}
