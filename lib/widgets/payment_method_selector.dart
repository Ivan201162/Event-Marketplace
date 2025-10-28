import 'package:event_marketplace_app/models/payment.dart';
import 'package:flutter/material.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.selectedMethod, required this.onMethodSelected, super.key,
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
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.primary, size: 24,)
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
      case PaymentMethod.digitalWallet:
        return Icons.qr_code;
      case PaymentMethod.cryptocurrency:
        return Icons.currency_bitcoin;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_wallet;
      case PaymentMethod.sbp:
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  String _getMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.digitalWallet:
        return 'Электронный кошелек';
      case PaymentMethod.cryptocurrency:
        return 'Криптовалюта';
      case PaymentMethod.card:
        return 'Банковская карта';
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
      case PaymentMethod.sbp:
        return 'СБП';
      default:
        return 'Способ оплаты';
    }
  }

  String _getMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.digitalWallet:
        return 'Оплата через электронный кошелек';
      case PaymentMethod.cryptocurrency:
        return 'Оплата криптовалютой';
      case PaymentMethod.card:
        return 'Оплата банковской картой';
      case PaymentMethod.cash:
        return 'Оплата наличными при встрече';
      case PaymentMethod.bankTransfer:
        return 'Перевод на банковский счет';
      case PaymentMethod.sbp:
        return 'Оплата через СБП';
      default:
        return 'Способ оплаты';
    }
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method.type) {
      case PaymentMethodType.card:
        return Icons.credit_card;
      case PaymentMethodType.bankTransfer:
        return Icons.account_balance;
      case PaymentMethodType.digitalWallet:
        return Icons.account_balance_wallet;
      case PaymentMethodType.cash:
        return Icons.money;
      case PaymentMethodType.other:
        return Icons.payment;
    }
  }
}
