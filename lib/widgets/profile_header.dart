import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';

/// Заголовок профиля с аватаром, именем и кнопками действий
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.isOwnProfile = false,
    this.onFollow,
    this.onMessage,
  });
  final UserProfile profile;
  final bool isOwnProfile;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Аватар
              _buildAvatar(theme),
              const SizedBox(width: 16),
              // Информация о пользователе
              Expanded(child: _buildUserInfo(theme)),
            ],
          ),
          const SizedBox(height: 16),
          // Биография
          if (profile.bio.isNotEmpty) ...[
            _buildBio(theme),
            const SizedBox(height: 16)
          ],
          // Кнопки действий
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) => Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.primaryColor, width: 2),
            ),
            child: ClipOval(
              child: profile.avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: profile.avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: theme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: theme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : Container(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: theme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
            ),
          ),
          // Индикатор верификации
          if (profile.isVerified)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    const Icon(Icons.verified, color: Colors.white, size: 16),
              ),
            ),
        ],
      );

  Widget _buildUserInfo(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Имя и роль
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.isVerified)
                const Icon(Icons.verified, color: Colors.blue, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          // Роль
          Text(
            profile.roleDisplayName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Город
          if (profile.city.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    profile.city,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      );

  Widget _buildBio(ThemeData theme) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Text(
          profile.bio,
          style: theme.textTheme.bodyMedium,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );

  Widget _buildActionButtons(ThemeData theme) {
    if (isOwnProfile) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO(developer): Редактировать профиль
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Редактировать'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO(developer): Настройки
              },
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Настройки'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onFollow,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Подписаться'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMessage,
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Сообщение'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    }
  }
}
