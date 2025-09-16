import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../payments/payment_gateway.dart';
import '../providers/payment_providers.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';

/// Экран оплаты
class PaymentScreen extends ConsumerStatefulWidget {
  final Booking booking;

  const PaymentScreen({
    super.key,
    required this.booking,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _isProcessing = false;
  List<PaymentInfo> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      final history = await ref.read(paymentHistoryProvider(widget.booking.id).future);
      setState(() {
        _paymentHistory = history;
      });
    } catch (e, stackTrace) {
      SafeLog.error('PaymentScreen: Error loading payment history', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!FeatureFlags.paymentsEnabled) {
      return _buildPaymentsDisabledState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBookingInfo(),
          const SizedBox(height: 24),
          _buildPaymentMethods(),
          const SizedBox(height: 24),
          _buildPaymentButtons(),
          const SizedBox(height: 24),
          _buildPaymentHistory(),
        ],
      ),
    );
  }

  Widget _buildPaymentsDisabledState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 32),
          Text(
            'Платежи временно недоступны',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Функция платежей отключена в настройках приложения. В демо-режиме вы можете просматривать информацию о платежах.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Назад'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Информация о бронировании',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Событие', widget.booking.eventTitle),
            _buildInfoRow('Дата', '${widget.booking.eventDate.day}.${widget.booking.eventDate.month}.${widget.booking.eventDate.year}'),
            _buildInfoRow('Участников', '${widget.booking.participantsCount}'),
            _buildInfoRow('Общая сумма', '${widget.booking.totalPrice} ₽'),
            _buildInfoRow('Статус', widget.booking.statusText),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final availableMethods = ref.watch(availablePaymentMethodsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Способ оплаты',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...availableMethods.map((method) => _buildPaymentMethodTile(method)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedMethod == method;
    final methodInfo = _getPaymentMethodInfo(method);

    return ListTile(
      leading: Icon(
        methodInfo.icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(methodInfo.name),
      subtitle: Text(methodInfo.description),
      trailing: Radio<PaymentMethod>(
        value: method,
        groupValue: _selectedMethod,
        onChanged: (value) {
          setState(() {
            _selectedMethod = value!;
          });
        },
      ),
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
    );
  }

  Widget _buildPaymentButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _processPayment(PaymentType.prepayment),
          icon: _isProcessing ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ) : const Icon(Icons.payment),
          label: Text(_isProcessing ? 'Обработка...' : 'Оплатить аванс (30%)'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _processPayment(PaymentType.finalPayment),
          icon: const Icon(Icons.account_balance_wallet),
          label: const Text('Оплатить остаток (70%)'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : () => _processPayment(PaymentType.fullPayment),
          icon: const Icon(Icons.payment),
          label: const Text('Оплатить полностью'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    if (_paymentHistory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'История платежей пуста',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'История платежей',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._paymentHistory.map((payment) => _buildPaymentHistoryItem(payment)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryItem(PaymentInfo payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getPaymentStatusIcon(payment.status),
            color: _getPaymentStatusColor(payment.status),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPaymentTypeName(payment.type),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${payment.amount} ${payment.currency}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getPaymentStatusName(payment.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getPaymentStatusColor(payment.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${payment.createdAt.day}.${payment.createdAt.month}.${payment.createdAt.year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(PaymentType type) async {
    if (!FeatureFlags.paymentsEnabled) {
      _showPaymentDisabledDialog(type);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentGateway = ref.read(paymentGatewayProvider);
      final amount = _calculatePaymentAmount(type);
      final fee = await paymentGateway.getPaymentFee(
        amount: amount,
        method: _selectedMethod,
      );

      _showPaymentConfirmationDialog(type, amount, fee);
    } catch (e, stackTrace) {
      SafeLog.error('PaymentScreen: Error processing payment', e, stackTrace);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обработки платежа: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPaymentDisabledDialog(PaymentType type) {
    final amount = _calculatePaymentAmount(type);
    final typeName = _getPaymentTypeName(type);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Демо-режим'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('В демо-режиме платежи отключены.'),
            const SizedBox(height: 12),
            Text(
              'Информация о платеже:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Тип', typeName),
            _buildInfoRow('Сумма', '$amount ₽'),
            _buildInfoRow('Способ', _getPaymentMethodInfo(_selectedMethod).name),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'В реальном приложении здесь будет происходить обработка платежа через выбранный способ оплаты.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmationDialog(PaymentType type, double amount, double fee) {
    final typeName = _getPaymentTypeName(type);
    final totalAmount = amount + fee;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение платежа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вы собираетесь произвести $typeName:'),
            const SizedBox(height: 12),
            _buildInfoRow('Сумма', '$amount ₽'),
            _buildInfoRow('Комиссия', '$fee ₽'),
            _buildInfoRow('Итого', '$totalAmount ₽'),
            _buildInfoRow('Способ', _getPaymentMethodInfo(_selectedMethod).name),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Это демо-режим. Реальные деньги не будут списаны.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executePayment(type, amount);
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  Future<void> _executePayment(PaymentType type, double amount) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentGateway = ref.read(paymentGatewayProvider);
      
      final result = await paymentGateway.createPayment(
        bookingId: widget.booking.id,
        amount: amount,
        currency: 'RUB',
        type: type,
        method: _selectedMethod,
        description: '${_getPaymentTypeName(type)} для ${widget.booking.eventTitle}',
      );

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Платеж успешно обработан! ID: ${result.paymentId}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Обновляем историю платежей
        await _loadPaymentHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка платежа: ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      SafeLog.error('PaymentScreen: Error executing payment', e, stackTrace);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка выполнения платежа: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  double _calculatePaymentAmount(PaymentType type) {
    switch (type) {
      case PaymentType.prepayment:
        return widget.booking.totalPrice * 0.3;
      case PaymentType.finalPayment:
        return widget.booking.totalPrice * 0.7;
      case PaymentType.fullPayment:
        return widget.booking.totalPrice;
      case PaymentType.refund:
        return 0.0;
    }
  }

  PaymentMethodInfo _getPaymentMethodInfo(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return PaymentMethodInfo(
          name: 'Банковская карта',
          description: 'Visa, MasterCard, МИР',
          icon: Icons.credit_card,
        );
      case PaymentMethod.applePay:
        return PaymentMethodInfo(
          name: 'Apple Pay',
          description: 'Быстрая оплата через Apple Pay',
          icon: Icons.apple,
        );
      case PaymentMethod.googlePay:
        return PaymentMethodInfo(
          name: 'Google Pay',
          description: 'Быстрая оплата через Google Pay',
          icon: Icons.g_mobiledata,
        );
      case PaymentMethod.yooMoney:
        return PaymentMethodInfo(
          name: 'ЮMoney',
          description: 'Электронный кошелек ЮMoney',
          icon: Icons.account_balance_wallet,
        );
      case PaymentMethod.qiwi:
        return PaymentMethodInfo(
          name: 'QIWI',
          description: 'Электронный кошелек QIWI',
          icon: Icons.account_balance_wallet,
        );
      case PaymentMethod.webmoney:
        return PaymentMethodInfo(
          name: 'WebMoney',
          description: 'Электронный кошелек WebMoney',
          icon: Icons.account_balance_wallet,
        );
      case PaymentMethod.bankTransfer:
        return PaymentMethodInfo(
          name: 'Банковский перевод',
          description: 'Перевод на банковский счет',
          icon: Icons.account_balance,
        );
    }
  }

  String _getPaymentTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.prepayment:
        return 'Предоплата';
      case PaymentType.finalPayment:
        return 'Финальный платеж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
      case PaymentType.refund:
        return 'Возврат';
    }
  }

  String _getPaymentStatusName(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.processing:
        return 'Обрабатывается';
      case PaymentStatus.completed:
        return 'Завершен';
      case PaymentStatus.failed:
        return 'Неудачный';
      case PaymentStatus.cancelled:
        return 'Отменен';
      case PaymentStatus.refunded:
        return 'Возвращен';
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.processing:
        return Icons.hourglass_empty;
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.undo;
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
    }
  }
}

class PaymentMethodInfo {
  final String name;
  final String description;
  final IconData icon;

  const PaymentMethodInfo({
    required this.name,
    required this.description,
    required this.icon,
  });
}
