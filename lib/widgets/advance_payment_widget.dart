import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/advance_payment_service.dart';
import '../services/bank_integration_service.dart';
import 'bank_payment_widget.dart';

/// Виджет для управления авансами и финальными платежами
class AdvancePaymentWidget extends ConsumerStatefulWidget {
  const AdvancePaymentWidget({
    super.key,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.totalAmount,
    this.onPaymentCompleted,
  });
  final String bookingId;
  final String customerId;
  final String specialistId;
  final double totalAmount;
  final Function()? onPaymentCompleted;

  @override
  ConsumerState<AdvancePaymentWidget> createState() =>
      _AdvancePaymentWidgetState();
}

class _AdvancePaymentWidgetState extends ConsumerState<AdvancePaymentWidget> {
  final AdvancePaymentService _paymentService = AdvancePaymentService();
  final BankIntegrationService _bankService = BankIntegrationService();

  PaymentSummary? _paymentSummary;
  bool _isLoading = true;
  String? _selectedBankId;
  double _advanceAmount = 0;
  bool _showAdvanceForm = false;
  bool _showFinalForm = false;

  @override
  void initState() {
    super.initState();
    _selectedBankId = _bankService.getDefaultBank().id;
    _loadPaymentSummary();
  }

  Future<void> _loadPaymentSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await _paymentService.getPaymentSummary(widget.bookingId);
      setState(() {
        _paymentSummary = summary;
        _advanceAmount =
            _paymentService.calculateRecommendedAdvance(widget.totalAmount);
      });
    } catch (e) {
      _showError('Ошибка загрузки информации о платежах: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentSummary == null) {
      return const Center(
          child: Text('Не удалось загрузить информацию о платежах'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          const Text(
            'Управление платежами',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Сводка по платежам
          _buildPaymentSummary(),

          const SizedBox(height: 24),

          // Кнопки действий
          _buildActionButtons(),

          const SizedBox(height: 24),

          // Форма авансового платежа
          if (_showAdvanceForm) _buildAdvancePaymentForm(),

          // Форма финального платежа
          if (_showFinalForm) _buildFinalPaymentForm(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final summary = _paymentSummary!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'Сводка по платежам',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
              'Общая сумма:', '${summary.totalAmount.toStringAsFixed(2)} ₽'),
          _buildSummaryRow('Аванс оплачен:',
              '${summary.advanceAmount.toStringAsFixed(2)} ₽'),
          _buildSummaryRow('Финальный платеж:',
              '${summary.finalAmount.toStringAsFixed(2)} ₽'),
          _buildSummaryRow(
              'Всего оплачено:', '${summary.totalPaid.toStringAsFixed(2)} ₽'),
          const Divider(),
          _buildSummaryRow(
            'Остаток к доплате:',
            '${summary.remainingAmount.toStringAsFixed(2)} ₽',
            isHighlighted: true,
          ),
          if (summary.nextPaymentDue != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Следующий платеж до: ${_formatDate(summary.nextPaymentDue!)}',
                    style: TextStyle(
                        color: Colors.orange[800], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildPaymentStatus(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
          {bool isHighlighted = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isHighlighted ? Colors.blue[800] : Colors.black87,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isHighlighted ? Colors.blue[800] : Colors.black87,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  Widget _buildPaymentStatus() {
    final summary = _paymentSummary!;
    String statusText;
    Color statusColor;

    if (summary.isFullyPaid) {
      statusText = 'Полностью оплачено';
      statusColor = Colors.green;
    } else if (summary.isAdvancePaid) {
      statusText = 'Аванс оплачен';
      statusColor = Colors.orange;
    } else {
      statusText = 'Ожидает аванса';
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: statusColor, size: 8),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
                color: statusColor, fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final summary = _paymentSummary!;

    return Row(
      children: [
        if (!summary.isAdvancePaid) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showAdvanceForm = !_showAdvanceForm;
                  _showFinalForm = false;
                });
              },
              icon: const Icon(Icons.payment),
              label: const Text('Оплатить аванс'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (summary.isAdvancePaid && !summary.isFullyPaid) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showFinalForm = !_showFinalForm;
                  _showAdvanceForm = false;
                });
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Финальный платеж'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancePaymentForm() => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Авансовый платеж',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Сумма аванса
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Сумма аванса (₽)',
                border: OutlineInputBorder(),
                suffixText: '₽',
              ),
              value: _advanceAmount.toStringAsFixed(0),
              onChanged: (value) {
                setState(() {
                  _advanceAmount = double.tryParse(value) ?? 0.0;
                });
              },
            ),

            const SizedBox(height: 8),
            Text(
              'Рекомендуемая сумма: ${_paymentService.calculateRecommendedAdvance(widget.totalAmount).toStringAsFixed(0)} ₽ (30% от общей суммы)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),

            const SizedBox(height: 16),

            // Виджет оплаты
            BankPaymentWidget(
              amount: _advanceAmount,
              currency: 'RUB',
              orderId: 'advance_${widget.bookingId}',
              description: 'Авансовый платеж за бронирование',
              customerEmail:
                  'customer@example.com', // TODO(developer): Получить из профиля
              customerPhone:
                  '+7XXXXXXXXXX', // TODO(developer): Получить из профиля
              onPaymentInitiated: (result) {
                _showSuccess('Авансовый платеж инициализирован');
                _loadPaymentSummary();
              },
            ),
          ],
        ),
      );

  Widget _buildFinalPaymentForm() {
    final summary = _paymentSummary!;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Финальный платеж',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          Text(
            'К доплате: ${summary.remainingAmount.toStringAsFixed(2)} ₽',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 16),

          // Виджет оплаты
          BankPaymentWidget(
            amount: summary.remainingAmount,
            currency: 'RUB',
            orderId: 'final_${widget.bookingId}',
            description: 'Финальный платеж за услугу',
            customerEmail:
                'customer@example.com', // TODO(developer): Получить из профиля
            customerPhone:
                '+7XXXXXXXXXX', // TODO(developer): Получить из профиля
            onPaymentInitiated: (result) {
              _showSuccess('Финальный платеж инициализирован');
              _loadPaymentSummary();
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green));
  }
}
