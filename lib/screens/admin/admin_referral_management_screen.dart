import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/marketing_admin_service.dart';

class AdminReferralManagementScreen extends StatefulWidget {
  const AdminReferralManagementScreen({super.key});

  @override
  State<AdminReferralManagementScreen> createState() => _AdminReferralManagementScreenState();
}

class _AdminReferralManagementScreenState extends State<AdminReferralManagementScreen> {
  final MarketingAdminService _marketingService = MarketingAdminService();
  Map<String, dynamic> _referralStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralStats();
  }

  Future<void> _loadReferralStats() async {
    try {
      final stats = await _marketingService.getReferralStats();
      setState(() {
        _referralStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки статистики: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление рефералами'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReferralStats,
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
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildTopReferrersCard(),
                  const SizedBox(height: 16),
                  _buildReferralSettingsCard(),
                  const SizedBox(height: 16),
                  _buildRecentReferralsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Статистика рефералов',
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
                    'Конверсия',
                    '${_calculateConversionRate()}%',
                    Icons.trending_up,
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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

  Widget _buildTopReferrersCard() {
    final topReferrers = _referralStats['topReferrers'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 Топ рефереры',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (topReferrers.isEmpty)
              const Text('Нет данных о реферерах')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topReferrers.length,
                itemBuilder: (context, index) {
                  final referrer = topReferrers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('Пользователь ${referrer['userId']}'),
                    subtitle: Text('Пригласил ${referrer['invitedCount']} пользователей'),
                    trailing: Text(
                      '${referrer['bonusesActivated']} бонусов',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Настройки реферальной программы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Бонус за приглашение'),
              subtitle: const Text('5 дней Premium для реферера, 3 дня для реферала'),
              trailing: const Icon(Icons.edit),
              onTap: () => _showBonusSettingsDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Награды за достижения'),
              subtitle: const Text('5 приглашений = 30 дней Premium, 10 = 1 месяц PRO'),
              trailing: const Icon(Icons.edit),
              onTap: () => _showRewardsSettingsDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.toggle_on),
              title: const Text('Статус программы'),
              subtitle: const Text('Активна'),
              trailing: Switch(
                value: true,
                onChanged: (value) => _toggleReferralProgram(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReferralsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Последние рефералы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('referrals')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }

                final referrals = snapshot.data?.docs ?? [];
                if (referrals.isEmpty) {
                  return const Text('Нет рефералов');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: referrals.length,
                  itemBuilder: (context, index) {
                    final referralData = referrals[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getReferralStatusColor(referralData['status']),
                        child: Icon(
                          _getReferralStatusIcon(referralData['status']),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      title: Text('Реферал от ${referralData['referrerId']}'),
                      subtitle: Text(
                        'Код: ${referralData['referralCode']} • ${_formatTimestamp(referralData['createdAt'])}',
                      ),
                      trailing: Text(
                        _getReferralStatusName(referralData['status']),
                        style: TextStyle(
                          color: _getReferralStatusColor(referralData['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBonusSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки бонусов'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Бонус для реферера (дни Premium)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Бонус для реферала (дни Premium)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки бонусов сохранены')),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showRewardsSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки наград'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Приглашений для Premium (дни)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Приглашений для PRO (месяцы)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки наград сохранены')),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _toggleReferralProgram(bool isActive) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Реферальная программа ${isActive ? 'активирована' : 'деактивирована'}'),
      ),
    );
  }

  String _calculateConversionRate() {
    final total = _referralStats['totalReferrals'] ?? 0;
    final active = _referralStats['activeReferrals'] ?? 0;
    if (total == 0) return '0';
    return ((active / total) * 100).toStringAsFixed(1);
  }

  Color _getReferralStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getReferralStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check;
      case 'pending':
        return Icons.schedule;
      case 'expired':
        return Icons.expired;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getReferralStatusName(String status) {
    switch (status) {
      case 'completed':
        return 'Завершен';
      case 'pending':
        return 'В ожидании';
      case 'expired':
        return 'Истек';
      case 'cancelled':
        return 'Отменен';
      default:
        return 'Неизвестно';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}.${date.month}.${date.year}';
    }
    return 'Неизвестно';
  }
}
