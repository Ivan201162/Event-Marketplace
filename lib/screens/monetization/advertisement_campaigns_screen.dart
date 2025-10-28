import 'package:event_marketplace_app/models/advertisement.dart';
import 'package:event_marketplace_app/screens/monetization/create_advertisement_screen.dart';
import 'package:event_marketplace_app/services/advertisement_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdvertisementCampaignsScreen extends StatefulWidget {
  const AdvertisementCampaignsScreen({super.key});

  @override
  State<AdvertisementCampaignsScreen> createState() =>
      _AdvertisementCampaignsScreenState();
}

class _AdvertisementCampaignsScreenState
    extends State<AdvertisementCampaignsScreen> {
  final AdvertisementService _advertisementService = AdvertisementService();
  List<AdCampaign> _campaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?['id'];

      if (userId != null) {
        final campaigns = await _advertisementService.getUserCampaigns(userId);
        setState(() {
          _campaigns = campaigns;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки кампаний: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекламные кампании'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateAdvertisementScreen(),),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _campaigns.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = _campaigns[index];
                    return _buildCampaignCard(campaign);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'У вас нет рекламных кампаний',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте рекламную кампанию для продвижения ваших услуг',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateAdvertisementScreen(),),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Создать кампанию'),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(AdCampaign campaign) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: campaign.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    campaign.isActive ? Icons.campaign : Icons.pause_circle,
                    color: campaign.isActive ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        campaign.isActive ? 'Активна' : 'Приостановлена',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: campaign.isActive
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(campaign),
              ],
            ),
            const SizedBox(height: 16),

            // Детали кампании
            _buildDetailRow('Бюджет:', '${campaign.budget.toInt()} ₽'),
            _buildDetailRow('Потрачено:', '${campaign.spentAmount.toInt()} ₽'),
            _buildDetailRow(
                'Остаток:', '${campaign.remainingBudget.toInt()} ₽',),
            _buildDetailRow('Показы:', campaign.impressions.toString()),
            _buildDetailRow('Клики:', campaign.clicks.toString()),
            _buildDetailRow('CTR:', '${campaign.ctr.toStringAsFixed(2)}%'),

            const SizedBox(height: 16),

            // Прогресс бюджета
            _buildBudgetProgress(campaign),

            const SizedBox(height: 16),

            // Действия
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewCampaignDetails(campaign),
                    child: const Text('Подробнее'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _manageCampaign(campaign),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          campaign.isActive ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        Text(campaign.isActive ? 'Управлять' : 'Активировать'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(AdCampaign campaign) {
    final progress =
        campaign.budget > 0 ? campaign.spentAmount / campaign.budget : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Использование бюджета',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            campaign.isBudgetExceeded ? Colors.red : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(AdCampaign campaign) {
    Color color;
    String text;

    if (campaign.isExpired) {
      color = Colors.red;
      text = 'Истекла';
    } else if (campaign.isBudgetExceeded) {
      color = Colors.orange;
      text = 'Бюджет исчерпан';
    } else if (campaign.isActive) {
      color = Colors.green;
      text = 'Активна';
    } else {
      color = Colors.grey;
      text = 'Приостановлена';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  void _viewCampaignDetails(AdCampaign campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(campaign.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (campaign.description != null) ...[
              Text('Описание: ${campaign.description}'),
              const SizedBox(height: 8),
            ],
            Text('Бюджет: ${campaign.budget.toInt()} ₽'),
            Text('Потрачено: ${campaign.spentAmount.toInt()} ₽'),
            Text('Показы: ${campaign.impressions}'),
            Text('Клики: ${campaign.clicks}'),
            Text('CTR: ${campaign.ctr.toStringAsFixed(2)}%'),
            Text('Начало: ${_formatDate(campaign.startDate)}'),
            Text('Окончание: ${_formatDate(campaign.endDate)}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),),
        ],
      ),
    );
  }

  void _manageCampaign(AdCampaign campaign) {
    // TODO: Реализовать управление кампанией
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Функция управления кампанией будет реализована в следующей версии',),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
