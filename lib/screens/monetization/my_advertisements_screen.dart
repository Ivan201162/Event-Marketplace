import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/advertisement.dart';
import '../../services/advertisement_service.dart';

class MyAdvertisementsScreen extends StatefulWidget {
  const MyAdvertisementsScreen({super.key});

  @override
  State<MyAdvertisementsScreen> createState() => _MyAdvertisementsScreenState();
}

class _MyAdvertisementsScreenState extends State<MyAdvertisementsScreen> {
  final AdvertisementService _advertisementService = AdvertisementService();
  List<Advertisement> _advertisements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
  }

  Future<void> _loadAdvertisements() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?['id'];

      if (userId != null) {
        // Получаем все рекламные объявления пользователя
        final campaigns = await _advertisementService.getUserCampaigns(userId);
        final advertisements = <Advertisement>[];

        for (final campaign in campaigns) {
          advertisements.addAll(campaign.ads);
        }

        setState(() {
          _advertisements = advertisements;
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
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки рекламы: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя реклама'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _advertisements.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _advertisements.length,
                  itemBuilder: (context, index) {
                    final advertisement = _advertisements[index];
                    return _buildAdvertisementCard(advertisement);
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
            'У вас нет рекламных объявлений',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте рекламное объявление для продвижения ваших услуг',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Создать рекламу'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertisementCard(Advertisement advertisement) {
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
                    color: _getStatusColor(advertisement.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(advertisement.status),
                    color: _getStatusColor(advertisement.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advertisement.title ?? 'Без названия',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getStatusText(advertisement.status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getStatusColor(advertisement.status),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(advertisement.status),
              ],
            ),
            const SizedBox(height: 16),

            // Детали рекламы
            _buildDetailRow('Тип:', _getTypeText(advertisement.type)),
            _buildDetailRow(
                'Размещение:', _getPlacementText(advertisement.placement)),
            _buildDetailRow('Цена:', '${advertisement.price.toInt()} ₽'),
            _buildDetailRow('Начало:', _formatDate(advertisement.startDate)),
            _buildDetailRow('Окончание:', _formatDate(advertisement.endDate)),
            _buildDetailRow('Показы:', advertisement.impressions.toString()),
            _buildDetailRow('Клики:', advertisement.clicks.toString()),
            _buildDetailRow('CTR:', '${advertisement.ctr.toStringAsFixed(2)}%'),
            _buildDetailRow(
                'CPC:', '${advertisement.cpc.toStringAsFixed(2)} ₽'),
            _buildDetailRow(
                'CPM:', '${advertisement.cpm.toStringAsFixed(2)} ₽'),

            if (advertisement.budget != null) ...[
              _buildDetailRow('Бюджет:', '${advertisement.budget!.toInt()} ₽'),
              _buildDetailRow(
                  'Потрачено:', '${advertisement.spentAmount.toInt()} ₽'),
              _buildDetailRow(
                  'Остаток:', '${advertisement.remainingBudget.toInt()} ₽'),
            ],

            if (advertisement.isActive) ...[
              const SizedBox(height: 12),
              _buildProgressBar(advertisement),
            ],

            const SizedBox(height: 16),

            // Действия
            if (advertisement.isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pauseAdvertisement(advertisement),
                      child: const Text('Пауза'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _viewAdvertisementDetails(advertisement),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Подробнее'),
                    ),
                  ),
                ],
              ),
            ] else if (advertisement.status == AdStatus.paused) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewAdvertisementDetails(advertisement),
                      child: const Text('Подробнее'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _resumeAdvertisement(advertisement),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Возобновить'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _viewAdvertisementDetails(advertisement),
                  child: const Text('Подробнее'),
                ),
              ),
            ],
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

  Widget _buildProgressBar(Advertisement advertisement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Осталось дней: ${advertisement.daysRemaining}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              '${(advertisement.progressPercentage * 100).toInt()}%',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: advertisement.progressPercentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            advertisement.isExpiringSoon ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(AdStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
            color: _getStatusColor(status),
            fontWeight: FontWeight.w500,
            fontSize: 12),
      ),
    );
  }

  Color _getStatusColor(AdStatus status) {
    switch (status) {
      case AdStatus.active:
        return Colors.green;
      case AdStatus.paused:
        return Colors.orange;
      case AdStatus.expired:
        return Colors.grey;
      case AdStatus.rejected:
        return Colors.red;
      case AdStatus.pending:
        return Colors.blue;
      case AdStatus.draft:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(AdStatus status) {
    switch (status) {
      case AdStatus.active:
        return Icons.campaign;
      case AdStatus.paused:
        return Icons.pause;
      case AdStatus.expired:
        return Icons.schedule;
      case AdStatus.rejected:
        return Icons.cancel;
      case AdStatus.pending:
        return Icons.pending;
      case AdStatus.draft:
        return Icons.edit;
    }
  }

  String _getStatusText(AdStatus status) {
    switch (status) {
      case AdStatus.active:
        return 'Активно';
      case AdStatus.paused:
        return 'На паузе';
      case AdStatus.expired:
        return 'Истекло';
      case AdStatus.rejected:
        return 'Отклонено';
      case AdStatus.pending:
        return 'Ожидает';
      case AdStatus.draft:
        return 'Черновик';
    }
  }

  String _getTypeText(AdType type) {
    switch (type) {
      case AdType.banner:
        return 'Баннер';
      case AdType.inline:
        return 'Встроенная';
      case AdType.profileBoost:
        return 'Продвижение профиля';
      case AdType.sponsoredPost:
        return 'Спонсорский пост';
      case AdType.categoryAd:
        return 'Реклама в категории';
      case AdType.searchAd:
        return 'Реклама в поиске';
    }
  }

  String _getPlacementText(AdPlacement placement) {
    switch (placement) {
      case AdPlacement.topBanner:
        return 'Верхний баннер';
      case AdPlacement.bottomBanner:
        return 'Нижний баннер';
      case AdPlacement.betweenPosts:
        return 'Между постами';
      case AdPlacement.profileHeader:
        return 'Заголовок профиля';
      case AdPlacement.searchResults:
        return 'Результаты поиска';
      case AdPlacement.categoryList:
        return 'Список категорий';
      case AdPlacement.homeFeed:
        return 'Лента новостей';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _viewAdvertisementDetails(Advertisement advertisement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(advertisement.title ?? 'Рекламное объявление'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (advertisement.description != null) ...[
                Text('Описание: ${advertisement.description}'),
                const SizedBox(height: 8),
              ],
              Text('Тип: ${_getTypeText(advertisement.type)}'),
              Text('Размещение: ${_getPlacementText(advertisement.placement)}'),
              Text('Цена: ${advertisement.price.toInt()} ₽'),
              if (advertisement.budget != null) ...[
                Text('Бюджет: ${advertisement.budget!.toInt()} ₽'),
                Text('Потрачено: ${advertisement.spentAmount.toInt()} ₽'),
                Text('Остаток: ${advertisement.remainingBudget.toInt()} ₽'),
              ],
              Text('Показы: ${advertisement.impressions}'),
              Text('Клики: ${advertisement.clicks}'),
              Text('CTR: ${advertisement.ctr.toStringAsFixed(2)}%'),
              Text('CPC: ${advertisement.cpc.toStringAsFixed(2)} ₽'),
              Text('CPM: ${advertisement.cpm.toStringAsFixed(2)} ₽'),
              Text('Начало: ${_formatDate(advertisement.startDate)}'),
              Text('Окончание: ${_formatDate(advertisement.endDate)}'),
              if (advertisement.region != null)
                Text('Регион: ${advertisement.region}'),
              if (advertisement.city != null)
                Text('Город: ${advertisement.city}'),
              if (advertisement.category != null)
                Text('Категория: ${advertisement.category}'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Future<void> _pauseAdvertisement(Advertisement advertisement) async {
    try {
      final success =
          await _advertisementService.pauseAdvertisement(advertisement.id);
      if (success) {
        await _loadAdvertisements();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Реклама поставлена на паузу'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        throw Exception('Не удалось поставить рекламу на паузу');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _resumeAdvertisement(Advertisement advertisement) async {
    try {
      final success =
          await _advertisementService.resumeAdvertisement(advertisement.id);
      if (success) {
        await _loadAdvertisements();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Реклама возобновлена'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Не удалось возобновить рекламу');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }
}
