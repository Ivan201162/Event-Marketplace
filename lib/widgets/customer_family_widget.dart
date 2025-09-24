import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/customer_profile.dart';
import '../services/customer_profile_service.dart';

/// Виджет семьи заказчика
class CustomerFamilyWidget extends ConsumerWidget {
  const CustomerFamilyWidget({
    super.key,
    required this.customerId,
    this.isOwnProfile = false,
    this.onAddFamilyMember,
    this.onEditFamilyMember,
    this.onRemoveFamilyMember,
  });

  final String customerId;
  final bool isOwnProfile;
  final VoidCallback? onAddFamilyMember;
  final Function(String)? onEditFamilyMember;
  final Function(String)? onRemoveFamilyMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return StreamBuilder<CustomerProfile?>(
      stream: ref.read(customerProfileServiceProvider).getCustomerProfile(customerId),
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
        final familyMembers = profile.familyMembers;
        
        return Column(
          children: [
            // Заголовок с кнопкой добавления
            if (isOwnProfile)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Моя семья',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onAddFamilyMember,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить'),
                    ),
                  ],
                ),
              ),
            
            // Список членов семьи
            if (familyMembers.isEmpty)
              _buildEmptyState(context, theme)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: familyMembers.length,
                itemBuilder: (context, index) {
                  final member = familyMembers[index];
                  return _buildFamilyMemberItem(context, theme, member);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.family_restroom,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            isOwnProfile ? 'Добавьте членов семьи' : 'Информация о семье не указана',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isOwnProfile 
                ? 'Добавьте информацию о членах семьи для персонализации сервиса'
                : 'Заказчик еще не добавил информацию о семье',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          if (isOwnProfile) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddFamilyMember,
              icon: const Icon(Icons.add),
              label: const Text('Добавить члена семьи'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilyMemberItem(BuildContext context, ThemeData theme, FamilyMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Аватар члена семьи
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: member.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: member.avatarUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(
                          _getRelationshipIcon(member.relationship),
                          color: theme.colorScheme.primary,
                          size: 30,
                        ),
                      ),
                    )
                  : Icon(
                      _getRelationshipIcon(member.relationship),
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
            ),
            
            const SizedBox(width: 16),
            
            // Информация о члене семьи
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRelationshipText(member.relationship),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (member.age != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${member.age} лет',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                  if (member.notes != null && member.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      member.notes!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Кнопки действий
            if (isOwnProfile)
              PopupMenuButton<String>(
                onSelected: (value) => _handleMemberAction(value, member),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Удалить', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  IconData _getRelationshipIcon(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'spouse':
      case 'супруг':
      case 'супруга':
        return Icons.favorite;
      case 'child':
      case 'ребенок':
      case 'дети':
        return Icons.child_care;
      case 'parent':
      case 'родитель':
      case 'мать':
      case 'отец':
        return Icons.elderly;
      case 'sibling':
      case 'брат':
      case 'сестра':
        return Icons.people;
      case 'grandparent':
      case 'бабушка':
      case 'дедушка':
        return Icons.elderly_woman;
      default:
        return Icons.person;
    }
  }

  String _getRelationshipText(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'spouse':
        return 'Супруг/супруга';
      case 'child':
        return 'Ребенок';
      case 'parent':
        return 'Родитель';
      case 'sibling':
        return 'Брат/сестра';
      case 'grandparent':
        return 'Бабушка/дедушка';
      default:
        return relationship;
    }
  }

  void _handleMemberAction(String action, FamilyMember member) {
    switch (action) {
      case 'edit':
        onEditFamilyMember?.call(member.id);
        break;
      case 'delete':
        _showDeleteConfirmation(member);
        break;
    }
  }

  void _showDeleteConfirmation(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить члена семьи'),
        content: Text('Вы уверены, что хотите удалить ${member.name} из списка семьи?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemoveFamilyMember?.call(member.id);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
