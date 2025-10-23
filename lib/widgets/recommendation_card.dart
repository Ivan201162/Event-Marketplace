import 'package:flutter/material.dart';

import '../models/common_types.dart';
import '../models/recommendation.dart';
import '../models/specialist.dart';

/// Карточка рекомендации специалиста
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
    this.onBook,
    this.showReason = true,
    this.compact = false,
  });

  final Recommendation recommendation;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final bool showReason;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final specialist = recommendation.specialist;

    if (compact) {
      return _buildCompactCard(context, specialist);
    } else {
      return _buildFullCard(context, specialist);
    }
  }

  Widget _buildFullCard(BuildContext context, Specialist specialist) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, specialist),
                const SizedBox(height: 12),
                _buildSpecialistInfo(context, specialist),
                if (showReason) ...[
                  const SizedBox(height: 12),
                  _buildReason(context)
                ],
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ),
          ),
        ),
      );

  Widget _buildCompactCard(BuildContext context, Specialist specialist) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildCompactAvatar(specialist),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactName(specialist),
                      const SizedBox(height: 4),
                      _buildCompactRating(specialist),
                      const SizedBox(height: 4),
                      _buildCompactPrice(specialist),
                    ],
                  ),
                ),
                _buildCompactTypeBadge(context),
              ],
            ),
          ),
        ),
      );

  Widget _buildHeader(BuildContext context, Specialist specialist) => Row(
        children: [
          _buildAvatar(specialist),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specialist.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildTypeBadge(context),
              ],
            ),
          ),
          _buildScoreChip(context),
        ],
      );

  Widget _buildAvatar(Specialist specialist) => CircleAvatar(
        radius: 24,
        backgroundImage: specialist.avatarUrl != null
            ? NetworkImage(specialist.avatarUrl!)
            : null,
        child: specialist.avatarUrl == null
            ? Text(
                specialist.name.isNotEmpty
                    ? specialist.name[0].toUpperCase()
                    : '?',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            : null,
      );

  Widget _buildCompactAvatar(Specialist specialist) => CircleAvatar(
        radius: 20,
        backgroundImage: specialist.avatarUrl != null
            ? NetworkImage(specialist.avatarUrl!)
            : null,
        child: specialist.avatarUrl == null
            ? Text(
                specialist.name.isNotEmpty
                    ? specialist.name[0].toUpperCase()
                    : '?',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              )
            : null,
      );

  Widget _buildTypeBadge(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getTypeColor(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _getTypeColor(context).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(recommendation.type.icon,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              recommendation.type.displayName,
              style: TextStyle(
                fontSize: 12,
                color: _getTypeColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildCompactTypeBadge(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getTypeColor(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(recommendation.type.icon,
            style: const TextStyle(fontSize: 10)),
      );

  Widget _buildScoreChip(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getScoreColor(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${(recommendation.score * 100).toInt()}%',
          style: TextStyle(
              fontSize: 12,
              color: _getScoreColor(context),
              fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildSpecialistInfo(BuildContext context, Specialist specialist) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                specialist.category?.displayName ?? 'Категория',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Icon(Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  specialist.location ?? 'Не указано',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              _buildRating(context, specialist),
              const SizedBox(width: 16),
              _buildPrice(context, specialist),
              const SizedBox(width: 16),
              _buildBookings(specialist),
            ],
          ),
        ],
      );

  Widget _buildCompactName(Specialist specialist) => Text(
        specialist.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildCompactRating(Specialist specialist) => Row(
        children: [
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            specialist.rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      );

  Widget _buildCompactPrice(Specialist specialist) => Text(
        specialist.priceRangeString ?? 'Цена не указана',
        style: TextStyle(
            fontSize: 12,
            color: Colors.green[700],
            fontWeight: FontWeight.w500),
      );

  Widget _buildRating(BuildContext context, Specialist specialist) => Row(
        children: [
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            specialist.rating.toStringAsFixed(1),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            ' (${specialist.totalReviews} отзывов)',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      );

  Widget _buildPrice(BuildContext context, Specialist specialist) => Row(
        children: [
          Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
          const SizedBox(width: 4),
          Text(
            specialist.priceRangeString ?? 'Цена не указана',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
                color: Colors.green[700], fontWeight: FontWeight.w500),
          ),
        ],
      );

  Widget _buildBookings(Specialist specialist) => Row(
        children: [
          Icon(Icons.event, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${specialist.totalBookings ?? 0} заказов',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      );

  Widget _buildReason(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline,
                size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recommendation.reason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ),
      );

  Widget _buildActions(BuildContext context) => Row(
        children: [
          Expanded(
            child: OutlinedButton(
                onPressed: onTap, child: const Text('Подробнее')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
                onPressed: onBook, child: const Text('Забронировать')),
          ),
        ],
      );

  Color _getTypeColor(BuildContext context) {
    switch (recommendation.type) {
      case RecommendationType.basedOnHistory:
        return Colors.blue;
      case RecommendationType.popular:
        return Colors.orange;
      case RecommendationType.categoryBased:
        return Colors.green;
      case RecommendationType.similarUsers:
        return Colors.purple;
      case RecommendationType.trending:
        return Colors.red;
      case RecommendationType.nearby:
        return Colors.teal;
      case RecommendationType.similarSpecialists:
        return Colors.indigo;
      case RecommendationType.popularInCategory:
        return Colors.amber;
      case RecommendationType.recentlyViewed:
        return Colors.cyan;
      case RecommendationType.priceRange:
        return Colors.brown;
      case RecommendationType.availability:
        return Colors.lime;
    }
  }

  Color _getScoreColor(BuildContext context) {
    if (recommendation.score >= 0.8) {
      return Colors.green;
    }
    if (recommendation.score >= 0.6) {
      return Colors.orange;
    }
    return Colors.red;
  }
}
