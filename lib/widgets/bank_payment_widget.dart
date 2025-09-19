import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bank_integration_service.dart';

/// Виджет для выбора банка и оплаты
class BankPaymentWidget extends ConsumerStatefulWidget {
  const BankPaymentWidget({
    super.key,
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.description,
    required this.customerEmail,
    required this.customerPhone,
    this.onPaymentInitiated,
    this.onPaymentCompleted,
  });
  final double amount;
  final String currency;
  final String orderId;
  final String description;
  final String customerEmail;
  final String customerPhone;
  final Function(PaymentInitiationResult)? onPaymentInitiated;
  final Function(PaymentStatusResult)? onPaymentCompleted;

  @override
  ConsumerState<BankPaymentWidget> createState() => _BankPaymentWidgetState();
}

class _BankPaymentWidgetState extends ConsumerState<BankPaymentWidget> {
  final BankIntegrationService _bankService = BankIntegrationService();
  String? _selectedBankId;
  String _selectedPaymentMethod = 'card';
  bool _isLoading = false;
  PaymentInitiationResult? _paymentResult;
  BankFee? _bankFee;

  @override
  void initState() {
    super.initState();
    _selectedBankId = _bankService.getDefaultBank().id;
    _loadBankFee();
  }

  Future<void> _loadBankFee() async {
    if (_selectedBankId == null) return;

    try {
      final fee = await _bankService.getBankFee(
        bankId: _selectedBankId!,
        amount: widget.amount,
        paymentMethod: _selectedPaymentMethod,
      );
      setState(() {
        _bankFee = fee;
      });
    } catch (e) {
      // Игнорируем ошибки загрузки комиссии
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          const Text(
            'Выберите способ оплаты',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Сумма к оплате
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Сумма к оплате:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '${widget.amount.toStringAsFixed(2)} ${widget.currency}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (_bankFee != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Комиссия банка (${_bankFee!.feePercentage}%):',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${_bankFee!.totalFee.toStringAsFixed(2)} ${_bankFee!.currency}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Выбор банка
          const Text(
            'Выберите банк:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          ..._bankService.getSupportedBanks().map(_buildBankOption),

          const SizedBox(height: 24),

          // Выбор способа оплаты
          const Text(
            'Способ оплаты:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          _buildPaymentMethodOption(
            'card',
            'Банковская карта',
            Icons.credit_card,
          ),
          _buildPaymentMethodOption('qr', 'QR-код', Icons.qr_code),
          _buildPaymentMethodOption(
            'sbp',
            'Система быстрых платежей',
            Icons.payment,
          ),

          const SizedBox(height: 24),

          // Кнопка оплаты
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _selectedBankId == null
                  ? null
                  : _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
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
                        Text('Обработка...'),
                      ],
                    )
                  : const Text(
                      'Оплатить',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),

          // Результат инициализации платежа
          if (_paymentResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Платеж инициализирован',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('ID платежа: ${_paymentResult!.paymentId}'),
                  Text('Статус: ${_getStatusText(_paymentResult!.status)}'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openPaymentPage,
                      child: const Text('Перейти к оплате'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );

  Widget _buildBankOption(BankInfo bank) {
    final isSelected = _selectedBankId == bank.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBankId = bank.id;
          });
          _loadBankFee();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.blue[50] : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Поддерживаемые методы: ${bank.supportedMethods.join(', ')}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: Colors.blue[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String method, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
          _loadBankFee();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.blue[50] : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: isSelected ? Colors.blue[800] : Colors.black87,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: Colors.blue[600]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (_selectedBankId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _bankService.initiatePayment(
        bankId: _selectedBankId!,
        amount: widget.amount,
        currency: widget.currency,
        orderId: widget.orderId,
        description: widget.description,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
      );

      setState(() {
        _paymentResult = result;
      });

      widget.onPaymentInitiated?.call(result);
    } catch (e) {
      _showError('Ошибка инициализации платежа: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openPaymentPage() {
    if (_paymentResult != null) {
      // TODO: Открыть страницу оплаты или внешний браузер
      _showInfo('Переход к оплате...');
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает оплаты';
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
