import 'package:flutter/material.dart';

import '../models/contract_models.dart';

/// Диалог деталей контракта
class ContractDetailsDialog extends StatelessWidget {
  const ContractDetailsDialog({
    super.key,
    required this.contract,
    this.onSign,
    this.onDownload,
  });

  final Contract contract;
  final VoidCallback? onSign;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Контракт #${contract.id.substring(0, 8)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
            ),
            
            // Содержимое
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Основная информация
                    _buildSection(
                      context,
                      'Основная информация',
                      [
                        _buildInfoRow(context, 'ID контракта', contract.id),
                        _buildInfoRow(context, 'ID бронирования', contract.bookingId),
                        _buildInfoRow(context, 'ID клиента', contract.customerId),
                        _buildInfoRow(context, 'ID специалиста', contract.specialistId),
                        _buildInfoRow(context, 'Статус', contract.statusDisplayName),
                        _buildInfoRow(context, 'Дата создания', _formatDate(contract.createdAt)),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Финансовая информация
                    if (contract.amount != null) ...[
                      _buildSection(
                        context,
                        'Финансовая информация',
                        [
                          _buildInfoRow(context, 'Общая сумма', '${contract.amount!.toStringAsFixed(2)} ₽'),
                          if (contract.prepaymentAmount != null && contract.prepaymentAmount! > 0)
                            _buildInfoRow(context, 'Аванс', '${contract.prepaymentAmount!.toStringAsFixed(2)} ₽'),
                          if (contract.finalAmount != null && contract.finalAmount! > 0)
                            _buildInfoRow(context, 'Финальная сумма', '${contract.finalAmount!.toStringAsFixed(2)} ₽'),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                    
                    // Подписи
                    _buildSection(
                      context,
                      'Подписи',
                      [
                        _buildInfoRow(
                          context,
                          'Подписан клиентом',
                          contract.isSignedByCustomer ? 'Да' : 'Нет',
                        ),
                        if (contract.signedByCustomer != null)
                          _buildInfoRow(context, 'Дата подписания клиентом', _formatDate(contract.signedByCustomer!)),
                        _buildInfoRow(
                          context,
                          'Подписан специалистом',
                          contract.isSignedBySpecialist ? 'Да' : 'Нет',
                        ),
                        if (contract.signedBySpecialist != null)
                          _buildInfoRow(context, 'Дата подписания специалистом', _formatDate(contract.signedBySpecialist!)),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Документы
                    _buildSection(
                      context,
                      'Документы',
                      [
                        _buildInfoRow(
                          context,
                          'Договор',
                          contract.contractUrl != null ? 'Доступен' : 'Не создан',
                        ),
                        _buildInfoRow(
                          context,
                          'Акт выполненных работ',
                          contract.actUrl != null ? 'Доступен' : 'Не создан',
                        ),
                        _buildInfoRow(
                          context,
                          'Счёт',
                          contract.invoiceUrl != null ? 'Доступен' : 'Не создан',
                        ),
                        _buildInfoRow(
                          context,
                          'Квитанция',
                          contract.receiptUrl != null ? 'Доступна' : 'Не создана',
                        ),
                      ],
                    ),
                    
                    if (contract.terms != null) ...[
                      const SizedBox(height: 20),
                      
                      // Условия договора
                      _buildSection(
                        context,
                        'Условия договора',
                        [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              contract.terms!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    if (contract.completedAt != null) ...[
                      const SizedBox(height: 20),
                      _buildInfoRow(context, 'Дата завершения', _formatDate(contract.completedAt!)),
                    ],
                    
                    if (contract.cancelledAt != null) ...[
                      const SizedBox(height: 20),
                      _buildInfoRow(context, 'Дата отмены', _formatDate(contract.cancelledAt!)),
                    ],
                  ],
                ),
              ),
            ),
            
            // Действия
            if (onSign != null || onDownload != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
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
                      const SizedBox(width: 12),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Закрыть'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Закрыть'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
