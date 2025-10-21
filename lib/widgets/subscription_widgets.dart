import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_template.dart';
import '../models/subscription.dart';
import '../models/subscription_notification.dart';
import '../providers/subscription_providers.dart';

/// Виджет кнопки подписки
class SubscribeButton extends ConsumerStatefulWidget {
  const SubscribeButton({
    super.key,
    required this.specialistId,
    required this.specialistName,
    this.specialistPhotoUrl,
    required this.userId,
    this.onSubscriptionChanged,
  });
  final String specialistId;
  final String specialistName;
  final String? specialistPhotoUrl;
  final String userId;
  final VoidCallback? onSubscriptionChanged;

  @override
  ConsumerState<SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends ConsumerState<SubscribeButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isSubscribedAsync = ref.watch(
      isSubscribedProvider(
        IsSubscribedParams(userId: widget.userId, specialistId: widget.specialistId),
      ),
    );

    return isSubscribedAsync.when(
      data: (isSubscribed) => ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _toggleSubscription(isSubscribed),
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isSubscribed ? Icons.person_remove : Icons.person_add),
        label: Text(isSubscribed ? 'Отписаться' : 'Подписаться'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSubscribed ? Colors.grey : Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) =>
          TextButton(onPressed: () => _toggleSubscription(false), child: const Text('Подписаться')),
    );
  }

  Future<void> _toggleSubscription(bool isSubscribed) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(subscriptionServiceProvider);

      if (isSubscribed) {
        await service.unsubscribeFromSpecialist(widget.userId, widget.specialistId);
      } else {
        await service.subscribeToSpecialist(
          userId: widget.userId,
          specialistId: widget.specialistId,
          specialistName: widget.specialistName,
          specialistPhotoUrl: widget.specialistPhotoUrl ?? '',
        );
      }

      // Обновляем состояние
      ref.invalidate(
        isSubscribedProvider(
          IsSubscribedParams(userId: widget.userId, specialistId: widget.specialistId),
        ),
      );

      widget.onSubscriptionChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSubscribed ? 'Отписались от специалиста' : 'Подписались на специалиста',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Виджет списка подписок
class SubscriptionsListWidget extends ConsumerWidget {
  const SubscriptionsListWidget({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(userSubscriptionsProvider(userId));

    return subscriptionsAsync.when(
      data: (subscriptions) {
        if (subscriptions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Нет подписок', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text(
                  'Подпишитесь на специалистов, чтобы видеть их посты',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            final subscription = subscriptions[index];
            return SubscriptionTile(
              subscription: subscription,
              onUnsubscribe: () => _unsubscribe(ref, subscription),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки подписок', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(userSubscriptionsProvider(userId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unsubscribe(WidgetRef ref, Subscription subscription) async {
    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.unsubscribeFromSpecialist(
        subscription.userId,
        subscription.userId, // Используем userId как specialistId
      );

      ref.invalidate(userSubscriptionsProvider(subscription.userId));
    } catch (e) {
      // Обработка ошибки
    }
  }
}

/// Виджет элемента подписки
class SubscriptionTile extends StatelessWidget {
  const SubscriptionTile({super.key, required this.subscription, this.onUnsubscribe});
  final Subscription subscription;
  final VoidCallback? onUnsubscribe;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text('Подписка ${subscription.plan.toString().split('.').last}'),
        subtitle: Text('Подписан с ${_formatDate(subscription.startedAt)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'unsubscribe':
                onUnsubscribe?.call();
                break;
              case 'view_profile':
                // TODO(developer): Перейти к профилю специалиста
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_profile',
              child: Row(
                  children: [Icon(Icons.person, size: 20), SizedBox(width: 8), Text('Профиль')]),
            ),
            const PopupMenuItem(
              value: 'unsubscribe',
              child: Row(
                children: [
                  Icon(Icons.person_remove, size: 20),
                  SizedBox(width: 8),
                  Text('Отписаться')
                ],
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}

/// Виджет уведомлений о подписках
class SubscriptionNotificationsWidget extends ConsumerWidget {
  const SubscriptionNotificationsWidget({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider(userId));

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Нет уведомлений', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return NotificationTile(
              notification: notification,
              onTap: () => _handleNotificationTap(context, ref, notification),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Ошибка: $error')),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    SubscriptionNotification notification,
  ) async {
    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.markNotificationAsRead(notification.id);

      // TODO(developer): Перейти к соответствующему экрану
      switch (notification.type) {
        case NotificationType.system:
          // Перейти к системному уведомлению
          break;
        case NotificationType.promotion:
          // Перейти к промо
          break;
        case NotificationType.booking:
          // Перейти к бронированию
          break;
        case NotificationType.payment:
          // Перейти к платежу
          break;
        case NotificationType.security:
          // Перейти к настройкам безопасности
          break;
        case NotificationType.review:
          // Перейти к отзыву
          break;
        case NotificationType.cancellation:
          // Перейти к отмененному событию
          break;
        case NotificationType.message:
          // Перейти к сообщению
          break;
        case NotificationType.reminder:
          // Показать напоминание
          break;
        case NotificationType.general:
          // Показать общее уведомление
          break;
      }
    } catch (e) {
      // Обработка ошибки
    }
  }
}

/// Виджет элемента уведомления
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, this.onTap});
  final SubscriptionNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundImage: notification.specialistPhotoUrl != null
              ? CachedNetworkImageProvider(notification.specialistPhotoUrl!)
              : null,
          child: notification.specialistPhotoUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(notification.title),
        subtitle: Text(notification.body),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTimeAgo(notification.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              ),
          ],
        ),
        onTap: onTap,
      );

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }
}
