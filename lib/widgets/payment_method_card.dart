import 'package:flutter/material.dart';

import '../models/payment_models.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethodInfo methodInfo;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.methodInfo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: methodInfo.isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Method icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMethodIcon(methodInfo.method),
                  color: isSelected
                      ? theme.colorScheme.primary
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
                      methodInfo.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: methodInfo.isAvailable
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      methodInfo.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: methodInfo.isAvailable
                            ? theme.colorScheme.onSurface.withOpacity(0.7)
                            : theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                    if (methodInfo.fee != null && methodInfo.fee! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Комиссия: ${(methodInfo.fee! * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                )
              else if (!methodInfo.isAvailable)
                Icon(
                  Icons.block,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  size: 24,
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.sbp:
        return Icons.phone_android;
      case PaymentMethod.yookassa:
        return Icons.account_balance_wallet;
      case PaymentMethod.tinkoff:
        return Icons.credit_card;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }
}
