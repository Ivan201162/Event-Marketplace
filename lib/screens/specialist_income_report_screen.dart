import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../services/financial_report_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';

/// Экран отчета по доходам для специалиста
class SpecialistIncomeReportScreen extends ConsumerStatefulWidget {
  const SpecialistIncomeReportScreen({super.key});

  @override
  ConsumerState<SpecialistIncomeReportScreen> createState() => _SpecialistIncomeReportScreenState();
}

class _SpecialistIncomeReportScreenState extends ConsumerState<SpecialistIncomeReportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FinancialReportService _reportService = FinancialReportService();

  SpecialistIncomeReport? _report;
  bool _isLoading = false;
  String? _error;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        final report = await _reportService.generateSpecialistIncomeReport(
          specialistId: currentUser.id,
          startDate: _startDate,
          endDate: _endDate,
        );
        setState(() {
          _report = report;
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
      title: const Text('Отчет по доходам'),
      actions: [
        IconButton(icon: const Icon(Icons.date_range), onPressed: _selectDateRange),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReport),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Обзор', icon: Icon(Icons.dashboard)),
          Tab(text: 'По месяцам', icon: Icon(Icons.calendar_month)),
          Tab(text: 'По типам', icon: Icon(Icons.category)),
          Tab(text: 'Методы оплаты', icon: Icon(Icons.payment)),
        ],
      ),
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Загрузка отчета...');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReport, child: const Text('Повторить')),
          ],
        ),
      );
    }

    if (_report == null) {
      return const EmptyStateWidget(
        icon: Icons.trending_up,
        title: 'Нет данных для отчета',
        subtitle: 'Выберите период для генерации отчета',
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildMonthlyTab(),
        _buildTypeTab(),
        _buildPaymentMethodTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final report = _report!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Период отчета
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Период отчета',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(report.period, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Основные показатели доходов
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Доходы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Общий доход',
                    report.formattedTotalIncome,
                    Icons.trending_up,
                    Colors.green,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Комиссии',
                          report.formattedTotalFees,
                          Icons.percent,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Налоги',
                          report.formattedTotalTaxes,
                          Icons.receipt_long,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Чистый доход',
                    report.formattedNetIncome,
                    Icons.account_balance_wallet,
                    Colors.blue,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Статистика заказов
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Статистика заказов',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Всего заказов',
                          report.totalBookings.toString(),
                          Icons.shopping_bag,
                          Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Средний чек',
                          report.formattedAverageBookingValue,
                          Icons.attach_money,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTab() {
    final report = _report!;

    if (report.monthlyBreakdown.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.calendar_month,
        title: 'Нет данных по месяцам',
        subtitle: 'В выбранном периоде нет доходов',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Доходы по месяцам',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...report.monthlyBreakdown.entries.map((entry) {
            final maxAmount = report.monthlyBreakdown.values.reduce((a, b) => a > b ? a : b);
            final percentage = entry.value / maxAmount;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatMonth(entry.key),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(2)} ₽',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypeTab() {
    final report = _report!;

    if (report.typeBreakdown.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.category,
        title: 'Нет данных по типам',
        subtitle: 'В выбранном периоде нет доходов',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Доходы по типам платежей',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...report.typeBreakdown.entries.map((entry) {
            final total = report.typeBreakdown.values.fold(0, (a, b) => a + b);
            final percentage = entry.value / total * 100;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.value.toStringAsFixed(2)} ₽',
                        style: const TextStyle(fontSize: 16, color: Colors.green),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTab() {
    final report = _report!;

    if (report.paymentMethodStats.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.payment,
        title: 'Нет данных по методам оплаты',
        subtitle: 'В выбранном периоде нет доходов',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Доходы по методам оплаты',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...report.paymentMethodStats.entries.map((entry) {
            final total = report.paymentMethodStats.values.fold(0, (a, b) => a + b);
            final percentage = entry.value / total * 100;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.value.toStringAsFixed(2)} ₽',
                        style: const TextStyle(fontSize: 16, color: Colors.green),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) => Container(
    width: isFullWidth ? double.infinity : null,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildStatItem(String title, String value, IconData icon, Color color) => Column(
    children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 8),
      Text(
        value,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
      Text(
        title,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
    ],
  );

  String _formatMonth(String monthKey) {
    final parts = monthKey.split('-');
    final year = parts[0];
    final month = parts[1];

    final monthNames = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];

    final monthIndex = int.parse(month) - 1;
    return '${monthNames[monthIndex]} $year';
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }
}
