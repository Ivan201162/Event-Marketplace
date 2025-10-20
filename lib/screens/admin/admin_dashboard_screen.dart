import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/marketing_admin_service.dart';
import 'admin_advertisement_management_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_logs_screen.dart';
import 'admin_newsletter_management_screen.dart';
import 'admin_promotions_management_screen.dart';
import 'admin_referral_management_screen.dart';
import 'admin_subscription_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final MarketingAdminService _marketingService = MarketingAdminService();
  Map<String, dynamic> _systemStats = {};
  Map<String, dynamic> _referralStats = {};
  Map<String, dynamic> _partnerStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final systemStats = await _adminService.getSystemStats();
      final referralStats = await _marketingService.getReferralStats();
      final partnerStats = await _marketingService.getPartnerStats();

      setState(() {
        _systemStats = systemStats;
        _referralStats = referralStats;
        _partnerStats = partnerStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель маркетинга'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLogsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSystemStatsCard(),
                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 16),
                  _buildReferralStatsCard(),
                  const SizedBox(height: 16),
                  _buildPartnerStatsCard(),
                  const SizedBox(height: 16),
                  _buildRecentActivityCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSystemStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Системная статистика',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Пользователи',
                    '${_systemStats['totalUsers'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Активные',
                    '${_systemStats['activeUsers'] ?? 0}',
                    Icons.person,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Транзакции',
                    '${_systemStats['totalTransactions'] ?? 0}',
                    Icons.payment,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Выручка',
                    '${(_systemStats['totalRevenue'] ?? 0.0).toStringAsFixed(0)}₽',
                    Icons.attach_money,
                    Colors.purple,
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
                    '${_systemStats['totalSubscriptions'] ?? 0}',
                    Icons.subscriptions,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Активные',
                    '${_systemStats['activeSubscriptions'] ?? 0}',
                    Icons.check_circle,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Быстрые действия',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  '💰 Тарифы',
                  Icons.credit_card,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminSubscriptionManagementScreen()),
                  ),
                ),
                _buildActionCard(
                  '📢 Реклама',
                  Icons.campaign,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAdvertisementManagementScreen()),
                  ),
                ),
                _buildActionCard(
                  '🎯 Акции',
                  Icons.local_offer,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPromotionsManagementScreen()),
                  ),
                ),
                _buildActionCard(
                  '👥 Рефералы',
                  Icons.group_add,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminReferralManagementScreen()),
                  ),
                ),
                _buildActionCard(
                  '📈 Аналитика',
                  Icons.analytics,
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
                  ),
                ),
                _buildActionCard(
                  '✉️ Рассылки',
                  Icons.email,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminNewsletterManagementScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👥 Статистика рефералов',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Всего рефералов',
                    '${_referralStats['totalReferrals'] ?? 0}',
                    Icons.group,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Активные',
                    '${_referralStats['activeReferrals'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'За месяц',
                    '${_referralStats['thisMonthReferrals'] ?? 0}',
                    Icons.calendar_month,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Топ реферер',
                    '${(_referralStats['topReferrers'] as List?)?.isNotEmpty == true ? (_referralStats['topReferrers'] as List).first['invitedCount'] ?? 0 : 0}',
                    Icons.star,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🤝 Статистика партнёров',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Всего партнёров',
                    '${_partnerStats['totalPartners'] ?? 0}',
                    Icons.business,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Активные',
                    '${_partnerStats['activePartners'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Комиссии',
                    '${(_partnerStats['totalCommissions'] ?? 0.0).toStringAsFixed(0)}₽',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Топ партнёр',
                    '${(_partnerStats['topPartners'] as List?)?.isNotEmpty == true ? (_partnerStats['topPartners'] as List).first['totalEarnings']?.toStringAsFixed(0) ?? '0' : '0'}₽',
                    Icons.star,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Последние действия',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _adminService.getAdminLogsStream(limit: 5).map((logs) {
                // Convert logs to QuerySnapshot-like structure
                return QuerySnapshot(
                  docs: logs
                      .map((log) => QueryDocumentSnapshot(
                            log.id,
                            log.toMap(),
                          ))
                      .toList(),
                );
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }

                final logs = snapshot.data?.docs ?? [];
                if (logs.isEmpty) {
                  return const Text('Нет последних действий');
                }

                return Column(
                  children: logs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Icon(
                        _getActionIcon(data['action']),
                        color: _getActionColor(data['status']),
                      ),
                      title: Text(data['description'] ?? 'Действие'),
                      subtitle: Text(
                        '${data['adminEmail']} • ${_formatTimestamp(data['timestamp'])}',
                      ),
                      trailing: Icon(
                        _getStatusIcon(data['status']),
                        color: _getActionColor(data['status']),
                        size: 16,
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

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'activate':
        return Icons.play_arrow;
      case 'deactivate':
        return Icons.pause;
      default:
        return Icons.info;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Неизвестно';
  }
}
