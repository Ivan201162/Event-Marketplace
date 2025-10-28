import 'package:event_marketplace_app/models/payment.dart';
import 'package:flutter/material.dart';

class PaymentMethodWidget extends StatelessWidget {
  const PaymentMethodWidget({
    required this.selectedMethod, required this.onMethodChanged, super.key,
  });
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onMethodChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Способ оплаты',
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...PaymentMethod.values.map(
                (method) => _buildPaymentMethodTile(context, method, selectedMethod == method),
              ),
            ],
          ),
        ),
      );

  Widget _buildPaymentMethodTile(BuildContext context, PaymentMethod method, bool isSelected) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: ListTile(
          leading: Icon(
            _getMethodIcon(method),
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
          ),
          title: Text(
            method.displayName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
              : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
          onTap: () => onMethodChanged(method),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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
