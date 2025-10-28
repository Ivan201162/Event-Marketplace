import 'package:event_marketplace_app/models/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Виджет действий профиля
class ProfileActionsWidget extends StatelessWidget {
  const ProfileActionsWidget(
      {required this.user, required this.isCurrentUser, super.key,});

  final AppUser user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isCurrentUser) ...[
            // Действия для текущего пользователя
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _editProfile(context),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Редактировать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareProfile(context),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Поделиться'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),),
                ),
              ),
            ),
          ] else ...[
            // Действия для других пользователей
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _sendMessage(context),
                icon: const Icon(Icons.message, size: 18),
                label: const Text('Написать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _followUser(context),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Подписаться'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editProfile(BuildContext context) {
    context.push('/profile/edit');
  }

  void _shareProfile(BuildContext context) {
    // TODO: Реализовать шаринг профиля
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Функция шаринга будет добавлена позже')),);
  }

  void _sendMessage(BuildContext context) {
    // TODO: Реализовать отправку сообщения
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(
        content: Text('Функция сообщений будет добавлена позже'),),);
  }

  void _followUser(BuildContext context) {
    // TODO: Реализовать подписку на пользователя
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(
        content: Text('Функция подписки будет добавлена позже'),),);
  }
}
