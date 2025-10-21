import 'package:flutter/material.dart';
import '../models/payment_extended.dart';

/// Виджет карточки платежа
class PaymentCardWidget extends StatelessWidget {
  const PaymentCardWidget({
    super.key,
    required this.payment,
    this.onTap,
    this.onPay,
    this.onDownloadReceipt,
    this.onDownloadInvoice,
  });
  final PaymentExtended payment;
  final VoidCallback? onTap;
  final VoidCallback? onPay;
  final VoidCallback? onDownloadReceipt;
  final VoidCallback? onDownloadInvoice;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с статусом
                Row(
                  children: [
                    _buildStatusIcon(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getPaymentTypeText(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),

                const SizedBox(height: 12),

                // Суммы
                _buildAmountsSection(),

                const SizedBox(height: 12),

                // Прогресс оплаты
                _buildProgressSection(),

                const SizedBox(height: 12),

                // Взносы
                if (payment.installments.isNotEmpty) ...[
                  _buildInstallmentsSection(),
                  const SizedBox(height: 12),
                ],

                // Действия
                _buildActionsSection(context),

                const SizedBox(height: 8),

                // Информация о дате
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Создан: ${_formatDate(payment.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    if (payment.updatedAt != payment.createdAt)
                      Text(
                        'Обновлен: ${_formatDate(payment.updatedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (payment.status) {
      case PaymentStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case PaymentStatus.processing:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case PaymentStatus.pending:
        icon = Icons.pending;
        color = Colors.blue;
        break;
      case PaymentStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case PaymentStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      case PaymentStatus.refunded:
        icon = Icons.refresh;
        color = Colors.purple;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;

    switch (payment.status) {
      case PaymentStatus.completed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case PaymentStatus.processing:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case PaymentStatus.pending:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case PaymentStatus.failed:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case PaymentStatus.cancelled:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        break;
      case PaymentStatus.refunded:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        _getStatusText(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  Widget _buildAmountsSection() => Row(
        children: [
          Expanded(
            child: _buildAmountItem(
              'Общая сумма',
              '${payment.totalAmount.toStringAsFixed(2)} ₽',
              Colors.black87,
            ),
          ),
          Expanded(
            child: _buildAmountItem(
              'Оплачено',
              '${payment.paidAmount.toStringAsFixed(2)} ₽',
              Colors.green[700]!,
            ),
          ),
          Expanded(
            child: _buildAmountItem(
              'Остаток',
              '${payment.remainingAmount.toStringAsFixed(2)} ₽',
              Colors.orange[700]!,
            ),
          ),
        ],
      );

  Widget _buildAmountItem(String label, String value, Color color) => Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      );

  Widget _buildProgressSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Прогресс оплаты', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(
                '${payment.paymentProgress.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: payment.paymentProgress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              payment.paymentProgress >= 100 ? Colors.green : Colors.blue,
            ),
          ),
        ],
      );

  Widget _buildInstallmentsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Взносы (${payment.installments.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...payment.installments.take(3).map(_buildInstallmentItem),
          if (payment.installments.length > 3) ...[
            const SizedBox(height: 4),
            Text(
              '... и ещё ${payment.installments.length - 3}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      );

  Widget _buildInstallmentItem(PaymentInstallment installment) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              _getInstallmentStatusIcon(installment.status),
              size: 16,
              color: _getInstallmentStatusColor(installment.status),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_formatDate(installment.dueDate), style: const TextStyle(fontSize: 12)),
            ),
            Text(
              '${installment.amount.toStringAsFixed(2)} ₽',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildActionsSection(BuildContext context) => Row(
        children: [
          if (payment.remainingAmount > 0 && onPay != null) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Оплатить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (payment.receiptPdfUrl != null && onDownloadReceipt != null) ...[
            IconButton(
              onPressed: onDownloadReceipt,
              icon: const Icon(Icons.receipt),
              tooltip: 'Скачать квитанцию',
            ),
          ],
          if (payment.invoicePdfUrl != null && onDownloadInvoice != null) ...[
            IconButton(
              onPressed: onDownloadInvoice,
              icon: const Icon(Icons.description),
              tooltip: 'Скачать счёт',
            ),
          ],
        ],
      );

  IconData _getInstallmentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.failed:
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getInstallmentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.blue;
      case PaymentStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentTypeText() {
    switch (payment.type) {
      case PaymentType.full:
        return 'Полная оплата';
      case PaymentType.advance:
        return 'Предоплата';
      case PaymentType.installment:
        return 'Рассрочка';
      case PaymentType.partial:
        return 'Частичная оплата';
    }
  }

  String _getStatusText() {
    switch (payment.status) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.processing:
        return 'Обработка';
      case PaymentStatus.completed:
        return 'Оплачено';
      case PaymentStatus.failed:
        return 'Ошибка';
      case PaymentStatus.cancelled:
        return 'Отменено';
      case PaymentStatus.refunded:
        return 'Возвращено';
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
