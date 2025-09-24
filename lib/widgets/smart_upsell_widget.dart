import 'package:flutter/material.dart';

import '../services/ai_recommendation_service.dart';

/// Виджет Smart Upsell для предложения дополнительных услуг
class SmartUpsellWidget extends StatefulWidget {
  const SmartUpsellWidget({
    super.key,
    required this.userId,
    required this.currentServiceId,
    required this.currentBudget,
    this.onServiceSelected,
  });

  final String userId;
  final String currentServiceId;
  final double currentBudget;
  final Function(UpsellRecommendation)? onServiceSelected;

  @override
  State<SmartUpsellWidget> createState() => _SmartUpsellWidgetState();
}

class _SmartUpsellWidgetState extends State<SmartUpsellWidget> {
  List<UpsellRecommendation> _upsellRecommendations = [];
  bool _isLoading = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUpsellRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_upsellRecommendations.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Дополнительные услуги',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Увеличьте ценность вашего заказа',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
          ),
          
          // Контент
          if (_isExpanded) ...[
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ..._upsellRecommendations.map((recommendation) => 
                _buildUpsellItem(context, recommendation)),
            
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildUpsellItem(BuildContext context, UpsellRecommendation recommendation) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Иконка услуги
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getServiceIcon(recommendation.service.category),
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Информация об услуге
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.service.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Цена и кнопка
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${recommendation.estimatedValue.toStringAsFixed(0)} ₽',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => widget.onServiceSelected?.call(recommendation),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: const Text('Добавить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadUpsellRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final aiService = AIRecommendationService();
      final recommendations = await aiService.getUpsellRecommendations(
        userId: widget.userId,
        currentServiceId: widget.currentServiceId,
        currentBudget: widget.currentBudget,
      );

      setState(() {
        _upsellRecommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Ошибка загрузки upsell рекомендаций: $e');
    }
  }

  IconData _getServiceIcon(String category) {
    switch (category.toLowerCase()) {
      case 'photography':
        return Icons.camera_alt;
      case 'videography':
        return Icons.videocam;
      case 'music':
        return Icons.music_note;
      case 'catering':
        return Icons.restaurant;
      case 'decoration':
        return Icons.celebration;
      case 'florist':
        return Icons.local_florist;
      case 'makeup':
        return Icons.face;
      case 'transport':
        return Icons.directions_car;
      case 'security':
        return Icons.security;
      default:
        return Icons.work;
    }
  }
}

/// Виджет для отображения рекомендаций "Вам может понравиться"
class YouMightLikeWidget extends StatelessWidget {
  const YouMightLikeWidget({
    super.key,
    required this.recommendations,
    this.onSpecialistSelected,
  });

  final List<SpecialistRecommendation> recommendations;
  final Function(EnhancedSpecialist)? onSpecialistSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Вам может понравиться',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  child: Card(
                    child: InkWell(
                      onTap: () => onSpecialistSelected?.call(recommendation.specialist),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Аватар и основная информация
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                  child: recommendation.specialist.avatarUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            recommendation.specialist.avatarUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => 
                                                Icon(Icons.person, color: theme.colorScheme.primary),
                                          ),
                                        )
                                      : Icon(Icons.person, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recommendation.specialist.name,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.amber, size: 14),
                                          const SizedBox(width: 2),
                                          Text(
                                            recommendation.specialist.rating.toStringAsFixed(1),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                  
                            const SizedBox(height: 8),
                  
                            // Причина рекомендации
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                recommendation.reason,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                  
                            const Spacer(),
                  
                            // Цена
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'от ${recommendation.specialist.minPrice.toStringAsFixed(0)} ₽',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(recommendation.score * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
