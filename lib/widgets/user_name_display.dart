import 'package:event_marketplace_app/models/app_user.dart';
import 'package:flutter/material.dart';

/// Виджет для отображения имени пользователя
/// Если есть username → первая строка: @username (крупно), ниже Имя Фамилия (меньше)
/// Если нет username → одна строка: Имя Фамилия (крупно)
class UserNameDisplay extends StatelessWidget {
  const UserNameDisplay({
    required this.user,
    this.mainStyle,
    this.secondaryStyle,
    this.usernameStyle,
    super.key,
  });

  final AppUser user;
  final TextStyle? mainStyle;
  final TextStyle? secondaryStyle;
  final TextStyle? usernameStyle;

  @override
  Widget build(BuildContext context) {
    final hasUsername = user.username != null && user.username!.isNotEmpty;
    final name = '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim();
    final displayName = name.isEmpty
        ? (user.email ?? user.name ?? 'Пользователь')
        : name;

    if (hasUsername) {
      // С username: @username крупно, ниже Имя Фамилия меньше
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '@${user.username}',
            style: usernameStyle ??
                mainStyle ??
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            displayName,
            style: secondaryStyle ??
                TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
          ),
        ],
      );
    } else {
      // Без username: одна строка Имя Фамилия крупно
      return Text(
        displayName,
        style: mainStyle ??
            const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
      );
    }
  }
}

