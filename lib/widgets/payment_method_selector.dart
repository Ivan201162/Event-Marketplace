import 'package:flutter/material.dart';

import '../models/payment.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod) onMethodSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: PaymentMethod.values
          .map(
            (method) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onMethodSelected(method),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedMethod == method
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: selectedMethod == method ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: selectedMethod == method
                        ? theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3)
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Method icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selectedMethod == method
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getMethodIcon(method),
                          color: selectedMethod == method
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Method info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getMethodDisplayName(method),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: selectedMethod == method
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getMethodDescription(method),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selection indicator
                      if (selectedMethod == method)
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 24,
                        )
                      else
                        Icon(
                          Icons.radio_button_unchecked,
                          color: theme.colorScheme.outline,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.sbp:
        return Icons.qr_code;
      case PaymentMethod.yookassa:
        return Icons.payment;
      case PaymentMethod.tinkoff:
        return Icons.account_balance;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_wallet;
    }
  }

  String _getMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.sbp:
        return 'СБП (Система быстрых платежей)';
      case PaymentMethod.yookassa:
        return 'ЮKassa';
      case PaymentMethod.tinkoff:
        return 'Tinkoff Pay';
      case PaymentMethod.card:
        return 'Банковская карта';
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
    }
  }

  String _getMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.sbp:
        return 'Мгновенная оплата через приложение банка';
      case PaymentMethod.yookassa:
        return 'Безопасная оплата через ЮKassa';
      case PaymentMethod.tinkoff:
        return 'Оплата через приложение Tinkoff';
      case PaymentMethod.card:
        return 'Оплата банковской картой';
      case PaymentMethod.cash:
        return 'Оплата наличными при встрече';
      case PaymentMethod.bankTransfer:
        return 'Перевод на банковский счет';
    }
  }
}
