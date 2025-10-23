import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/specialist.dart';

/// Карточка ведущего для отображения в списке
class HostCard extends StatelessWidget {
  const HostCard({super.key, required this.specialist, this.onTap});
  final Specialist specialist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото ведущего
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  color: theme.colorScheme.surface,
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: specialist.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: specialist.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.primaryColor),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person,
                              size: isMobile ? 40 : 60,
                              color: theme.primaryColor,
                            ),
                          ),
                        )
                      : Container(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            size: isMobile ? 40 : 60,
                            color: theme.primaryColor,
                          ),
                        ),
                ),
              ),
            ),

            // Информация о ведущем
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя и верификация
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            specialist.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 12 : 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (specialist.isVerified)
                          Icon(Icons.verified,
                              size: isMobile ? 14 : 16, color: Colors.green),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Город
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: isMobile ? 12 : 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            specialist.city,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: isMobile ? 10 : 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Рейтинг
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: isMobile ? 12 : 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          specialist.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 10 : 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${specialist.totalReviews})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: isMobile ? 9 : 11,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Ценовой диапазон
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                        vertical: isMobile ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${specialist.pricePerHour} ₽/час',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                          fontSize: isMobile ? 9 : 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
