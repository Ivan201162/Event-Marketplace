import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../services/transaction_history_service.dart';

/// Виджет истории транзакций
class TransactionHistoryWidget extends StatelessWidget {
  const TransactionHistoryWidget({
    super.key,
    required this.transactions,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.onTransactionTap,
    required this.onRefresh,
  });

  final List<TransactionHistoryItem> transactions;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final Function(TransactionHistoryItem) onTransactionTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == transactions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final transaction = transactions[index];
          return TransactionItemWidget(
            transaction: transaction,
            onTap: () => onTransactionTap(transaction),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет транзакций',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут отображаться ваши транзакции',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Обновить'),
          ),
        ],
      ),
    );
  }
}

/// Виджет элемента транзакции
class TransactionItemWidget extends StatelessWidget {
  const TransactionItemWidget({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final TransactionHistoryItem transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(transaction.status),
          child: Icon(
            _getTransactionIcon(transaction.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.description,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(transaction.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            if (transaction.booking != null)
              Text(
                transaction.booking!.eventTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: _getAmountColor(transaction.type),
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(transaction.status),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(transaction.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.advancePayment:
        return Icons.payment;
      case TransactionType.finalPayment:
        return Icons.account_balance_wallet;
      case TransactionType.fullPayment:
        return Icons.credit_card;
      case TransactionType.refund:
        return Icons.undo;
    }
  }

  Color _getAmountColor(TransactionType type) {
    switch (type) {
      case TransactionType.refund:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.processing:
        return 'Обработка';
      case PaymentStatus.completed:
        return 'Завершено';
      case PaymentStatus.failed:
        return 'Ошибка';
      case PaymentStatus.cancelled:
        return 'Отменено';
      case PaymentStatus.refunded:
        return 'Возврат';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Сегодня ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }
}
