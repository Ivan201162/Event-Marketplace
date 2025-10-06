import 'package:flutter/material.dart';

import '../models/payment.dart';

class PaymentSummary extends StatelessWidget {
  const PaymentSummary({
    super.key,
    required this.amount,
    required this.type,
    required this.taxAmount,
    required this.netAmount,
  });
  final double amount;
  final PaymentType type;
  final double taxAmount;
  final double netAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _getTypeIcon(),
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _getTypeDisplayName(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Amount breakdown
          _buildAmountRow(
            theme,
            'Сумма к оплате',
            '${amount.toStringAsFixed(0)} ₽',
            isTotal: true,
          ),

          if (taxAmount > 0) ...[
            const SizedBox(height: 12),
            _buildAmountRow(
              theme,
              'Налог (13%)',
              '${taxAmount.toStringAsFixed(0)} ₽',
            ),
          ],

          if (netAmount > 0) ...[
            const SizedBox(height: 12),
            _buildAmountRow(
              theme,
              'К получению',
              '${netAmount.toStringAsFixed(0)} ₽',
            ),
          ],

          const SizedBox(height: 16),

          // Payment info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getPaymentInfo(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    ThemeData theme,
    String label,
    String value, {
    bool isTotal = false,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 18 : null,
            ),
          ),
        ],
      );

  IconData _getTypeIcon() {
    switch (type) {
      case PaymentType.prepayment:
        return Icons.payment;
      case PaymentType.finalPayment:
        return Icons.account_balance_wallet;
      case PaymentType.fullPayment:
        return Icons.check_circle;
    }
  }

  String _getTypeDisplayName() {
    switch (type) {
      case PaymentType.prepayment:
        return 'Предоплата';
      case PaymentType.finalPayment:
        return 'Окончательный расчет';
      case PaymentType.fullPayment:
        return 'Полная оплата';
    }
  }

  String _getPaymentInfo() {
    switch (type) {
      case PaymentType.prepayment:
        return 'Предоплата составляет 30% от общей стоимости услуги';
      case PaymentType.finalPayment:
        return 'Окончательный расчет после завершения мероприятия';
      case PaymentType.fullPayment:
        return 'Полная оплата за услугу';
    }
  }
}
