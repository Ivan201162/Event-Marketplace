import 'package:flutter/material.dart';

import '../models/recommendation.dart';
import 'recommendation_card.dart';

/// Секция с рекомендациями
class RecommendationSection extends StatelessWidget {
  const RecommendationSection({
    super.key,
    required this.title,
    required this.recommendations,
    this.subtitle,
    this.icon,
    this.onViewAll,
    this.onRecommendationTap,
    this.onRecommendationBook,
    this.maxItems = 6,
    this.showViewAllButton = true,
    this.compact = false,
  });

  final String title;
  final List<Recommendation> recommendations;
  final String? subtitle;
  final String? icon;
  final VoidCallback? onViewAll;
  final void Function(Recommendation)? onRecommendationTap;
  final void Function(Recommendation)? onRecommendationBook;
  final int maxItems;
  final bool showViewAllButton;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayRecommendations = recommendations.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        if (compact)
          _buildCompactList(context, displayRecommendations)
        else
          _buildFullList(context, displayRecommendations),
        if (showViewAllButton && recommendations.length > maxItems) ...[
          const SizedBox(height: 16),
          _buildViewAllButton(context),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Text(
                icon!,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFullList(
    BuildContext context,
    List<Recommendation> recommendations,
  ) =>
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = recommendations[index];
          return RecommendationCard(
            recommendation: recommendation,
            onTap: () => onRecommendationTap?.call(recommendation),
            onBook: () => onRecommendationBook?.call(recommendation),
          );
        },
      );

  Widget _buildCompactList(
    BuildContext context,
    List<Recommendation> recommendations,
  ) =>
      SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final recommendation = recommendations[index];
            return SizedBox(
              width: 280,
              child: RecommendationCard(
                recommendation: recommendation,
                compact: true,
                onTap: () => onRecommendationTap?.call(recommendation),
                onBook: () => onRecommendationBook?.call(recommendation),
              ),
            );
          },
        ),
      );

  Widget _buildViewAllButton(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onViewAll,
            child: Text('Смотреть все (${recommendations.length})'),
          ),
        ),
      );
}

/// Виджет для отображения горизонтального списка рекомендаций
class HorizontalRecommendationList extends StatelessWidget {
  const HorizontalRecommendationList({
    super.key,
    required this.recommendations,
    this.onRecommendationTap,
    this.onRecommendationBook,
    this.height = 140,
  });

  final List<Recommendation> recommendations;
  final void Function(Recommendation)? onRecommendationTap;
  final void Function(Recommendation)? onRecommendationBook;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = recommendations[index];
          return SizedBox(
            width: 200,
            child: Card(
              margin: const EdgeInsets.only(right: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => onRecommendationTap?.call(recommendation),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(recommendation.specialist),
                      const SizedBox(height: 8),
                      _buildName(recommendation.specialist),
                      const SizedBox(height: 4),
                      _buildRating(recommendation.specialist),
                      const SizedBox(height: 4),
                      _buildPrice(recommendation.specialist),
                      const Spacer(),
                      _buildTypeBadge(context, recommendation),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(dynamic specialist) => CircleAvatar(
        radius: 20,
        backgroundImage: specialist.avatarUrl != null
            ? NetworkImage(specialist.avatarUrl as String)
            : null,
        child: specialist.avatarUrl == null
            ? Text(
                (specialist.name as String).isNotEmpty
                    ? (specialist.name as String)[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      );

  Widget _buildName(dynamic specialist) => Text(
        specialist.name as String,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildRating(dynamic specialist) => Row(
        children: [
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            (specialist.rating as num).toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _buildPrice(dynamic specialist) => Text(
        specialist.priceRangeString as String,
        style: TextStyle(
          fontSize: 12,
          color: Colors.green[700],
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _buildTypeBadge(BuildContext context, Recommendation recommendation) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getTypeColor(context, recommendation.type)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          recommendation.type.icon,
          style: const TextStyle(fontSize: 10),
        ),
      );

  Color _getTypeColor(BuildContext context, RecommendationType type) {
    switch (type) {
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
}
