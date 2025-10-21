import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tax_info.dart';
import '../models/user.dart';
import '../services/tax_service.dart';

/// Экран калькулятора налогов
class TaxCalculatorScreen extends ConsumerStatefulWidget {
  const TaxCalculatorScreen({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends ConsumerState<TaxCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _periodController = TextEditingController();

  TaxType _selectedTaxType = TaxType.individual;
  double _calculatedTax = 0;
  double _calculatedRate = 0;
  bool _isCalculated = false;

  @override
  void initState() {
    super.initState();
    _periodController.text = _getCurrentPeriod();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  String _getCurrentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Калькулятор налогов'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информационная карточка
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Калькулятор поможет рассчитать сумму налога на основе вашего дохода и типа налогообложения.',
                        style: TextStyle(color: Colors.blue[800], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Выбор типа налогообложения
            Text(
              'Тип налогообложения',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...TaxType.values.map(
              (taxType) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<TaxType>(
                  title: Row(
                    children: [
                      Text(taxType.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              taxType.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              taxType.description,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  value: taxType,
                  groupValue: _selectedTaxType,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTaxType = value;
                        _isCalculated = false;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Поле ввода дохода
            TextFormField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Сумма дохода (₽)',
                hintText: 'Введите сумму дохода',
                prefixIcon: Icon(Icons.monetization_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите сумму дохода';
                }
                final income = double.tryParse(value.trim());
                if (income == null || income <= 0) {
                  return 'Введите корректную сумму';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _isCalculated = false;
                });
              },
            ),

            const SizedBox(height: 16),

            // Поле ввода периода
            TextFormField(
              controller: _periodController,
              decoration: const InputDecoration(
                labelText: 'Период',
                hintText: 'Например: 2024-01',
                prefixIcon: Icon(Icons.calendar_month),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите период';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Кнопка расчёта
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculateTax,
                icon: const Icon(Icons.calculate),
                label: const Text('Рассчитать налог'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),

            const SizedBox(height: 24),

            // Результат расчёта
            if (_isCalculated) _buildCalculationResult(),

            const SizedBox(height: 24),

            // Кнопка сохранения
            if (_isCalculated)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveTaxCalculation,
                  icon: const Icon(Icons.save),
                  label: const Text('Сохранить расчёт'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _buildCalculationResult() => Card(
    color: Colors.green[50],
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Результат расчёта',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultRow(
            'Тип налогообложения',
            _selectedTaxType.displayName,
            _selectedTaxType.icon,
          ),
          const SizedBox(height: 8),
          _buildResultRow(
            'Налоговая ставка',
            '${(_calculatedRate * 100).toStringAsFixed(1)}%',
            Icons.percent,
          ),
          const SizedBox(height: 8),
          _buildResultRow('Сумма дохода', '${_incomeController.text} ₽', Icons.monetization_on),
          const SizedBox(height: 8),
          _buildResultRow(
            'Сумма налога',
            '${_calculatedTax.toStringAsFixed(0)} ₽',
            Icons.account_balance,
            isHighlighted: true,
          ),
          const SizedBox(height: 8),
          _buildResultRow(
            'Чистый доход',
            '${(double.parse(_incomeController.text) - _calculatedTax).toStringAsFixed(0)} ₽',
            Icons.trending_up,
          ),
        ],
      ),
    ),
  );

  Widget _buildResultRow(String label, String value, IconData icon, {bool isHighlighted = false}) =>
      Row(
        children: [
          Icon(icon, size: 20, color: isHighlighted ? Colors.green[700] : Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isHighlighted ? Colors.green[700] : Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: isHighlighted ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      );

  void _calculateTax() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final income = double.parse(_incomeController.text.trim());

    // Рассчитываем налог
    _calculatedRate = _getTaxRate(_selectedTaxType, income);
    _calculatedTax = income * _calculatedRate;

    setState(() {
      _isCalculated = true;
    });
  }

  double _getTaxRate(TaxType taxType, double income) {
    switch (taxType) {
      case TaxType.individual:
        return 0.13; // 13% НДФЛ
      case TaxType.selfEmployed:
        return 0.04; // 4% для самозанятых
      case TaxType.individualEntrepreneur:
        return 0.06; // 6% УСН "доходы"
      case TaxType.government:
        return 0; // Освобождено
    }
  }

  Future<void> _saveTaxCalculation() async {
    if (!_isCalculated) return;

    try {
      final income = double.parse(_incomeController.text.trim());
      final period = _periodController.text.trim();

      final taxInfo = await TaxService().calculateTaxFromEarnings(
        userId: widget.user.id,
        specialistId: widget.user.id, // Для упрощения используем userId как specialistId
        taxType: _selectedTaxType,
        period: period,
        earnings: income,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Расчёт сохранён успешно'), backgroundColor: Colors.green),
        );

        // Очищаем форму
        _incomeController.clear();
        _periodController.text = _getCurrentPeriod();
        setState(() {
          _isCalculated = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
