import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import '../providers/transaction_history_providers.dart';
import '../services/transaction_history_service.dart';
import '../widgets/transaction_history_widget.dart';
import '../widgets/transaction_statistics_widget.dart';
import '../widgets/transaction_filters_widget.dart';

/// Экран истории транзакций
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({
    super.key,
    required this.userId,
    this.initialType,
  });

  final String userId;
  final TransactionType? initialType;

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  TransactionType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _lastDocumentId;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('История транзакций'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Транзакции', icon: Icon(Icons.receipt)),
            Tab(text: 'Статистика', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportTransactions,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    final params = TransactionHistoryParams(
      userId: widget.userId,
      type: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
      limit: 20,
      lastDocumentId: _lastDocumentId,
    );

    return Consumer(
      builder: (context, ref, child) {
        final transactionHistoryAsync = ref.watch(transactionHistoryProvider(params));
        
        return transactionHistoryAsync.when(
          data: (transactions) => TransactionHistoryWidget(
            transactions: transactions,
            onLoadMore: _loadMoreTransactions,
            isLoadingMore: _isLoadingMore,
            onTransactionTap: _showTransactionDetails,
            onRefresh: _refreshTransactions,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки транзакций',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshTransactions,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    final params = TransactionStatisticsParams(
      userId: widget.userId,
      startDate: _startDate,
      endDate: _endDate,
    );

    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(transactionStatisticsProvider(params));
        final monthlyDataAsync = ref.watch(monthlyTransactionDataProvider(
          MonthlyTransactionParams(userId: widget.userId, monthsBack: 12),
        ));
        
        return statisticsAsync.when(
          data: (statistics) => TransactionStatisticsWidget(
            statistics: statistics,
            monthlyData: monthlyDataAsync.value ?? [],
            onPeriodChanged: _updatePeriod,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки статистики',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshStatistics,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionFiltersWidget(
        selectedType: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        onFiltersChanged: (type, startDate, endDate) {
          setState(() {
            _selectedType = type;
            _startDate = startDate;
            _endDate = endDate;
            _lastDocumentId = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _exportTransactions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildExportBottomSheet(),
    );
  }

  Widget _buildExportBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Экспорт транзакций',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text('Выберите формат экспорта:'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _performExport(TransactionExportFormat.csv),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('CSV'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _performExport(TransactionExportFormat.json),
                  icon: const Icon(Icons.code),
                  label: const Text('JSON'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _performExport(TransactionExportFormat.pdf),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
            ),
          ),
        ],
      ),
    );
  }

  void _performExport(TransactionExportFormat format) async {
    Navigator.pop(context);
    
    try {
      final params = TransactionExportParams(
        userId: widget.userId,
        format: format,
        startDate: _startDate,
        endDate: _endDate,
      );

      final export = await ref.read(transactionExportProvider(params).future);
      
      if (mounted) {
        _showExportSuccess(export);
      }
    } catch (e) {
      if (mounted) {
        _showExportError(e.toString());
      }
    }
  }

  void _showExportSuccess(TransactionExport export) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт завершен'),
        content: Text(
          'Файл ${export.filename} готов к скачиванию.\n'
          'Экспортировано транзакций: ${export.transactionCount}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка экспорта'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _loadMoreTransactions() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    // В реальном приложении здесь была бы загрузка дополнительных транзакций
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  void _showTransactionDetails(TransactionHistoryItem transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(
          transactionId: transaction.id,
        ),
      ),
    );
  }

  void _refreshTransactions() {
    setState(() {
      _lastDocumentId = null;
    });
  }

  void _refreshStatistics() {
    // Обновление статистики происходит автоматически через провайдеры
  }

  void _updatePeriod(DateTime? startDate, DateTime? endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
  }
}

/// Экран деталей транзакции
class TransactionDetailsScreen extends ConsumerWidget {
  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
  });

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionDetailsAsync = ref.watch(transactionDetailsProvider(transactionId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали транзакции'),
      ),
      body: transactionDetailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(
              child: Text('Транзакция не найдена'),
            );
          }
          
          return _buildTransactionDetails(context, details);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки деталей',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(BuildContext context, TransactionDetails details) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основная информация
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Основная информация',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('ID транзакции', details.payment.id),
                  _buildInfoRow('Тип', _getTransactionTypeName(details.payment.type)),
                  _buildInfoRow('Сумма', '${details.payment.amount} ${details.payment.currency}'),
                  _buildInfoRow('Статус', _getStatusName(details.payment.status)),
                  _buildInfoRow('Дата создания', _formatDateTime(details.payment.createdAt)),
                  if (details.payment.completedAt != null)
                    _buildInfoRow('Дата завершения', _formatDateTime(details.payment.completedAt!)),
                  if (details.payment.description != null)
                    _buildInfoRow('Описание', details.payment.description!),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Информация о бронировании
          if (details.booking != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация о бронировании',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('ID бронирования', details.booking!.id),
                    _buildInfoRow('Название события', details.booking!.eventTitle),
                    _buildInfoRow('Дата события', _formatDateTime(details.booking!.eventDate)),
                    _buildInfoRow('Количество участников', details.booking!.participantsCount.toString()),
                    _buildInfoRow('Общая стоимость', '${details.booking!.totalPrice} ${details.booking!.currency ?? 'RUB'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Связанные транзакции
          if (details.relatedTransactions.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Связанные транзакции',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ...details.relatedTransactions.map((payment) => 
                      ListTile(
                        title: Text(_getTransactionTypeName(payment.type)),
                        subtitle: Text('${payment.amount} ${payment.currency}'),
                        trailing: Text(_getStatusName(payment.status)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Временная линия
          if (details.timeline.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'История изменений',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ...details.timeline.map((event) => 
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTimelineEventColor(event.type),
                          child: Icon(
                            _getTimelineEventIcon(event.type),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(event.status),
                        subtitle: Text(event.description),
                        trailing: Text(_formatDateTime(event.timestamp)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getTransactionTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.advance:
        return 'Аванс';
      case PaymentType.finalPayment:
        return 'Финальный платеж';
      case PaymentType.fullPayment:
        return 'Полная оплата';
      case PaymentType.refund:
        return 'Возврат';
    }
  }

  String _getStatusName(PaymentStatus status) {
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.'
           '${dateTime.month.toString().padLeft(2, '0')}.'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getTimelineEventColor(TransactionTimelineEventType type) {
    switch (type) {
      case TransactionTimelineEventType.created:
        return Colors.blue;
      case TransactionTimelineEventType.processing:
        return Colors.orange;
      case TransactionTimelineEventType.completed:
        return Colors.green;
      case TransactionTimelineEventType.failed:
        return Colors.red;
      case TransactionTimelineEventType.cancelled:
        return Colors.grey;
    }
  }

  IconData _getTimelineEventIcon(TransactionTimelineEventType type) {
    switch (type) {
      case TransactionTimelineEventType.created:
        return Icons.add;
      case TransactionTimelineEventType.processing:
        return Icons.hourglass_empty;
      case TransactionTimelineEventType.completed:
        return Icons.check;
      case TransactionTimelineEventType.failed:
        return Icons.error;
      case TransactionTimelineEventType.cancelled:
        return Icons.cancel;
    }
  }
}
