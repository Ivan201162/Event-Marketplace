import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/transaction.dart';
import '../../services/payment_service.dart';
import '../../widgets/analytics/analytics_card.dart';
import '../../widgets/analytics/revenue_chart.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final PaymentService _paymentService = PaymentService();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Аналитика'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _selectedPeriod = value;
                });
                _loadAnalytics();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'week',
                  child: Text('Неделя'),
                ),
                const PopupMenuItem(
                  value: 'month',
                  child: Text('Месяц'),
                ),
                const PopupMenuItem(
                  value: 'year',
                  child: Text('Год'),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.indigo),
                          const SizedBox(width: 12),
                          Text(
                            'Период: ${_getPeriodText(_selectedPeriod)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Revenue Overview
                    const Text(
                      'Общая статистика',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: AnalyticsCard(
                            title: 'Общий доход',
                            value: '${_getTotalRevenue().toInt()} ₽',
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnalyticsCard(
                            title: 'Транзакций',
                            value: '${_transactions.length}',
                            icon: Icons.receipt,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: AnalyticsCard(
                            title: 'Донаты',
                            value: '${_getDonationsCount()}',
                            icon: Icons.favorite,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnalyticsCard(
                            title: 'Подписки',
                            value: '${_getSubscriptionsCount()}',
                            icon: Icons.diamond,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Revenue Chart
                    const Text(
                      'Динамика доходов',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    RevenueChart(
                      transactions: _transactions,
                      period: _selectedPeriod,
                    ),

                    const SizedBox(height: 24),

                    // Transaction Types
                    const Text(
                      'Типы транзакций',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTransactionTypeChart(),

                    const SizedBox(height: 24),

                    // Recent Transactions
                    const Text(
                      'Последние транзакции',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ..._transactions.take(5).map(
                          _buildTransactionItem,
                        ),

                    if (_transactions.length > 5) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Navigate to full transactions list
                          },
                          child: const Text('Показать все транзакции'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      );

  Widget _buildTransactionTypeChart() {
    final typeStats = _getTransactionTypeStats();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PieChart(
        PieChartData(
          sections: typeStats.entries.map((entry) {
            final color = _getTransactionTypeColor(entry.key);
            return PieChartSectionData(
              color: color,
              value: entry.value,
              title: '${entry.value.toInt()}',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _getTransactionTypeColor(transaction.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTransactionTypeIcon(transaction.type),
                color: _getTransactionTypeColor(transaction.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatDate(transaction.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${transaction.amount.toInt()} ₽',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.status == TransactionStatus.success
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
      );

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions =
          await _paymentService.getUserTransactions(widget.userId);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _getTotalRevenue() => _transactions
      .where((t) => t.status == TransactionStatus.success)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  int _getDonationsCount() => _transactions
      .where((t) =>
          t.type == TransactionType.donation &&
          t.status == TransactionStatus.success)
      .length;

  int _getSubscriptionsCount() => _transactions
      .where((t) =>
          t.type == TransactionType.subscription &&
          t.status == TransactionStatus.success)
      .length;

  Map<TransactionType, double> _getTransactionTypeStats() {
    final stats = <TransactionType, double>{};

    for (final transaction in _transactions) {
      if (transaction.status == TransactionStatus.success) {
        stats[transaction.type] =
            (stats[transaction.type] ?? 0) + transaction.amount;
      }
    }

    return stats;
  }

  Color _getTransactionTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.promotion:
        return Colors.purple;
      case TransactionType.subscription:
        return Colors.blue;
      case TransactionType.donation:
        return Colors.pink;
      case TransactionType.boostPost:
        return Colors.orange;
    }
  }

  IconData _getTransactionTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.promotion:
        return Icons.star;
      case TransactionType.subscription:
        return Icons.diamond;
      case TransactionType.donation:
        return Icons.favorite;
      case TransactionType.boostPost:
        return Icons.trending_up;
    }
  }

  String _getPeriodText(String period) {
    switch (period) {
      case 'week':
        return 'Неделя';
      case 'month':
        return 'Месяц';
      case 'year':
        return 'Год';
      default:
        return 'Месяц';
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
