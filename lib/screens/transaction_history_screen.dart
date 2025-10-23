import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import '../providers/auth_providers.dart';
import '../services/financial_report_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';

/// Экран истории транзакций
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final FinancialReportService _reportService = FinancialReportService();

  List<Payment> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _error = null;
        _transactions.clear();
        _hasMore = true;
      });
    }

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        final newTransactions = await _reportService.getTransactionHistory(
          userId: currentUser.id,
          limit: 20,
        );

        setState(() {
          if (loadMore) {
            _transactions.addAll(newTransactions);
          } else {
            _transactions = newTransactions;
          }
          _hasMore = newTransactions.length == 20;
          _isLoading = false;
        });
      }
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
          title: const Text('История транзакций'),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh), onPressed: _loadTransactions)
          ],
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_isLoading && _transactions.isEmpty) {
      return const LoadingWidget(message: 'Загрузка транзакций...');
    }

    if (_error != null && _transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadTransactions, child: const Text('Повторить')),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'Нет транзакций',
        subtitle: 'У вас пока нет транзакций',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            // Кнопка "Загрузить еще"
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ElevatedButton(
                  onPressed:
                      _hasMore ? () => _loadTransactions(loadMore: true) : null,
                  child: const Text('Загрузить еще'),
                ),
              ),
            );
          }

          final transaction = _transactions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTransactionCard(transaction),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(Payment transaction) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с типом и суммой
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(transaction.typeIcon,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.typeName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            transaction.description,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        transaction.formattedAmount,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getAmountColor(transaction),
                        ),
                      ),
                      Text(
                        transaction.statusName,
                        style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(transaction.status)),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Детали транзакции
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Метод оплаты', transaction.methodName),
                    _buildDetailRow(
                        'Дата создания', _formatDate(transaction.createdAt)),
                    if (transaction.completedAt != null)
                      _buildDetailRow('Дата завершения',
                          _formatDate(transaction.completedAt!)),
                    if (transaction.fee != null && transaction.fee! > 0)
                      _buildDetailRow('Комиссия',
                          '${transaction.fee!.toStringAsFixed(2)} ₽'),
                    if (transaction.tax != null && transaction.tax! > 0)
                      _buildDetailRow(
                          'Налог', '${transaction.tax!.toStringAsFixed(2)} ₽'),
                    if (transaction.totalAmount != null &&
                        transaction.totalAmount != transaction.amount)
                      _buildDetailRow(
                          'Итого', transaction.formattedTotalAmount),
                  ],
                ),
              ),

              // Действия (если доступны)
              if (_canShowActions(transaction)) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (transaction.status == PaymentStatus.failed)
                      TextButton.icon(
                        onPressed: () => _retryPayment(transaction),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Повторить'),
                      ),
                    if (transaction.status == PaymentStatus.completed &&
                        (transaction.type == PaymentType.deposit ||
                            transaction.type == PaymentType.finalPayment))
                      TextButton.icon(
                        onPressed: () => _requestRefund(transaction),
                        icon: const Icon(Icons.undo, size: 16),
                        label: const Text('Возврат'),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.orange),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Color _getAmountColor(Payment transaction) {
    switch (transaction.type) {
      case PaymentType.deposit:
      case PaymentType.finalPayment:
        return Colors.red; // Расходы
      case PaymentType.refund:
        return Colors.green; // Возвраты
      case PaymentType.bonus:
        return Colors.blue; // Бонусы
      case PaymentType.penalty:
        return Colors.orange; // Штрафы
      case PaymentType.hold:
        return Colors.grey; // Заморозки
    }
  }

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

  bool _canShowActions(Payment transaction) =>
      transaction.status == PaymentStatus.failed ||
      (transaction.status == PaymentStatus.completed &&
          (transaction.type == PaymentType.deposit ||
              transaction.type == PaymentType.finalPayment));

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Future<void> _retryPayment(Payment transaction) async {
    // TODO(developer): Реализовать повторную попытку платежа
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Повторная попытка платежа будет добавлена в следующей версии')),
    );
  }

  Future<void> _requestRefund(Payment transaction) async {
    // TODO(developer): Реализовать запрос возврата
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Запрос возврата будет добавлен в следующей версии')),
    );
  }
}
