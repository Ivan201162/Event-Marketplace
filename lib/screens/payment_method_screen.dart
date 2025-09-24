import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_models.dart';
import '../services/bank_integration_service.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/payment_summary_widget.dart';

/// Экран выбора способа оплаты
class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({
    super.key,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.amount,
    required this.paymentType,
    required this.paymentScheme,
    this.description,
  });

  final String bookingId;
  final String customerId;
  final String specialistId;
  final double amount;
  final PaymentType paymentType;
  final PaymentScheme paymentScheme;
  final String? description;

  @override
  ConsumerState<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;
  final BankIntegrationService _bankService = BankIntegrationService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableMethods = _bankService.getAvailablePaymentMethods();

    return Scaffold(
      appBar: AppBar(
        title: Text('Способ оплаты'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // Сводка платежа
          PaymentSummaryWidget(
            amount: widget.amount,
            paymentType: widget.paymentType,
            paymentScheme: widget.paymentScheme,
            description: widget.description,
          ),
          
          const SizedBox(height: 16),
          
          // Список способов оплаты
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableMethods.length,
              itemBuilder: (context, index) {
                final method = availableMethods[index];
                final fee = _bankService.getPaymentFee(method, widget.amount);
                final totalAmount = widget.amount + fee;
                
                return PaymentMethodCard(
                  method: method,
                  amount: widget.amount,
                  fee: fee,
                  totalAmount: totalAmount,
                  isSelected: _selectedMethod == method,
                  onTap: () => _selectPaymentMethod(method),
                );
              },
            ),
          ),
          
          // Кнопка оплаты
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMethod != null && !_isProcessing
                      ? _processPayment
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Оплатить ${_getTotalAmount().toStringAsFixed(2)} ₽',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPaymentMethod(PaymentMethod method) {
    setState(() {
      _selectedMethod = method;
    });
  }

  double _getTotalAmount() {
    if (_selectedMethod == null) return widget.amount;
    final fee = _bankService.getPaymentFee(_selectedMethod!, widget.amount);
    return widget.amount + fee;
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      PaymentResult result;
      
      switch (_selectedMethod!) {
        case PaymentMethod.yookassa:
          result = await _bankService.createYooKassaPayment(
            paymentId: widget.bookingId,
            amount: widget.amount,
            description: widget.description ?? 'Оплата услуг',
            returnUrl: 'https://yourapp.com/payment/return',
          );
          break;
        case PaymentMethod.sbp:
          result = await _bankService.createSBPPayment(
            paymentId: widget.bookingId,
            amount: widget.amount,
            description: widget.description ?? 'Оплата услуг',
          );
          break;
        case PaymentMethod.card:
          // Для карт используем ЮKassa
          result = await _bankService.createYooKassaPayment(
            paymentId: widget.bookingId,
            amount: widget.amount,
            description: widget.description ?? 'Оплата услуг',
            returnUrl: 'https://yourapp.com/payment/return',
          );
          break;
        case PaymentMethod.bankTransfer:
          // Для банковских переводов показываем реквизиты
          _showBankTransferDetails();
          return;
      }

      if (result.success && result.paymentUrl != null) {
        // Открываем страницу оплаты
        _openPaymentPage(result.paymentUrl!);
      } else {
        _showErrorDialog(result.error ?? 'Ошибка создания платежа');
      }
    } catch (e) {
      _showErrorDialog('Ошибка: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _openPaymentPage(String paymentUrl) {
    // Здесь должна быть логика открытия страницы оплаты
    // Для демонстрации показываем диалог
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переход к оплате'),
        content: const Text('Вы будете перенаправлены на страницу оплаты'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Здесь должен быть переход на страницу оплаты
              _showSuccessDialog();
            },
            child: const Text('Перейти'),
          ),
        ],
      ),
    );
  }

  void _showBankTransferDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Реквизиты для оплаты'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Получатель: ООО "Event Marketplace"'),
            const Text('ИНН: 1234567890'),
            const Text('КПП: 123456789'),
            const Text('Банк: ПАО "Сбербанк"'),
            const Text('БИК: 044525225'),
            const Text('Корр. счёт: 30101810400000000225'),
            const Text('Расчётный счёт: 40702810123456789012'),
            const SizedBox(height: 8),
            Text(
              'Сумма: ${widget.amount.toStringAsFixed(2)} ₽',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Назначение: Оплата услуг по договору'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Платёж создан'),
        content: const Text('Платёж успешно создан. Проверьте статус в разделе "Мои платежи"'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Возвращаемся на предыдущий экран
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
