import 'package:event_marketplace_app/services/payment_integration_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContractCard extends StatelessWidget {
  const ContractCard(
      {required this.contract, super.key, this.onTap, this.onStatusUpdate,});
  final Contract contract;
  final VoidCallback? onTap;
  final Function(ContractStatus)? onStatusUpdate;

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
                      color: _getStatusColor(contract.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Contract info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Контракт #${contract.id.substring(0, 8)}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Бронирование: ${contract.bookingId.substring(0, 8)}...',
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
                        '${contract.totalAmount.toStringAsFixed(0)} ₽',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Предоплата: ${contract.prepaymentAmount.toStringAsFixed(0)} ₽',
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
                      color: _getStatusColor(contract.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(contract.status)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusDisplayName(contract.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(contract.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Date
                  Text(
                    DateFormat('dd.MM.yyyy').format(contract.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Payment breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPaymentInfo(
                        theme,
                        'Предоплата',
                        '${contract.prepaymentAmount.toStringAsFixed(0)} ₽',
                        Icons.payment,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _buildPaymentInfo(
                        theme,
                        'Остаток',
                        '${contract.postpaymentAmount.toStringAsFixed(0)} ₽',
                        Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (contract.status == ContractStatus.draft) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            onStatusUpdate?.call(ContractStatus.active),
                        child: const Text('Активировать'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            onStatusUpdate?.call(ContractStatus.cancelled),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,),
                        child: const Text('Отменить'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(
          ThemeData theme, String label, String value, IconData icon,) =>
      Column(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),),
        ],
      );

  Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return Colors.grey;
      case ContractStatus.active:
        return Colors.green;
      case ContractStatus.completed:
        return Colors.blue;
      case ContractStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusDisplayName(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return 'Черновик';
      case ContractStatus.active:
        return 'Активный';
      case ContractStatus.completed:
        return 'Завершен';
      case ContractStatus.cancelled:
        return 'Отменен';
    }
  }
}
