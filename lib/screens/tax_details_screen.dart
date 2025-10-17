import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tax_info.dart';
import '../models/user.dart';
import '../services/tax_service.dart';

/// Экран детального просмотра налогов специалиста
class TaxDetailsScreen extends ConsumerStatefulWidget {
  const TaxDetailsScreen({
    super.key,
    required this.user,
  });

  final AppUser user;

  @override
  ConsumerState<TaxDetailsScreen> createState() => _TaxDetailsScreenState();
}

class _TaxDetailsScreenState extends ConsumerState<TaxDetailsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TaxService _taxService = TaxService();

  final String _selectedPeriod = '2024';
  List<TaxInfo> _taxRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTaxRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTaxRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await _taxService.getTaxInfoForSpecialist(widget.user.id);
      setState(() {
        _taxRecords = records;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Налоги'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Записи', icon: Icon(Icons.list)),
              Tab(text: 'Статистика', icon: Icon(Icons.analytics)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTaxRecordsTab(),
            _buildStatisticsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTaxDialog,
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildTaxRecordsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_taxRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Нет записей о налогах',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте первую запись о налоге',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddTaxDialog,
              icon: const Icon(Icons.add),
              label: const Text('Добавить налог'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTaxRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _taxRecords.length,
        itemBuilder: (context, index) {
          final taxInfo = _taxRecords[index];
          return _buildTaxRecordCard(taxInfo);
        },
      ),
    );
  }

  Widget _buildTaxRecordCard(TaxInfo taxInfo) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    taxInfo.taxTypeIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taxInfo.taxTypeDisplayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Период: ${taxInfo.period}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: taxInfo.isPaid ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      taxInfo.paymentStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTaxInfoItem(
                      'Доход',
                      taxInfo.formattedIncome,
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildTaxInfoItem(
                      'Налог',
                      taxInfo.formattedTaxAmount,
                      Icons.account_balance,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildTaxInfoItem(
                      'Ставка',
                      taxInfo.formattedTaxRate,
                      Icons.percent,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              if (!taxInfo.isPaid) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsPaid(taxInfo),
                        icon: const Icon(Icons.check),
                        label: const Text('Отметить как оплаченный'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendReminder(taxInfo),
                        icon: const Icon(Icons.notifications),
                        label: const Text('Напомнить'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildTaxInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      );

  Widget _buildStatisticsTab() => FutureBuilder<Map<String, dynamic>>(
        future: _taxService.getTaxStatistics(widget.user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки статистики: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final stats = snapshot.data ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatCard(
                  'Общая статистика',
                  [
                    _buildStatItem(
                      'Общий доход',
                      '${(stats['totalIncome'] as double? ?? 0.0).toStringAsFixed(0)} ₽',
                      Icons.trending_up,
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Общая сумма налогов',
                      '${(stats['totalTaxAmount'] as double? ?? 0.0).toStringAsFixed(0)} ₽',
                      Icons.account_balance,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Оплачено',
                      '${(stats['paidAmount'] as double? ?? 0.0).toStringAsFixed(0)} ₽',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatItem(
                      'К доплате',
                      '${(stats['unpaidAmount'] as double? ?? 0.0).toStringAsFixed(0)} ₽',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Прогресс оплаты',
                  [
                    LinearProgressIndicator(
                      value: (stats['paymentPercentage'] as double? ?? 0.0) / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (stats['paymentPercentage'] as double? ?? 0.0) == 100
                            ? Colors.green
                            : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Оплачено: ${(stats['paymentPercentage'] as double? ?? 0.0).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _buildStatCard(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );

  void _showAddTaxDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить налог'),
        content: const Text('Здесь будет форма добавления налога'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO(developer): Добавить логику создания налога
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _markAsPaid(TaxInfo taxInfo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отметить как оплаченный'),
        content: const Text(
          'Вы уверены, что хотите отметить этот налог как оплаченный?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _taxService.markTaxAsPaid(
                  taxInfoId: taxInfo.id,
                  paymentMethod: 'Банковский перевод',
                );
                _loadTaxRecords();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Налог отмечен как оплаченный'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on Exception catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _sendReminder(TaxInfo taxInfo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отправить напоминание'),
        content: const Text('Отправить напоминание об оплате налога?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _taxService.sendTaxReminder(taxInfo.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Напоминание отправлено'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on Exception catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}
