import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Виджет для отображения счетчика непрочитанных уведомлений
class NotificationBadgeWidget extends StatelessWidget {
  const NotificationBadgeWidget({
    super.key,
    required this.userId,
    required this.child,
    this.onTap,
  });

  final String userId;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => FutureBuilder<int>(
        future: NotificationService.getUnreadCount(userId),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;

          return GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                child,
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

/// Виджет иконки уведомлений с бейджем
class NotificationIconWidget extends StatelessWidget {
  const NotificationIconWidget({
    super.key,
    required this.userId,
    this.onTap,
    this.icon = Icons.notifications,
    this.size = 24,
  });

  final String userId;
  final VoidCallback? onTap;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => NotificationBadgeWidget(
        userId: userId,
        onTap: onTap,
        child: Icon(
          icon,
          size: size,
        ),
      );
}

/// Виджет кнопки уведомлений с бейджем
class NotificationButtonWidget extends StatelessWidget {
  const NotificationButtonWidget({
    super.key,
    required this.userId,
    this.onTap,
    this.icon = Icons.notifications,
    this.label = 'Уведомления',
  });

  final String userId;
  final VoidCallback? onTap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => NotificationBadgeWidget(
        userId: userId,
        onTap: onTap,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
}
