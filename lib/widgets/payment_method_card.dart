import 'package:flutter/material.dart';

import '../models/payment_models.dart';

/// Карточка способа оплаты
class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.amount,
    required this.fee,
    required this.totalAmount,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final double amount;
  final double fee;
  final double totalAmount;
  final bool isSelected;
  final VoidCallback onTap;

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
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Иконка способа оплаты
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMethodIcon(),
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Информация о способе оплаты
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.methodDisplayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMethodDescription(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (fee > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Комиссия: ${fee.toStringAsFixed(2)} ₽',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Сумма и индикатор выбора
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${totalAmount.toStringAsFixed(2)} ₽',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 12,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMethodIcon() {
    switch (method) {
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.sbp:
        return Icons.phone_android;
      case PaymentMethod.yookassa:
        return Icons.payment;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }

  String _getMethodDescription() {
    switch (method) {
      case PaymentMethod.card:
        return 'Банковские карты Visa, MasterCard, МИР';
      case PaymentMethod.sbp:
        return 'Система быстрых платежей';
      case PaymentMethod.yookassa:
        return 'ЮKassa - все способы оплаты';
      case PaymentMethod.bankTransfer:
        return 'Банковский перевод';
    }
  }
}
