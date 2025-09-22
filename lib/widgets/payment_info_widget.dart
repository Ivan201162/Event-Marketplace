import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../services/payment_service.dart';

/// Виджет для отображения информации о платежах
class PaymentInfoWidget extends ConsumerWidget {
  final Booking booking;
  final double totalAmount;
  final String currency;
  final bool isGovernmentOrganization;

  const PaymentInfoWidget({
    super.key,
    required this.booking,
    required this.totalAmount,
    required this.currency,
    this.isGovernmentOrganization = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advancePercentage = isGovernmentOrganization ? 0.7 : 0.3;
    final advanceAmount = totalAmount * advancePercentage;
    final finalAmount = totalAmount - advanceAmount;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о платежах',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow(
              'Общая стоимость',
              '${totalAmount.toStringAsFixed(2)} $currency',
              Colors.black,
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Аванс (${(advancePercentage * 100).round()}%)',
              '${advanceAmount.toStringAsFixed(2)} $currency',
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Окончательная оплата',
              '${finalAmount.toStringAsFixed(2)} $currency',
              Colors.green,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildPaymentSchedule(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'График платежей',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildScheduleItem(
          '1',
          'Аванс',
          'При подтверждении бронирования',
          '${(totalAmount * (isGovernmentOrganization ? 0.7 : 0.3)).toStringAsFixed(2)} $currency',
          Colors.orange,
        ),
        const SizedBox(height: 8),
        _buildScheduleItem(
          '2',
          'Окончательная оплата',
          'После завершения мероприятия',
          '${(totalAmount * (isGovernmentOrganization ? 0.3 : 0.7)).toStringAsFixed(2)} $currency',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
    String step,
    String title,
    String description,
    String amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения статуса платежа
class PaymentStatusWidget extends ConsumerWidget {
  final String paymentId;
  final String status;
  final String? confirmationUrl;

  const PaymentStatusWidget({
    super.key,
    required this.paymentId,
    required this.status,
    this.confirmationUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        border: Border.all(color: _getStatusColor(status)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(status),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
                if (confirmationUrl != null)
                  Text(
                    'ID: $paymentId',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          if (confirmationUrl != null && status == PaymentService.PaymentStatus.pending)
            ElevatedButton(
              onPressed: () => _openPaymentUrl(context, confirmationUrl!),
              child: const Text('Оплатить'),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case PaymentService.paymentStatusPending:
        return Colors.orange;
      case PaymentService.paymentStatusProcessing:
        return Colors.blue;
      case PaymentService.paymentStatusSucceeded:
        return Colors.green;
      case PaymentService.paymentStatusFailed:
        return Colors.red;
      case PaymentService.paymentStatusCanceled:
        return Colors.grey;
      case PaymentService.paymentStatusRefunded:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case PaymentService.paymentStatusPending:
        return Icons.pending;
      case PaymentService.paymentStatusProcessing:
        return Icons.hourglass_empty;
      case PaymentService.paymentStatusSucceeded:
        return Icons.check_circle;
      case PaymentService.paymentStatusFailed:
        return Icons.error;
      case PaymentService.paymentStatusCanceled:
        return Icons.cancel;
      case PaymentService.paymentStatusRefunded:
        return Icons.refresh;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case PaymentService.paymentStatusPending:
        return 'Ожидает оплаты';
      case PaymentService.paymentStatusProcessing:
        return 'Обрабатывается';
      case PaymentService.paymentStatusSucceeded:
        return 'Оплачено';
      case PaymentService.paymentStatusFailed:
        return 'Ошибка оплаты';
      case PaymentService.paymentStatusCanceled:
        return 'Отменено';
      case PaymentService.paymentStatusRefunded:
        return 'Возвращено';
    }
  }

  void _openPaymentUrl(BuildContext context, String url) {
    // TODO: Реализовать открытие URL для оплаты
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открытие ссылки для оплаты: $url')),
    );
  }
}
