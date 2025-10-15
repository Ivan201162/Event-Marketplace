import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/referral.dart';
import '../services/referral_service.dart';

/// Экран партнёрской программы
class PartnerProgramScreen extends ConsumerStatefulWidget {
  const PartnerProgramScreen({super.key});

  @override
  ConsumerState<PartnerProgramScreen> createState() =>
      _PartnerProgramScreenState();
}

class _PartnerProgramScreenState extends ConsumerState<PartnerProgramScreen>
    with TickerProviderStateMixin {
  final ReferralService _referralService = ReferralService();
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  PartnerProgram? _partnerProgram;
  List<Referral> _referrals = [];
  List<Bonus> _bonuses = [];
  int _bonusBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const userId = 'current_user'; // TODO: Получать из аутентификации

      // Получаем или создаем партнёрскую программу
      _partnerProgram = await _referralService.getPartnerProgram(userId);
      if (_partnerProgram == null) {
        final referralCode =
            await _referralService.createPartnerProgram(userId);
        if (referralCode != null) {
          _partnerProgram = await _referralService.getPartnerProgram(userId);
        }
      }

      // Загружаем данные
      _referrals = await _referralService.getUserReferrals(userId);
      _bonuses = await _referralService.getUserBonuses(userId);
      _bonusBalance = await _referralService.getUserBonusBalance(userId);

      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Партнёрская программа'),
          elevation: 0,
          backgroundColor: Colors.purple.shade50,
          foregroundColor: Colors.purple.shade800,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.purple.shade600,
            labelColor: Colors.purple.shade800,
            unselectedLabelColor: Colors.grey.shade600,
            tabs: const [
              Tab(text: 'Обзор', icon: Icon(Icons.dashboard)),
              Tab(text: 'Рефералы', icon: Icon(Icons.people)),
              Tab(text: 'Бонусы', icon: Icon(Icons.card_giftcard)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildReferralsTab(),
                    _buildBonusesTab(),
                  ],
                ),
              ),
      );

  Widget _buildOverviewTab() {
    if (_partnerProgram == null) {
      return const Center(
        child: Text('Ошибка загрузки партнёрской программы'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статус и прогресс
          _buildStatusCard(),

          const SizedBox(height: 20),

          // Реферальная ссылка
          _buildReferralLinkCard(),

          const SizedBox(height: 20),

          // QR-код
          _buildQRCodeCard(),

          const SizedBox(height: 20),

          // Статистика
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _partnerProgram!.status;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              status.color.withValues(alpha: 0.1),
              status.color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  status.icon,
                  size: 32,
                  color: status.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: status.color,
                            ),
                      ),
                      Text(
                        '${_partnerProgram!.completedReferrals} из ${_partnerProgram!.totalReferrals} рефералов',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_partnerProgram!.canUpgrade) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _partnerProgram!.progressToNextStatus,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(status.color),
              ),
              const SizedBox(height: 8),
              Text(
                'До ${_partnerProgram!.nextStatus?.displayName}: ${_partnerProgram!.nextStatus?.minReferrals ?? 0 - _partnerProgram!.completedReferrals} рефералов',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReferralLinkCard() => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.link,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ваша реферальная ссылка',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _partnerProgram!.referralLink,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // TODO: Копирование в буфер обмена
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ссылка скопирована')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Share.share(
                          'Присоединяйся к Event Marketplace по моей ссылке: ${_partnerProgram!.referralLink}',
                          subject: 'Приглашение в Event Marketplace',
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Поделиться'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showQRCode,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('QR-код'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildQRCodeCard() => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'QR-код для быстрого доступа',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: _partnerProgram!.referralLink,
                  size: 150,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStatsCard() => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статистика',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Всего рефералов',
                      '${_partnerProgram!.totalReferrals}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Завершено',
                      '${_partnerProgram!.completedReferrals}',
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
                      'Всего бонусов',
                      '${_partnerProgram!.totalBonus}',
                      Icons.card_giftcard,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Баланс',
                      '$_bonusBalance',
                      Icons.account_balance_wallet,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildReferralsTab() {
    if (_referrals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет рефералов',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Поделитесь своей ссылкой с друзьями',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _referrals.length,
      itemBuilder: (context, index) {
        final referral = _referrals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: referral.isCompleted
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              child: Icon(
                referral.isCompleted ? Icons.check : Icons.pending,
                color: referral.isCompleted
                    ? Colors.green.shade600
                    : Colors.orange.shade600,
              ),
            ),
            title: Text(
              referral.invitedUserName ?? 'Пользователь',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(referral.invitedUserEmail ?? 'Email не указан'),
                Text(
                  'Приглашен: ${_formatDate(referral.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (referral.isCompleted)
                  Text(
                    'Завершен: ${_formatDate(referral.completedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade600,
                        ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${referral.bonus}',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'бонусов',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonusesTab() {
    if (_bonuses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет бонусов',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Приглашайте друзей и зарабатывайте бонусы',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bonuses.length,
      itemBuilder: (context, index) {
        final bonus = _bonuses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  bonus.isUsed ? Colors.grey.shade100 : Colors.green.shade100,
              child: Icon(
                bonus.isUsed ? Icons.check_circle : Icons.card_giftcard,
                color:
                    bonus.isUsed ? Colors.grey.shade600 : Colors.green.shade600,
              ),
            ),
            title: Text(
              bonus.description,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Получен: ${_formatDate(bonus.earnedAt)}'),
                if (bonus.isUsed)
                  Text(
                    'Использован: ${_formatDate(bonus.usedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
              ],
            ),
            trailing: Text(
              '+${bonus.amount}',
              style: TextStyle(
                color:
                    bonus.isUsed ? Colors.grey.shade600 : Colors.green.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR-код'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: _partnerProgram!.referralLink,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Покажите этот QR-код друзьям для быстрой регистрации',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
