import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment.dart';
import '../models/booking.dart';
import '../services/payment_service.dart';
import '../widgets/payment_method_widget.dart';
import '../widgets/payment_summary_widget.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  final PaymentType paymentType;
  final OrganizationType organizationType;

  const PaymentScreen({
    Key? key,
    required this.booking,
    required this.paymentType,
    required this.organizationType,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _amountController = TextEditingController();
  
  PaymentMethod _selectedPaymentMethod = PaymentMethod.bankCard;
  bool _isProcessing = false;
  double _totalAmount = 0.0;
  double _prepaymentAmount = 0.0;
  double _taxAmount = 0.0;
  double _taxRate = 0.0;
  TaxType _taxType = TaxType.none;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _calculateAmounts();
  }

  void _calculateAmounts() {
    final config = PaymentConfiguration.getDefault(widget.organizationType);
    _totalAmount = widget.booking.totalPrice;
    _prepaymentAmount = config.calculateAdvanceAmount(_totalAmount);
    
    // Определяем тип налога в зависимости от типа организации
    switch (widget.organizationType) {
      case OrganizationType.selfEmployed:
        _taxType = TaxType.professionalIncome;
        _taxRate = 4.0; // 4% для самозанятых с физлиц
        break;
      case OrganizationType.entrepreneur:
        _taxType = TaxType.simplifiedTax;
        _taxRate = 6.0; // 6% УСН для ИП
        break;
      case OrganizationType.commercial:
        _taxType = TaxType.vat;
        _taxRate = 20.0; // 20% НДС для коммерческих организаций
        break;
      default:
        _taxType = TaxType.none;
        _taxRate = 0.0;
    }

    _taxAmount = TaxCalculator.calculateTax(_totalAmount, _taxType);
    
    // Устанавливаем сумму для оплаты
    if (widget.paymentType == PaymentType.advance) {
      _amountController.text = _prepaymentAmount.toStringAsFixed(2);
    } else {
      _amountController.text = (_totalAmount - _prepaymentAmount).toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о бронировании
            _buildBookingInfo(),
            const SizedBox(height: 24),
            
            // Сводка по платежу
            PaymentSummaryWidget(
              totalAmount: _totalAmount,
              prepaymentAmount: _prepaymentAmount,
              taxAmount: _taxAmount,
              taxRate: _taxRate,
              taxType: _taxType,
              paymentType: widget.paymentType,
              organizationType: widget.organizationType,
            ),
            const SizedBox(height: 24),
            
            // Выбор метода оплаты
            PaymentMethodWidget(
              selectedMethod: _selectedPaymentMethod,
              onMethodChanged: (method) {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Сумма к оплате
            _buildAmountInput(),
            const SizedBox(height: 24),
            
            // Ошибка
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            // Кнопка оплаты
            _buildPayButton(),
          ],
        ),
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
            _buildInfoRow('Мероприятие', widget.booking.eventTitle),
            _buildInfoRow('Дата', _formatDate(widget.booking.eventDate)),
            _buildInfoRow('Участники', '${widget.booking.participantsCount} чел.'),
            if (widget.booking.eventLocation != null)
              _buildInfoRow('Место', widget.booking.eventLocation!),
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
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сумма к оплате',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Сумма (₽)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: '₽',
                prefixIcon: const Icon(Icons.attach_money),
              ),
              onChanged: (value) {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _getAmountDescription(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
                'Оплатить ${_amountController.text} ₽',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getScreenTitle() {
    switch (widget.paymentType) {
      case PaymentType.advance:
        return 'Оплата аванса';
      case PaymentType.finalPayment:
        return 'Финальный платеж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
      case PaymentType.refund:
        return 'Возврат средств';
    }
  }

  String _getAmountDescription() {
    switch (widget.paymentType) {
      case PaymentType.advance:
        return 'Авансовый платеж (${(_prepaymentAmount / _totalAmount * 100).toStringAsFixed(0)}% от общей суммы)';
      case PaymentType.finalPayment:
        return 'Остаток к доплате после выполнения услуг';
      case PaymentType.fullPayment:
        return 'Полная стоимость услуг';
      case PaymentType.refund:
        return 'Сумма к возврату';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _processPayment() async {
    if (_amountController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Введите сумму для оплаты';
      });
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Введите корректную сумму';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Создаем платеж с автоматическим расчётом налогов
      final payment = await _paymentService.createPaymentWithTaxes(
        bookingId: widget.booking.id,
        customerId: widget.booking.userId,
        specialistId: widget.booking.specialistId ?? '',
        type: widget.paymentType,
        amount: amount,
        organizationType: widget.organizationType,
        taxType: _taxType,
        description: _getPaymentDescription(),
        paymentMethod: _selectedPaymentMethod.name,
        metadata: {
          'bookingId': widget.booking.id,
          'eventTitle': widget.booking.eventTitle,
          'eventDate': widget.booking.eventDate.toIso8601String(),
        },
      );

      // Обрабатываем платеж
      await _paymentService.processPayment(payment.id, _selectedPaymentMethod.name);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Платеж на сумму ${amount.toStringAsFixed(2)} ₽ успешно создан'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при создании платежа: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _getPaymentDescription() {
    switch (widget.paymentType) {
      case PaymentType.advance:
        return 'Авансовый платеж за ${widget.booking.eventTitle}';
      case PaymentType.finalPayment:
        return 'Финальный платеж за ${widget.booking.eventTitle}';
      case PaymentType.fullPayment:
        return 'Полная оплата за ${widget.booking.eventTitle}';
      case PaymentType.refund:
        return 'Возврат средств за ${widget.booking.eventTitle}';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

enum PaymentMethod {
  bankCard,
  yooMoney,
  qiwi,
  webmoney,
  sberbank,
  tinkoff,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.bankCard:
        return 'Банковская карта';
      case PaymentMethod.yooMoney:
        return 'ЮMoney';
      case PaymentMethod.qiwi:
        return 'QIWI';
      case PaymentMethod.webmoney:
        return 'WebMoney';
      case PaymentMethod.sberbank:
        return 'Сбербанк Онлайн';
      case PaymentMethod.tinkoff:
        return 'Тинькофф';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.bankCard:
        return Icons.credit_card;
      case PaymentMethod.yooMoney:
        return Icons.account_balance_wallet;
      case PaymentMethod.qiwi:
        return Icons.phone_android;
      case PaymentMethod.webmoney:
        return Icons.account_balance;
      case PaymentMethod.sberbank:
        return Icons.account_balance;
      case PaymentMethod.tinkoff:
        return Icons.account_balance;
    }
  }
}