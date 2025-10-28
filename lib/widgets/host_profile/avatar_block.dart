import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_marketplace_app/models/host_profile.dart';
import 'package:flutter/material.dart';

/// Компонент блока с аватаром ведущего
class AvatarBlock extends StatelessWidget {
  const AvatarBlock({required this.host, super.key, this.onPhotoTap});
  final HostProfile host;
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Аватар
          GestureDetector(
            onTap: onPhotoTap,
            child: Container(
              width: isMobile ? 120 : 150,
              height: isMobile ? 120 : 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.primaryColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: host.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: host.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => ColoredBox(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            size: isMobile ? 60 : 75,
                            color: theme.primaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => ColoredBox(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            size: isMobile ? 60 : 75,
                            color: theme.primaryColor,
                          ),
                        ),
                      )
                    : ColoredBox(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          size: isMobile ? 60 : 75,
                          color: theme.primaryColor,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Имя и фамилия
          Text(
            host.fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Город и верификация
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                host.city,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (host.isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        'Верифицирован',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Рейтинг
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  host.rating.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${host.totalReviews} отзывов)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
