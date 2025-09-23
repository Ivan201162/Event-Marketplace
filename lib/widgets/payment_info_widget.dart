import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/payment_service.dart';

/// Виджет для отображения информации о платеже на экране бронирования
class PaymentInfoWidget extends ConsumerWidget {
  final String bookingId;
  final double totalAmount;
  final double advanceAmount;
  final String currency;
  final String paymentStatus; // Статус платежа
  final String? paymentConfirmationUrl; // URL для подтверждения платежа

  const PaymentInfoWidget({
    super.key,
    required this.bookingId,
    required this.totalAmount,
    required this.advanceAmount,
    required this.currency,
    required this.paymentStatus,
    this.paymentConfirmationUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingAmount = totalAmount - advanceAmount;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о платеже',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Общая сумма:'),
                Text('$totalAmount $currency'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Аванс:'),
                Text('$advanceAmount $currency'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Остаток к оплате:'),
                Text('$remainingAmount $currency'),
              ],
            ),
            const SizedBox(height: 16),
            PaymentStatusWidget(
              paymentId: bookingId, // Используем bookingId как paymentId для примера
              status: paymentStatus,
              confirmationUrl: paymentConfirmationUrl,
            ),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
            ),
            const SizedBox(width: 8),
            Text(
              _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (confirmationUrl != null && status == PaymentService.paymentStatusPending)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton(
              onPressed: () => _openPaymentUrl(context, confirmationUrl!),
              child: const Text('Перейти к оплате'),
            ),
          ),
      ],
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
      default:
        return Colors.black;
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
      default:
        return Icons.info_outline;
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
      default:
        return 'Неизвестный статус';
    }
  }

  void _openPaymentUrl(BuildContext context, String url) {
    // TODO: Реализовать открытие URL для оплаты
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открытие URL для оплаты: $url')),
    );
    // launchUrl(Uri.parse(url)); // Для реального открытия URL
  }
}