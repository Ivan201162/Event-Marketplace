import 'package:flutter/material.dart';

import '../models/payment.dart';

class PaymentSummaryWidget extends StatelessWidget {
  const PaymentSummaryWidget({super.key, required this.payment, required this.taxStatus});
  final Payment payment;
  final TaxStatus taxStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Сводка платежа',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Payment details
            _buildDetailRow(context, 'Тип платежа', payment.typeDisplayName ?? 'Не указан'),
            const SizedBox(height: 12),

            _buildDetailRow(context, 'Способ оплаты', payment.methodDisplayName ?? 'Не указан'),
            const SizedBox(height: 12),

            _buildDetailRow(
              context,
              'Налоговый статус',
              payment.taxStatusDisplayName ?? 'Не указан',
            ),
            const SizedBox(height: 20),

            // Amount breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildAmountRow(context, 'Сумма к оплате', payment.amount, isTotal: true),
                  if ((payment.taxAmount ?? 0.0) > 0) ...[
                    const SizedBox(height: 8),
                    _buildAmountRow(
                      context,
                      'Налог (${((payment.taxAmount ?? 0.0) / payment.amount * 100).toStringAsFixed(1)}%)',
                      payment.taxAmount ?? 0.0,
                      isTax: true,
                    ),
                    const SizedBox(height: 8),
                    _buildAmountRow(context, 'К получению', payment.netAmount ?? 0.0, isNet: true),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tax information
            if ((payment.taxAmount ?? 0.0) > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getTaxInfoText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAmountRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    bool isTax = false,
    bool isNet = false,
  }) {
    final theme = Theme.of(context);

    Color? amountColor;
    if (isTotal) {
      amountColor = theme.colorScheme.primary;
    } else if (isTax) {
      amountColor = theme.colorScheme.error;
    } else if (isNet) {
      amountColor = theme.colorScheme.secondary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} ₽',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  String _getTaxInfoText() {
    switch (taxStatus) {
      case TaxStatus.none:
        return 'Налоги не применяются';
      case TaxStatus.individual:
        return 'НДФЛ 13% удерживается с суммы к получению';
      case TaxStatus.individualEntrepreneur:
        return 'Налог по УСН рассчитывается с суммы к получению';
      case TaxStatus.selfEmployed:
        return 'Налог для самозанятого рассчитывается с суммы к получению';
      case TaxStatus.legalEntity:
        return 'НДС и налог на прибыль рассчитываются с суммы к получению';
      case TaxStatus.professionalIncome:
        return 'НПД рассчитывается с суммы к получению';
      case TaxStatus.simplifiedTax:
        return 'УСН рассчитывается с суммы к получению';
      case TaxStatus.vat:
        return 'НДС рассчитывается с суммы к получению';
      case TaxStatus.notCalculated:
        return 'Налоги не рассчитаны';
      case TaxStatus.calculated:
        return 'Налоги рассчитаны';
      case TaxStatus.paid:
        return 'Налоги уплачены';
      case TaxStatus.exempt:
        return 'Освобождение от налогов';
    }
  }
}
