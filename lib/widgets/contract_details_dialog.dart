import 'package:event_marketplace_app/models/payment_models.dart';
import 'package:event_marketplace_app/services/payment_integration_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContractDetailsDialog extends StatefulWidget {
  const ContractDetailsDialog(
      {required this.contract, super.key, this.onStatusUpdate,});
  final Contract contract;
  final Function(ContractStatus)? onStatusUpdate;

  @override
  State<ContractDetailsDialog> createState() => _ContractDetailsDialogState();
}

class _ContractDetailsDialogState extends State<ContractDetailsDialog> {
  final PaymentIntegrationService _paymentIntegrationService =
      PaymentIntegrationService();
  List<Payment> _payments = [];
  bool _isLoadingPayments = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final payments = await _paymentIntegrationService.getBookingPayments(
        widget.contract.bookingId,
      );
      setState(() {
        _payments = payments;
        _isLoadingPayments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPayments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Контракт #${widget.contract.id.substring(0, 8)}',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),),
              ],
            ),

            const SizedBox(height: 16),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.contract.status)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(widget.contract.status)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _getStatusDisplayName(widget.contract.status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getStatusColor(widget.contract.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contract details
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(theme, 'Основная информация', [
                      _buildDetailRow(
                          theme, 'ID контракта', widget.contract.id,),
                      _buildDetailRow(
                          theme, 'ID бронирования', widget.contract.bookingId,),
                      _buildDetailRow(
                          theme, 'ID заказчика', widget.contract.customerId,),
                      _buildDetailRow(theme, 'ID специалиста',
                          widget.contract.specialistId,),
                      _buildDetailRow(
                        theme,
                        'Дата создания',
                        DateFormat('dd.MM.yyyy HH:mm')
                            .format(widget.contract.createdAt),
                      ),
                      _buildDetailRow(
                        theme,
                        'Дата обновления',
                        DateFormat('dd.MM.yyyy HH:mm')
                            .format(widget.contract.updatedAt),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection(theme, 'Финансовая информация', [
                      _buildDetailRow(
                        theme,
                        'Общая сумма',
                        '${widget.contract.totalAmount.toStringAsFixed(0)} ₽',
                      ),
                      _buildDetailRow(
                        theme,
                        'Предоплата',
                        '${widget.contract.prepaymentAmount.toStringAsFixed(0)} ₽',
                      ),
                      _buildDetailRow(
                        theme,
                        'Остаток к доплате',
                        '${widget.contract.postpaymentAmount.toStringAsFixed(0)} ₽',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection(
                        theme, 'Платежи', _buildPaymentsList(theme),),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (widget.contract.status == ContractStatus.draft) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onStatusUpdate?.call(ContractStatus.active);
                        Navigator.pop(context);
                      },
                      child: const Text('Активировать контракт'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onStatusUpdate?.call(ContractStatus.cancelled);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,),
                      child: const Text('Отменить контракт'),
                    ),
                  ),
                ],
              ),
            ] else if (widget.contract.status == ContractStatus.active) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    widget.onStatusUpdate?.call(ContractStatus.completed);
                    Navigator.pop(context);
                  },
                  child: const Text('Завершить контракт'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
          ThemeData theme, String title, List<Widget> children,) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
        ],
      );

  Widget _buildDetailRow(ThemeData theme, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  List<Widget> _buildPaymentsList(ThemeData theme) {
    if (_isLoadingPayments) {
      return [
        const Center(
          child: Padding(
              padding: EdgeInsets.all(16), child: CircularProgressIndicator(),),
        ),
      ];
    }

    if (_payments.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Платежи не найдены',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ];
    }

    return _payments
        .map((payment) => _buildPaymentItem(theme, payment))
        .toList();
  }

  Widget _buildPaymentItem(ThemeData theme, Payment payment) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getPaymentStatusColor(payment.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPaymentTypeDisplayName(payment.type),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${payment.amount.toStringAsFixed(0)} ₽ • ${_getPaymentMethodDisplayName(payment.method)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _getPaymentStatusDisplayName(payment.status),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getPaymentStatusColor(payment.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return Colors.grey;
      case ContractStatus.active:
        return Colors.green;
      case ContractStatus.completed:
        return Colors.blue;
      case ContractStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusDisplayName(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return 'Черновик';
      case ContractStatus.active:
        return 'Активный';
      case ContractStatus.completed:
        return 'Завершен';
      case ContractStatus.cancelled:
        return 'Отменен';
    }
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
      case PaymentStatus.disputed:
        return Colors.amber;
    }
  }

  String _getPaymentStatusDisplayName(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.processing:
        return 'Обрабатывается';
      case PaymentStatus.completed:
        return 'Завершена';
      case PaymentStatus.failed:
        return 'Неудачная';
      case PaymentStatus.cancelled:
        return 'Отменена';
      case PaymentStatus.refunded:
        return 'Возвращена';
      case PaymentStatus.disputed:
        return 'Спор';
    }
  }

  String _getPaymentTypeDisplayName(PaymentType type) {
    switch (type) {
      case PaymentType.prepayment:
        return 'Предоплата';
      case PaymentType.postpayment:
        return 'Окончательный расчет';
      case PaymentType.fullPayment:
        return 'Полная оплата';
    }
  }

  String _getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.sbp:
        return 'СБП';
      case PaymentMethod.yookassa:
        return 'ЮKassa';
      case PaymentMethod.tinkoff:
        return 'Tinkoff';
      case PaymentMethod.card:
        return 'Карта';
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.bankTransfer:
        return 'Перевод';
    }
  }
}
