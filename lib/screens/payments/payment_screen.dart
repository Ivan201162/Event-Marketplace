import 'package:event_marketplace_app/models/payment.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/providers/payment_providers.dart';
import 'package:event_marketplace_app/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Screen for processing payments
class PaymentScreen extends ConsumerStatefulWidget {

  const PaymentScreen({
    required this.specialistId, required this.serviceName, required this.amount, super.key,
    this.bookingId,
  });
  final String specialistId;
  final String serviceName;
  final int amount;
  final String? bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
        leading: _isProcessing
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),),
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
          }

          return _buildPaymentForm(user.id);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Детали услуги',
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.work, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.serviceName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Специалист ID: ${widget.specialistId}',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Amount
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сумма к оплате',
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Стоимость услуги:',
                          style: Theme.of(context).textTheme.bodyLarge,),
                      Text(
                        '${(widget.amount / 100).toStringAsFixed(2)} ₽',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Комиссия платформы (10%):',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      Text(
                        '${(widget.amount * 0.1 / 100).toStringAsFixed(2)} ₽',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Итого к оплате:',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(widget.amount / 100).toStringAsFixed(2)} ₽',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Payment Method
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Способ оплаты',
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...PaymentMethod.values.map(
                    (method) => RadioListTile<PaymentMethod>(
                      title: Text(method.displayName),
                      subtitle: _getPaymentMethodSubtitle(method),
                      value: method,
                      groupValue: _selectedMethod,
                      onChanged: _isProcessing
                          ? null
                          : (value) {
                              setState(() {
                                _selectedMethod = value;
                              });
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Error Message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red),),
                  ),
                ],
              ),
            ),
          if (_errorMessage != null) const SizedBox(height: 16),
          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),),
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Обработка платежа...'),
                      ],
                    )
                  : Text(
                      'Оплатить ${(widget.amount / 100).toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Security Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ваши платежные данные защищены и обрабатываются через Stripe',
                    style: TextStyle(color: Colors.green[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _getPaymentMethodSubtitle(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Банковская карта Visa, MasterCard, МИР';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.yooMoney:
        return 'ЮMoney (Яндекс.Деньги)';
      case PaymentMethod.sberbank:
        return 'Сбербанк Онлайн';
      case PaymentMethod.tinkoff:
        return 'Тинькофф Банк';
    }
    return null;
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) {
        throw Exception('Пользователь не найден');
      }

      // Create payment intent
      final paymentIntent = await paymentService.createPaymentIntent(
        amount: widget.amount,
        currency: 'RUB',
        description: 'Оплата услуги: ${widget.serviceName}',
        metadata: {
          'specialistId': widget.specialistId,
          'bookingId': widget.bookingId ?? '',
          'serviceName': widget.serviceName,
        },
      );

      if (paymentIntent == null) {
        throw Exception('Не удалось создать платеж');
      }

      // Process payment
      final payment = await paymentService.processPayment(
        userId: currentUser.id,
        paymentIntentId: paymentIntent.id,
        type: PaymentType.booking,
        method: _selectedMethod,
        amount: widget.amount,
        description: 'Оплата услуги: ${widget.serviceName}',
        specialistId: widget.specialistId,
        bookingId: widget.bookingId,
        metadata: {'serviceName': widget.serviceName},
      );

      if (payment != null && payment.isSuccessful) {
        // Payment successful
        if (mounted) {
          Navigator.pop(context, payment);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Платеж успешно обработан!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Платеж не был обработан');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
