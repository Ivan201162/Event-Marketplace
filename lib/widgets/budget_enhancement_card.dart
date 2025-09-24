import 'package:flutter/material.dart';

import '../models/specialist.dart';
import '../services/enhanced_recommendation_service.dart';

/// Карточка рекомендации по улучшению бюджета
class BudgetEnhancementCard extends StatelessWidget {
  const BudgetEnhancementCard({
    super.key,
    required this.recommendation,
    required this.onTap,
    required this.onAddSpecialist,
  });

  final BudgetEnhancementRecommendation recommendation;
  final VoidCallback onTap;
  final void Function(Specialist) onAddSpecialist;

  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      color: _getCategoryColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: _getCategoryColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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
                      color: _getImpactColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recommendation.impact,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getImpactColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCostInfo(
                      'Дополнительно',
                      recommendation.additionalCost,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCostInfo(
                      'Общий бюджет',
                      recommendation.totalBudget,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recommendation.specialists.isNotEmpty) ...[
                const Text(
                  'Рекомендуемые специалисты:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendation.specialists.length,
                    itemBuilder: (context, index) {
                      final specialist = recommendation.specialists[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          child: InkWell(
                            onTap: () => onAddSpecialist(specialist),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage: specialist.avatarUrl != null
                                            ? NetworkImage(specialist.avatarUrl!)
                                            : null,
                                        child: specialist.avatarUrl == null
                                            ? Text(
                                                specialist.name.isNotEmpty
                                                    ? specialist.name[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          specialist.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        specialist.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${specialist.reviewCount ?? 0})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'от ${(specialist.hourlyRate * (specialist.minBookingHours ?? 1)).toInt()} ₽',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                      fontWeight: FontWeight.w500,
                                    ),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      child: const Text('Подробнее'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Add all specialists from this enhancement
                        for (final specialist in recommendation.specialists) {
                          onAddSpecialist(specialist);
                        }
                      },
                      child: const Text('Добавить все'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  Widget _buildCostInfo(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toInt()} ₽',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() =>
    switch (recommendation.category) {
      SpecialistCategory.lighting => Colors.amber,
      SpecialistCategory.sound => Colors.blue,
      SpecialistCategory.decorator => Colors.purple,
      SpecialistCategory.host => Colors.green,
      SpecialistCategory.animator => Colors.orange,
      SpecialistCategory.makeup => Colors.pink,
      SpecialistCategory.florist => Colors.lightGreen,
      _ => Colors.grey,
    };

  IconData _getCategoryIcon() =>
    switch (recommendation.category) {
      SpecialistCategory.lighting => Icons.lightbulb,
      SpecialistCategory.sound => Icons.volume_up,
      SpecialistCategory.decorator => Icons.palette,
      SpecialistCategory.host => Icons.mic,
      SpecialistCategory.animator => Icons.celebration,
      SpecialistCategory.makeup => Icons.face,
      SpecialistCategory.florist => Icons.local_florist,
      _ => Icons.star,
    };

  Color _getImpactColor() =>
    switch (recommendation.impact) {
      'Высокий' => Colors.red,
      'Средний' => Colors.orange,
      'Низкий' => Colors.green,
      _ => Colors.grey,
    };
}