import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';
import '../widgets/analytics_chart_widget.dart';

/// Экран аналитики доходов и расходов
class AnalyticsScreen extends ConsumerStatefulWidget {
  final String userId;

  const AnalyticsScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with TickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  late TabController _tabController;

  AnalyticsFilter _filter = const AnalyticsFilter();
  IncomeExpenseStats? _stats;
  List<BudgetGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        _analyticsService.getIncomeExpenseStats(widget.userId, _filter),
        _analyticsService.getUserBudgetGoals(widget.userId).first,
      ]);

      setState(() {
        _stats = futures[0] as IncomeExpenseStats;
        _goals = futures[1] as List<BudgetGoal>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки данных: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Обзор', icon: Icon(Icons.dashboard)),
            Tab(text: 'Графики', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Цели', icon: Icon(Icons.flag)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Фильтр'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Экспорт'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync),
                    SizedBox(width: 8),
                    Text('Синхронизация'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildChartsTab(),
          _buildGoalsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Статистика
          AnalyticsStatsWidget(
            stats: _stats!,
            onViewDetails: () => _tabController.animateTo(1),
          ),

          const SizedBox(height: 16),

          // Последние транзакции
          _buildRecentTransactions(),

          const SizedBox(height: 16),

          // Быстрые действия
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // График доходов по месяцам
          FutureBuilder<List<ChartData>>(
            future: _analyticsService.getIncomeChartData(widget.userId, 6),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              return AnalyticsChartWidget(
                data: snapshot.data ?? [],
                type: ChartType.line,
                title: 'Доходы по месяцам',
                subtitle: 'Последние 6 месяцев',
              );
            },
          ),

          const SizedBox(height: 16),

          // График расходов по месяцам
          FutureBuilder<List<ChartData>>(
            future: _analyticsService.getExpenseChartData(widget.userId, 6),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              return AnalyticsChartWidget(
                data: snapshot.data ?? [],
                type: ChartType.bar,
                title: 'Расходы по месяцам',
                subtitle: 'Последние 6 месяцев',
              );
            },
          ),

          const SizedBox(height: 16),

          // Доходы по категориям
          FutureBuilder<List<ChartData>>(
            future: _analyticsService.getIncomeCategoryChartData(
                widget.userId, _filter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              return AnalyticsChartWidget(
                data: snapshot.data ?? [],
                type: ChartType.pie,
                title: 'Доходы по категориям',
                subtitle: 'Текущий период',
              );
            },
          ),

          const SizedBox(height: 16),

          // Расходы по категориям
          FutureBuilder<List<ChartData>>(
            future: _analyticsService.getExpenseCategoryChartData(
                widget.userId, _filter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              return AnalyticsChartWidget(
                data: snapshot.data ?? [],
                type: ChartType.pie,
                title: 'Расходы по категориям',
                subtitle: 'Текущий период',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Цели
          BudgetGoalsWidget(
            goals: _goals,
            onAddGoal: _showAddGoalDialog,
          ),

          const SizedBox(height: 16),

          // Прогресс по целям
          if (_goals.isNotEmpty) _buildGoalsProgress(),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Последние транзакции',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Все'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Analytics>>(
              stream:
                  _analyticsService.getUserAnalytics(widget.userId, _filter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data ?? [];
                final recentTransactions = transactions.take(5).toList();

                if (recentTransactions.isEmpty) {
                  return const Center(
                    child: Text('Нет транзакций'),
                  );
                }

                return Column(
                  children: recentTransactions.map((transaction) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            transaction.type == AnalyticsType.income
                                ? Colors.green
                                : Colors.red,
                        child: Icon(
                          transaction.type == AnalyticsType.income
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      title: Text(transaction.category),
                      subtitle: Text(transaction.description ?? ''),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${transaction.amount.toStringAsFixed(0)} ₽',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: transaction.type == AnalyticsType.income
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Text(
                            _formatDate(transaction.date),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Быстрые действия',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Добавить доход',
                    Icons.trending_up,
                    Colors.green,
                    () => _showAddTransactionDialog(AnalyticsType.income),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Добавить расход',
                    Icons.trending_down,
                    Colors.red,
                    () => _showAddTransactionDialog(AnalyticsType.expense),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Создать цель',
                    Icons.flag,
                    Colors.blue,
                    _showAddGoalDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Синхронизация',
                    Icons.sync,
                    Colors.orange,
                    _syncData,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Прогресс по целям',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._goals.map((goal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${goal.progressPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: goal.isAchieved
                                ? Colors.green
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: goal.progressPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goal.isAchieved
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog([AnalyticsType? type]) {
    showDialog(
      context: context,
      builder: (context) => _AddTransactionDialog(
        userId: widget.userId,
        initialType: type,
        onTransactionAdded: () {
          _loadData();
        },
      ),
    );
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddGoalDialog(
        userId: widget.userId,
        onGoalAdded: () {
          _loadData();
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        filter: _filter,
        onFilterChanged: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
          _loadData();
        },
      ),
    );
  }

  Future<void> _syncData() async {
    try {
      await _analyticsService.syncFromPayments(widget.userId);
      _loadData();
      _showSuccessSnackBar('Данные синхронизированы');
    } catch (e) {
      _showErrorSnackBar('Ошибка синхронизации: $e');
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter':
        _showFilterDialog();
        break;
      case 'export':
        _exportData();
        break;
      case 'sync':
        _syncData();
        break;
    }
  }

  Future<void> _exportData() async {
    try {
      final csv = await _analyticsService.exportToCSV(widget.userId, _filter);
      // TODO: Сохранить CSV файл
      _showSuccessSnackBar('Данные экспортированы');
    } catch (e) {
      _showErrorSnackBar('Ошибка экспорта: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Диалог добавления транзакции
class _AddTransactionDialog extends StatefulWidget {
  final String userId;
  final AnalyticsType? initialType;
  final VoidCallback onTransactionAdded;

  const _AddTransactionDialog({
    required this.userId,
    this.initialType,
    required this.onTransactionAdded,
  });

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  AnalyticsType _type = AnalyticsType.income;
  String _category = '';
  DateTime _date = DateTime.now();
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
    _category = _type == AnalyticsType.income
        ? IncomeCategories.categories.first
        : ExpenseCategories.categories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          'Добавить ${_type == AnalyticsType.income ? 'доход' : 'расход'}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Тип транзакции
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<AnalyticsType>(
                      title: const Text('Доход'),
                      value: AnalyticsType.income,
                      groupValue: _type,
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                          _category = IncomeCategories.categories.first;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<AnalyticsType>(
                      title: const Text('Расход'),
                      value: AnalyticsType.expense,
                      groupValue: _type,
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                          _category = ExpenseCategories.categories.first;
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Сумма
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  prefixText: '₽ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите сумму';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректную сумму';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Категория
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                items: (_type == AnalyticsType.income
                        ? IncomeCategories.categories
                        : ExpenseCategories.categories)
                    .map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Дата
              ListTile(
                title: const Text('Дата'),
                subtitle: Text(_formatDate(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _date = date;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveTransaction,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final amount = double.parse(_amountController.text);

      String? id;
      if (_type == AnalyticsType.income) {
        id = await _analyticsService.addIncome(
          userId: widget.userId,
          amount: amount,
          category: _category,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          date: _date,
        );
      } else {
        id = await _analyticsService.addExpense(
          userId: widget.userId,
          amount: amount,
          category: _category,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          date: _date,
        );
      }

      if (id != null) {
        Navigator.pop(context);
        widget.onTransactionAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Транзакция добавлена')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка добавления транзакции')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Диалог добавления цели
class _AddGoalDialog extends StatefulWidget {
  final String userId;
  final VoidCallback onGoalAdded;

  const _AddGoalDialog({
    required this.userId,
    required this.onGoalAdded,
  });

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  BudgetType _type = BudgetType.income;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Создать цель'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Название
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название цели',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название цели';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Тип цели
              DropdownButtonFormField<BudgetType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Тип цели',
                  border: OutlineInputBorder(),
                ),
                items: BudgetType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeText(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Сумма
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Целевая сумма',
                  prefixText: '₽ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите сумму';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректную сумму';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Дата
              ListTile(
                title: const Text('Целевая дата'),
                subtitle: Text(_formatDate(_targetDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _targetDate = date;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveGoal,
          child: const Text('Создать'),
        ),
      ],
    );
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final amount = double.parse(_amountController.text);

      final id = await _analyticsService.createBudgetGoal(
        userId: widget.userId,
        name: _nameController.text,
        targetAmount: amount,
        targetDate: _targetDate,
        type: _type,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (id != null) {
        Navigator.pop(context);
        widget.onGoalAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Цель создана')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания цели')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  String _getTypeText(BudgetType type) {
    switch (type) {
      case BudgetType.income:
        return 'Цель по доходам';
      case BudgetType.expense:
        return 'Лимит расходов';
      case BudgetType.savings:
        return 'Накопления';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Диалог фильтра
class _FilterDialog extends StatefulWidget {
  final AnalyticsFilter filter;
  final Function(AnalyticsFilter) onFilterChanged;

  const _FilterDialog({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late AnalyticsFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Фильтр'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Период
          DropdownButtonFormField<AnalyticsPeriod>(
            value: _filter.period,
            decoration: const InputDecoration(
              labelText: 'Период',
              border: OutlineInputBorder(),
            ),
            items: AnalyticsPeriod.values.map((period) {
              return DropdownMenuItem(
                value: period,
                child: Text(_getPeriodText(period)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(period: value);
              });
            },
          ),

          const SizedBox(height: 16),

          // Тип
          DropdownButtonFormField<AnalyticsType?>(
            value: _filter.type,
            decoration: const InputDecoration(
              labelText: 'Тип',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Все'),
              ),
              const DropdownMenuItem(
                value: AnalyticsType.income,
                child: Text('Доходы'),
              ),
              const DropdownMenuItem(
                value: AnalyticsType.expense,
                child: Text('Расходы'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(type: value);
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onFilterChanged(_filter);
            Navigator.pop(context);
          },
          child: const Text('Применить'),
        ),
      ],
    );
  }

  String _getPeriodText(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.week:
        return 'Неделя';
      case AnalyticsPeriod.month:
        return 'Месяц';
      case AnalyticsPeriod.quarter:
        return 'Квартал';
      case AnalyticsPeriod.year:
        return 'Год';
      case AnalyticsPeriod.custom:
        return 'Пользовательский';
    }
  }
}
