import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/user.dart';

/// Виджет заголовка профиля
class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key, required this.user, required this.isCurrentUser});

  final AppUser user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Аватар
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                child: user.avatarUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user.avatarUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 100,
                            height: 100,
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.person, size: 50, color: theme.primaryColor),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 100,
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.person, size: 50, color: theme.primaryColor),
                          ),
                        ),
                      )
                    : Icon(Icons.person, size: 50, color: theme.primaryColor),
              ),
              if (user.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.cardColor, width: 2),
                    ),
                    child: const Icon(Icons.verified, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Имя пользователя
          Text(
            user.displayName ?? user.email.split('@').first,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Роль
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.roleDisplayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (user.city != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  user.city!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],

          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(user.bio!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],

          // Специализации (для специалистов)
          if (user.isSpecialist && user.specialties.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: user.specialties
                  .take(3)
                  .map(
                    (specialty) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        specialty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
