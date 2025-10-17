import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import 'payment_history_screen.dart';

/// Экран доходов специалиста
class SpecialistEarningsScreen extends ConsumerStatefulWidget {
  const SpecialistEarningsScreen({
    super.key,
    required this.specialistId,
  });

  final String specialistId;

  @override
  ConsumerState<SpecialistEarningsScreen> createState() => _SpecialistEarningsScreenState();
}

class _SpecialistEarningsScreenState extends ConsumerState<SpecialistEarningsScreen> {
  final PaymentService _paymentService = PaymentService();
  Map<String, dynamic>? _stats;
  List<Payment> _recentPayments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = 'month'; // month, quarter, year

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Загружаем статистику
      final stats = await _paymentService.getSpecialistFinancialStats(widget.specialistId);

      // Загружаем последние платежи
      final recentPayments = await _paymentService.getSpecialistPayments(
        widget.specialistId,
        limit: 10,
      );

      setState(() {
        _stats = stats;
        _recentPayments = recentPayments;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Доходы'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadEarningsData,
            ),
            PopupMenuButton<String>(
              onSelected: (period) {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadEarningsData();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'month',
                  child: Text('За месяц'),
                ),
                const PopupMenuItem(
                  value: 'quarter',
                  child: Text('За квартал'),
                ),
                const PopupMenuItem(
                  value: 'year',
                  child: Text('За год'),
                ),
              ],
            ),
          ],
        ),
        body: _buildContent(),
      );

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки данных',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEarningsData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsOverview(),
          const SizedBox(height: 24),
          _buildEarningsChart(),
          const SizedBox(height: 24),
          _buildRecentPayments(),
          const SizedBox(height: 24),
          _buildEarningsBreakdown(),
        ],
      ),
    );
  }

  Widget _buildEarningsOverview() {
    if (_stats == null) return const SizedBox.shrink();

    final totalIncome = _stats!['totalIncome'] as double? ?? 0.0;
    final totalExpenses = _stats!['totalExpenses'] as double? ?? 0.0;
    final netIncome = _stats!['netIncome'] as double? ?? 0.0;
    final completedPayments = _stats!['completedPayments'] as int? ?? 0;
    final pendingPayments = _stats!['pendingPayments'] as int? ?? 0;
    final holdPayments = _stats!['holdPayments'] as int? ?? 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Обзор доходов',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Общий доход',
                    '${totalIncome.toStringAsFixed(0)} ₽',
                    Colors.green,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Чистый доход',
                    '${netIncome.toStringAsFixed(0)} ₽',
                    Colors.blue,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Завершенные',
                    '$completedPayments',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'В ожидании',
                    '$pendingPayments',
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
              ],
            ),
            if (holdPayments > 0) ...[
              const SizedBox(height: 16),
              _buildStatCard(
                'Заморожено',
                '$holdPayments',
                Colors.purple,
                Icons.lock,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildEarningsChart() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Динамика доходов',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'График доходов\n(в разработке)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildRecentPayments() => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Последние платежи',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => PaymentHistoryScreen(
                            userId: widget.specialistId,
                            isSpecialist: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Все платежи'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recentPayments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Платежей пока нет',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._recentPayments.take(5).map(_buildPaymentItem),
            ],
          ),
        ),
      );

  Widget _buildPaymentItem(Payment payment) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(payment.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                payment.typeIcon,
                color: _getStatusColor(payment.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.typeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payment.description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(payment.createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  payment.formattedAmount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: payment.type == PaymentType.refund ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payment.statusName,
                    style: TextStyle(
                      color: _getStatusColor(payment.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildEarningsBreakdown() {
    if (_stats == null) return const SizedBox.shrink();

    final totalIncome = _stats!['totalIncome'] as double? ?? 0.0;
    final totalExpenses = _stats!['totalExpenses'] as double? ?? 0.0;
    final completedPayments = _stats!['completedPayments'] as int? ?? 0;
    final refundedPayments = _stats!['refundedPayments'] as int? ?? 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.purple, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Детализация',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildBreakdownRow('Доходы от услуг', totalIncome, Colors.green),
            _buildBreakdownRow('Возвраты', totalExpenses, Colors.red),
            _buildBreakdownRow(
              'Завершенные платежи',
              completedPayments.toDouble(),
              Colors.blue,
            ),
            if (refundedPayments > 0)
              _buildBreakdownRow(
                'Возвращенные платежи',
                refundedPayments.toDouble(),
                Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double value, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              value < 1000 ? value.toStringAsFixed(0) : '${value.toStringAsFixed(0)} ₽',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
