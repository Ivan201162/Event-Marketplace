import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/customer_profile.dart';
import '../services/customer_profile_service.dart';

/// Заголовок профиля заказчика
class CustomerProfileHeader extends ConsumerWidget {
  const CustomerProfileHeader({
    super.key,
    required this.customerId,
    this.isOwnProfile = false,
    this.onEditProfile,
  });

  final String customerId;
  final bool isOwnProfile;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return FutureBuilder<CustomerProfile?>(
      future: ref.read(customerProfileServiceProvider).getCustomerProfile(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('Профиль не найден'),
          );
        }

        final profile = snapshot.data!;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аватар
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: profile.avatarUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: profile.avatarUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    size: 50,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: theme.colorScheme.primary,
                              ),
                      ),
                      if (profile.isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Информация о заказчике
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Имя и возраст
                        Row(
                          children: [
                            Text(
                              profile.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (profile.age != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${profile.age} лет',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Семейный статус
                        if (profile.maritalStatus != null) ...[
                          Row(
                            children: [
                              Icon(
                                _getMaritalStatusIcon(profile.maritalStatus!),
                                size: 16,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getMaritalStatusText(profile.maritalStatus!),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        // Местоположение
                        if (profile.location != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  profile.location!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        // Статус активности
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: profile.isActive ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profile.isActive ? 'Активен' : 'Был в сети ${_getLastSeen(profile.lastActiveAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Описание
              if (profile.bio != null) ...[
                Text(
                  profile.bio!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              
              // Кнопка редактирования
              if (isOwnProfile)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(Icons.edit),
                    label: const Text('Редактировать профиль'),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Дополнительная информация
              _buildAdditionalInfo(context, profile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, CustomerProfile profile) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  'Заказов',
                  '${profile.totalOrders}',
                  Icons.shopping_bag,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  'Потрачено',
                  '${profile.totalSpent.toStringAsFixed(0)} ₽',
                  Icons.attach_money,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  'Семья',
                  '${profile.familyMembers.length} чел.',
                  Icons.family_restroom,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  'Даты',
                  '${profile.importantDates.length}',
                  Icons.event,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getMaritalStatusIcon(MaritalStatus status) {
    switch (status) {
      case MaritalStatus.single:
        return Icons.person;
      case MaritalStatus.married:
        return Icons.favorite;
      case MaritalStatus.divorced:
        return Icons.person_off;
      case MaritalStatus.widowed:
        return Icons.person_remove;
      case MaritalStatus.inRelationship:
        return Icons.favorite_border;
    }
  }

  String _getMaritalStatusText(MaritalStatus status) {
    switch (status) {
      case MaritalStatus.single:
        return 'Холост/не замужем';
      case MaritalStatus.married:
        return 'Женат/замужем';
      case MaritalStatus.divorced:
        return 'Разведен/разведена';
      case MaritalStatus.widowed:
        return 'Вдовец/вдова';
      case MaritalStatus.inRelationship:
        return 'В отношениях';
    }
  }

  String _getLastSeen(DateTime? lastActiveAt) {
    if (lastActiveAt == null) return 'давно';
    
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'только что';
    }
  }
}
