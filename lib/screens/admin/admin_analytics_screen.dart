import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/marketing_admin_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final MarketingAdminService _marketingService = MarketingAdminService();
  List<FinancialAnalytics> _analytics = [];
  bool _isLoading = true;
  String _selectedPeriod = 'daily';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _marketingService.getFinancialAnalytics(
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки аналитики: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансовая аналитика'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _exportAnalytics),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAnalytics),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFiltersCard(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildRevenueChart(),
                  const SizedBox(height: 16),
                  _buildDetailedAnalytics(),
                ],
              ),
            ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔍 Фильтры', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Период',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Дневной')),
                      DropdownMenuItem(value: 'weekly', child: Text('Недельный')),
                      DropdownMenuItem(value: 'monthly', child: Text('Месячный')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                      _loadAnalytics();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('Начальная дата'),
                    subtitle: Text('${_startDate.day}.${_startDate.month}.${_startDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Конечная дата'),
                    subtitle: Text('${_endDate.day}.${_endDate.month}.${_endDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(false),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: _loadAnalytics, child: const Text('Применить')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_analytics.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16.0), child: Text('Нет данных для отображения')),
      );
    }

    final totalRevenue = _analytics.fold(0.0, (sum, item) => sum + item.totalRevenue);
    final totalSubscriptions = _analytics.fold(0.0, (sum, item) => sum + item.subscriptionRevenue);
    final totalPromotions = _analytics.fold(0.0, (sum, item) => sum + item.promotionRevenue);
    final totalAds = _analytics.fold(0.0, (sum, item) => sum + item.advertisementRevenue);
    final totalTransactions = _analytics.fold(0, (sum, item) => sum + item.totalTransactions);
    final avgArpu = _analytics.isNotEmpty
        ? _analytics.fold(0.0, (sum, item) => sum + item.arpu) / _analytics.length
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Сводка', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Общая выручка',
                    '${totalRevenue.toStringAsFixed(0)}₽',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Транзакций',
                    '$totalTransactions',
                    Icons.payment,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Подписки',
                    '${totalSubscriptions.toStringAsFixed(0)}₽',
                    Icons.subscriptions,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Продвижения',
                    '${totalPromotions.toStringAsFixed(0)}₽',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Реклама',
                    '${totalAds.toStringAsFixed(0)}₽',
                    Icons.campaign,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'ARPU',
                    '${avgArpu.toStringAsFixed(0)}₽',
                    Icons.person,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_analytics.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16.0), child: Text('Нет данных для графика')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 График выручки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _buildSimpleChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart() {
    final maxRevenue = _analytics.map((e) => e.totalRevenue).reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _analytics.length,
      itemBuilder: (context, index) {
        final item = _analytics[index];
        final height = (item.totalRevenue / maxRevenue) * 150;

        return Container(
          width: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text('${item.date.day}', style: const TextStyle(fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedAnalytics() {
    if (_analytics.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16.0), child: Text('Нет детальных данных')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Детальная аналитика',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _analytics.length,
              itemBuilder: (context, index) {
                final item = _analytics[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${item.date.day}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('${item.date.day}.${item.date.month}.${item.date.year}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Выручка: ${item.totalRevenue.toStringAsFixed(0)}₽'),
                        Text('Транзакций: ${item.totalTransactions}'),
                        Text('ARPU: ${item.arpu.toStringAsFixed(0)}₽'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${item.subscriptionRevenue.toStringAsFixed(0)}₽',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('подписки', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _exportAnalytics() async {
    try {
      // Mock export functionality
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Экспорт аналитики в CSV...')));

      // Simulate export delay
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Аналитика экспортирована успешно')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
    }
  }
}
