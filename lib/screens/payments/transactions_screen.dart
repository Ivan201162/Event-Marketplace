import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/transaction.dart';
import '../../providers/auth_providers.dart';
import '../../providers/payment_providers.dart';
import '../../widgets/transaction_card.dart';

/// Screen for displaying transaction history
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Транзакции'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Все', icon: Icon(Icons.list)),
            Tab(text: 'Доходы', icon: Icon(Icons.trending_up)),
            Tab(text: 'Расходы', icon: Icon(Icons.trending_down)),
            Tab(text: 'Статистика', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userTransactionsProvider);
            },
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllTransactionsTab(user.id),
              _buildIncomeTransactionsTab(user.id),
              _buildExpenseTransactionsTab(user.id),
              _buildStatisticsTab(user.id),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllTransactionsTab(String userId) {
    final transactionsAsync = ref.watch(userTransactionsStreamProvider(userId));

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.account_balance_wallet,
            title: 'Нет транзакций',
            subtitle: 'Здесь будут отображаться ваши транзакции',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userTransactionsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionCard(
                transaction: transaction,
                onTap: () => _showTransactionDetails(transaction),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildIncomeTransactionsTab(String userId) {
    final incomeTransactionsAsync = ref.watch(incomeTransactionsProvider(userId));

    return incomeTransactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.trending_up,
            title: 'Нет доходов',
            subtitle: 'Здесь будут отображаться ваши доходы',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(incomeTransactionsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionCard(
                transaction: transaction,
                onTap: () => _showTransactionDetails(transaction),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildExpenseTransactionsTab(String userId) {
    final expenseTransactionsAsync = ref.watch(expenseTransactionsProvider(userId));

    return expenseTransactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.trending_down,
            title: 'Нет расходов',
            subtitle: 'Здесь будут отображаться ваши расходы',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(expenseTransactionsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionCard(
                transaction: transaction,
                onTap: () => _showTransactionDetails(transaction),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildStatisticsTab(String userId) {
    final balanceAsync = ref.watch(userBalanceProvider(userId));
    final totalIncomeAsync = ref.watch(totalIncomeProvider(userId));
    final totalExpenseAsync = ref.watch(totalExpenseProvider(userId));
    final monthlyIncomeAsync = ref.watch(monthlyIncomeProvider(userId));
    final monthlyExpenseAsync = ref.watch(monthlyExpenseProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userBalanceProvider);
        ref.invalidate(totalIncomeProvider);
        ref.invalidate(totalExpenseProvider);
        ref.invalidate(monthlyIncomeProvider);
        ref.invalidate(monthlyExpenseProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            balanceAsync.when(
              data: (balance) => _buildBalanceCard(balance),
              loading: () => _buildLoadingCard(),
              error: (error, stack) => _buildErrorCard(),
            ),
            const SizedBox(height: 16),
            // Monthly Statistics
            Text(
              'За этот месяц',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: monthlyIncomeAsync.when(
                    data: (income) =>
                        _buildStatCard('Доходы', income, Colors.green, Icons.trending_up),
                    loading: () => _buildLoadingStatCard(),
                    error: (error, stack) => _buildErrorStatCard(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: monthlyExpenseAsync.when(
                    data: (expense) =>
                        _buildStatCard('Расходы', expense, Colors.red, Icons.trending_down),
                    loading: () => _buildLoadingStatCard(),
                    error: (error, stack) => _buildErrorStatCard(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total Statistics
            Text(
              'Всего',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: totalIncomeAsync.when(
                    data: (income) => _buildStatCard(
                      'Общие доходы',
                      income,
                      Colors.green,
                      Icons.account_balance_wallet,
                    ),
                    loading: () => _buildLoadingStatCard(),
                    error: (error, stack) => _buildErrorStatCard(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: totalExpenseAsync.when(
                    data: (expense) =>
                        _buildStatCard('Общие расходы', expense, Colors.red, Icons.shopping_cart),
                    loading: () => _buildLoadingStatCard(),
                    error: (error, stack) => _buildErrorStatCard(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(int balance) {
    final rubles = balance / 100;
    final isPositive = balance >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Текущий баланс',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '${rubles.toStringAsFixed(2)} ₽',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isPositive ? 'Положительный' : 'Отрицательный',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int amount, Color color, IconData icon) {
    final rubles = amount / 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${rubles.toStringAsFixed(2)} ₽',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Загрузка баланса...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStatCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Загрузка...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorStatCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 24),
            const SizedBox(height: 4),
            Text(
              'Ошибка',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Ошибка загрузки транзакций'),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(userTransactionsProvider);
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionDetailsSheet(transaction: transaction),
    );
  }
}

/// Bottom sheet for displaying transaction details
class TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailsSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getTypeColor(transaction.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(transaction.typeIcon, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            transaction.type.displayName,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          transaction.formattedAmount,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: _getTypeColor(transaction.type),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          transaction.formattedDate,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDetailRow('ID транзакции', transaction.id),
                    _buildDetailRow('Тип', transaction.type.displayName),
                    _buildDetailRow('Сумма', transaction.formattedAbsoluteAmount),
                    _buildDetailRow('Валюта', transaction.currency),
                    _buildDetailRow('Дата', transaction.formattedDateTime),
                    if (transaction.category != null)
                      _buildDetailRow('Категория', transaction.category!),
                    if (transaction.notes != null) _buildDetailRow('Заметки', transaction.notes!),
                    if (transaction.referenceId != null)
                      _buildDetailRow('Ссылка', transaction.referenceId!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
      case TransactionType.refund:
        return Colors.purple;
      case TransactionType.commission:
        return Colors.orange;
      case TransactionType.bonus:
        return Colors.yellow;
    }
  }
}
