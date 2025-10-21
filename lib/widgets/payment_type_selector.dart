import 'package:flutter/material.dart';
import '../models/payment_extended.dart';

/// Виджет для выбора типа оплаты
class PaymentTypeSelector extends StatefulWidget {
  const PaymentTypeSelector({
    super.key,
    required this.totalAmount,
    required this.settings,
    required this.onPaymentTypeSelected,
  });
  final double totalAmount;
  final AdvancePaymentSettings settings;
  final void Function(PaymentType, double?, int?) onPaymentTypeSelected;

  @override
  State<PaymentTypeSelector> createState() => _PaymentTypeSelectorState();
}

class _PaymentTypeSelectorState extends State<PaymentTypeSelector> {
  PaymentType _selectedType = PaymentType.full;
  double _selectedAdvancePercentage = 30;
  int _selectedInstallments = 3;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите тип оплаты',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Типы оплаты
          _buildPaymentTypeOptions(),

          const SizedBox(height: 16),

          // Дополнительные настройки
          if (_selectedType == PaymentType.advance) ...[
            _buildAdvanceSettings(),
          ] else if (_selectedType == PaymentType.installment) ...[
            _buildInstallmentSettings(),
          ],

          const SizedBox(height: 16),

          // Сводка
          _buildPaymentSummary(),

          const SizedBox(height: 16),

          // Кнопка подтверждения
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _confirmSelection, child: const Text('Подтвердить')),
          ),
        ],
      );

  Widget _buildPaymentTypeOptions() => Column(
        children: [
          _buildPaymentTypeOption(
            type: PaymentType.full,
            title: 'Полная оплата',
            subtitle: 'Оплатить всю сумму сразу',
            icon: Icons.payment,
            amount: widget.totalAmount,
          ),
          const SizedBox(height: 8),
          _buildPaymentTypeOption(
            type: PaymentType.advance,
            title: 'Предоплата',
            subtitle: 'Оплатить часть суммы сейчас, остальное позже',
            icon: Icons.account_balance_wallet,
            amount: _calculateAdvanceAmount(),
          ),
          const SizedBox(height: 8),
          _buildPaymentTypeOption(
            type: PaymentType.installment,
            title: 'Рассрочка',
            subtitle: 'Разделить оплату на несколько частей',
            icon: Icons.schedule,
            amount: _calculateInstallmentAmount(),
          ),
          const SizedBox(height: 8),
          _buildPaymentTypeOption(
            type: PaymentType.partial,
            title: 'Частичная оплата',
            subtitle: 'Оплатить 50% сейчас, 50% позже',
            icon: Icons.percent,
            amount: widget.totalAmount * 0.5,
          ),
        ],
      );

  Widget _buildPaymentTypeOption({
    required PaymentType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required double amount,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Text(
              '${amount.toStringAsFixed(0)} ₽',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceSettings() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройки предоплаты',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Проценты предоплаты
            const Text(
              'Размер предоплаты:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: widget.settings.availablePercentages.map((percentage) {
                final isSelected = _selectedAdvancePercentage == percentage;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAdvancePercentage = percentage;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (widget.settings.allowCustomAmount) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customAmountController,
                decoration: const InputDecoration(
                  labelText: 'Или введите сумму',
                  hintText: 'Введите сумму предоплаты',
                  prefixText: '₽ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  if (amount != null && amount > 0) {
                    setState(() {
                      _selectedAdvancePercentage = (amount / widget.totalAmount) * 100;
                    });
                  }
                },
              ),
            ],
          ],
        ),
      );

  Widget _buildInstallmentSettings() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройки рассрочки',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Количество взносов
            const Text(
              'Количество взносов:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: List.generate(widget.settings.maxInstallments, (index) {
                final count = index + 1;
                final isSelected = _selectedInstallments == count;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedInstallments = count;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );

  Widget _buildPaymentSummary() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Сводка платежа',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Общая сумма:'),
                Text(
                  '${widget.totalAmount.toStringAsFixed(2)} ₽',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_selectedType != PaymentType.full) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Первый платеж:'),
                  Text(
                    '${_getFirstPaymentAmount().toStringAsFixed(2)} ₽',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Остаток:'),
                  Text(
                    '${_getRemainingAmount().toStringAsFixed(2)} ₽',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      );

  double _calculateAdvanceAmount() => widget.totalAmount * (_selectedAdvancePercentage / 100);

  double _calculateInstallmentAmount() => widget.totalAmount / _selectedInstallments;

  double _getFirstPaymentAmount() {
    switch (_selectedType) {
      case PaymentType.advance:
        return _calculateAdvanceAmount();
      case PaymentType.installment:
        return _calculateInstallmentAmount();
      case PaymentType.partial:
        return widget.totalAmount * 0.5;
      case PaymentType.full:
        return widget.totalAmount;
    }
  }

  double _getRemainingAmount() => widget.totalAmount - _getFirstPaymentAmount();

  void _confirmSelection() {
    double? advancePercentage;
    int? installments;

    if (_selectedType == PaymentType.advance) {
      advancePercentage = _selectedAdvancePercentage;
    } else if (_selectedType == PaymentType.installment) {
      installments = _selectedInstallments;
    }

    widget.onPaymentTypeSelected(_selectedType, advancePercentage, installments);
  }
}
