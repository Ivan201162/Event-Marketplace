import 'package:flutter/material.dart';

import '../models/contract_models.dart';

/// Карточка контракта
class ContractCard extends StatelessWidget {
  const ContractCard({
    super.key,
    required this.contract,
    required this.onTap,
    this.onSign,
    this.onDownload,
  });

  final Contract contract;
  final VoidCallback onTap;
  final VoidCallback? onSign;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и статус
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Контракт #${contract.id.substring(0, 8)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Информация о контракте
              _buildInfoRow(
                context,
                'Бронирование',
                contract.bookingId.substring(0, 8),
                Icons.event,
              ),
              
              const SizedBox(height: 8),
              
              _buildInfoRow(
                context,
                'Сумма',
                '${contract.amount?.toStringAsFixed(2) ?? '0.00'} ₽',
                Icons.attach_money,
              ),
              
              if (contract.prepaymentAmount != null && contract.prepaymentAmount! > 0) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  'Аванс',
                  '${contract.prepaymentAmount!.toStringAsFixed(2)} ₽',
                  Icons.payment,
                ),
              ],
              
              const SizedBox(height: 8),
              
              _buildInfoRow(
                context,
                'Создан',
                _formatDate(contract.createdAt),
                Icons.calendar_today,
              ),
              
              // Подписи
              if (contract.isSignedByCustomer || contract.isSignedBySpecialist) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Подписи:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (contract.isSignedByCustomer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Клиент',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (contract.isSignedByCustomer && contract.isSignedBySpecialist)
                      const SizedBox(width: 4),
                    if (contract.isSignedBySpecialist)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Специалист',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              
              // Действия
              if (onSign != null || onDownload != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (onSign != null && !contract.isSignedByCustomer) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSign,
                          icon: const Icon(Icons.edit),
                          label: const Text('Подписать'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (onDownload != null && contract.contractUrl != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download),
                          label: const Text('Скачать'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    
    switch (contract.status) {
      case ContractStatus.draft:
        backgroundColor = theme.colorScheme.surfaceVariant;
        textColor = theme.colorScheme.onSurfaceVariant;
        break;
      case ContractStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange.shade700;
        break;
      case ContractStatus.signed:
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.2);
        textColor = theme.colorScheme.primary;
        break;
      case ContractStatus.completed:
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green.shade700;
        break;
      case ContractStatus.cancelled:
        backgroundColor = theme.colorScheme.error.withValues(alpha: 0.2);
        textColor = theme.colorScheme.error;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        contract.statusDisplayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
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
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
