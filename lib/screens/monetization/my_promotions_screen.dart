import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/promotion_boost.dart';
import '../../services/promotion_service.dart';

class MyPromotionsScreen extends StatefulWidget {
  const MyPromotionsScreen({super.key});

  @override
  State<MyPromotionsScreen> createState() => _MyPromotionsScreenState();
}

class _MyPromotionsScreenState extends State<MyPromotionsScreen> {
  final PromotionService _promotionService = PromotionService();
  List<PromotionBoost> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?['id'];

      if (userId != null) {
        final promotions = await _promotionService.getUserPromotions(userId);
        setState(() {
          _promotions = promotions;
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
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки продвижений: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои продвижения'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promotions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _promotions.length,
              itemBuilder: (context, index) {
                final promotion = _promotions[index];
                return _buildPromotionCard(promotion);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'У вас нет продвижений',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Оформите продвижение для увеличения видимости',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
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
            child: const Text('Выбрать продвижение'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(PromotionBoost promotion) {
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
                    color: _getStatusColor(promotion.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(promotion.status),
                    color: _getStatusColor(promotion.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeText(promotion.type),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getStatusText(promotion.status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getStatusColor(promotion.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(promotion.status),
              ],
            ),
            const SizedBox(height: 16),

            // Детали продвижения
            _buildDetailRow('Приоритет:', _getPriorityText(promotion.priorityLevel)),
            _buildDetailRow('Цена:', '${promotion.price.toInt()} ₽'),
            _buildDetailRow('Начало:', _formatDate(promotion.startDate)),
            _buildDetailRow('Окончание:', _formatDate(promotion.endDate)),
            _buildDetailRow('Показы:', promotion.impressions.toString()),
            _buildDetailRow('Клики:', promotion.clicks.toString()),
            _buildDetailRow('CTR:', '${promotion.ctr.toStringAsFixed(2)}%'),

            if (promotion.isActive) ...[const SizedBox(height: 12), _buildProgressBar(promotion)],

            const SizedBox(height: 16),

            // Действия
            if (promotion.isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pausePromotion(promotion),
                      child: const Text('Пауза'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _cancelPromotion(promotion),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Отменить'),
                    ),
                  ),
                ],
              ),
            ] else if (promotion.status == PromotionStatus.paused) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _resumePromotion(promotion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Возобновить'),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(PromotionBoost promotion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Осталось дней: ${promotion.daysRemaining}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              '${(promotion.progressPercentage * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: promotion.progressPercentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            promotion.isExpiringSoon ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(PromotionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  Color _getStatusColor(PromotionStatus status) {
    switch (status) {
      case PromotionStatus.active:
        return Colors.green;
      case PromotionStatus.expired:
        return Colors.orange;
      case PromotionStatus.cancelled:
        return Colors.red;
      case PromotionStatus.pending:
        return Colors.blue;
      case PromotionStatus.paused:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PromotionStatus status) {
    switch (status) {
      case PromotionStatus.active:
        return Icons.trending_up;
      case PromotionStatus.expired:
        return Icons.schedule;
      case PromotionStatus.cancelled:
        return Icons.cancel;
      case PromotionStatus.pending:
        return Icons.pending;
      case PromotionStatus.paused:
        return Icons.pause;
    }
  }

  String _getStatusText(PromotionStatus status) {
    switch (status) {
      case PromotionStatus.active:
        return 'Активно';
      case PromotionStatus.expired:
        return 'Истекло';
      case PromotionStatus.cancelled:
        return 'Отменено';
      case PromotionStatus.pending:
        return 'Ожидает';
      case PromotionStatus.paused:
        return 'На паузе';
    }
  }

  String _getTypeText(PromotionType type) {
    switch (type) {
      case PromotionType.profileBoost:
        return 'Продвижение профиля';
      case PromotionType.postBoost:
        return 'Продвижение поста';
      case PromotionType.categoryBoost:
        return 'Продвижение в категории';
      case PromotionType.searchBoost:
        return 'Продвижение в поиске';
    }
  }

  String _getPriorityText(PromotionPriority priority) {
    switch (priority) {
      case PromotionPriority.low:
        return 'Низкий';
      case PromotionPriority.medium:
        return 'Средний';
      case PromotionPriority.high:
        return 'Высокий';
      case PromotionPriority.premium:
        return 'Премиум';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _pausePromotion(PromotionBoost promotion) async {
    try {
      final success = await _promotionService.pausePromotion(promotion.id);
      if (success) {
        await _loadPromotions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Продвижение поставлено на паузу'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        throw Exception('Не удалось поставить продвижение на паузу');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _resumePromotion(PromotionBoost promotion) async {
    try {
      final success = await _promotionService.resumePromotion(promotion.id);
      if (success) {
        await _loadPromotions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Продвижение возобновлено'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Не удалось возобновить продвижение');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _cancelPromotion(PromotionBoost promotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить продвижение'),
        content: const Text(
          'Вы уверены, что хотите отменить продвижение? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _promotionService.cancelPromotion(promotion.id);
        if (success) {
          await _loadPromotions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Продвижение успешно отменено'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Не удалось отменить продвижение');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}
