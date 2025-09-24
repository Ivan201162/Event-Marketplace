import 'package:flutter/material.dart';

import '../models/payment_models.dart';

/// Виджет сводки платежа
class PaymentSummaryWidget extends StatelessWidget {
  const PaymentSummaryWidget({
    super.key,
    required this.amount,
    required this.paymentType,
    required this.paymentScheme,
    this.description,
  });

  final double amount;
  final PaymentType paymentType;
  final PaymentScheme paymentScheme;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Сводка платежа',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Тип платежа
          _buildInfoRow(
            context,
            'Тип платежа',
            paymentType.typeDisplayName,
            Icons.payment,
          ),
          
          const SizedBox(height: 12),
          
          // Схема оплаты
          _buildInfoRow(
            context,
            'Схема оплаты',
            paymentScheme.schemeDisplayName,
            Icons.schedule,
          ),
          
          if (description != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Описание',
              description!,
              Icons.description,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Разделитель
          Container(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          
          const SizedBox(height: 16),
          
          // Сумма
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сумма к оплате',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${amount.toStringAsFixed(2)} ₽',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Дополнительная информация
          if (paymentScheme == PaymentScheme.partialPrepayment) ...[
            Text(
              'Аванс: ${(amount * 0.3).toStringAsFixed(2)} ₽ (30%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Остаток: ${(amount * 0.7).toStringAsFixed(2)} ₽ (70%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (paymentScheme == PaymentScheme.fullPrepayment) ...[
            Text(
              'Полная предоплата',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (paymentScheme == PaymentScheme.postPayment) ...[
            Text(
              'Постоплата (после выполнения работ)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}