import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/enhanced_specialist.dart';

/// Карточка рекомендации специалиста
class SpecialistRecommendationCard extends StatelessWidget {
  const SpecialistRecommendationCard({
    super.key,
    required this.specialist,
    this.recommendationReason,
    this.recommendationScore,
    this.onTap,
    this.onBook,
    this.onFavorite,
  });

  final EnhancedSpecialist specialist;
  final String? recommendationReason;
  final double? recommendationScore;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с аватаром и основной информацией
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аватар
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: specialist.avatarUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: specialist.avatarUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 30,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 30,
                            color: theme.colorScheme.primary,
                          ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Основная информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Имя и статусы
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                specialist.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (specialist.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '✓',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (specialist.isPremium) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Категории
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: specialist.categories.take(3).map((category) => 
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getCategoryDisplayName(category),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Рейтинг и отзывы
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              specialist.rating.toStringAsFixed(1),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${specialist.reviewsCount} отзывов)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Кнопка избранного
                  IconButton(
                    onPressed: onFavorite,
                    icon: const Icon(Icons.favorite_border),
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Местоположение
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    specialist.location,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Ценовой диапазон
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'от ${specialist.minPrice.toStringAsFixed(0)} ₽',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (specialist.maxPrice > specialist.minPrice) ...[
                    Text(
                      ' - до ${specialist.maxPrice.toStringAsFixed(0)} ₽',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
              
              // Причина рекомендации
              if (recommendationReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendationReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (recommendationScore != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(recommendationScore! * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Описание
              if (specialist.description != null) ...[
                Text(
                  specialist.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Статистика
              Row(
                children: [
                  _buildStatItem(
                    context,
                    'Заказов',
                    '${specialist.totalOrders ?? 0}',
                    Icons.shopping_bag,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    context,
                    'Отклик',
                    specialist.responseTime != null 
                        ? '${specialist.responseTime!.inMinutes} мин'
                        : 'N/A',
                    Icons.timer,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    context,
                    'Завершено',
                    specialist.completionRate != null 
                        ? '${(specialist.completionRate! * 100).toInt()}%'
                        : 'N/A',
                    Icons.check_circle,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Кнопки действий
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      child: const Text('Подробнее'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onBook,
                      child: const Text('Заказать'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getCategoryDisplayName(dynamic category) {
    // Здесь должна быть логика получения отображаемого имени категории
    return category.toString();
  }
}
