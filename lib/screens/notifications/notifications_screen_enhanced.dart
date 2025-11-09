import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Провайдер уведомлений
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return <String, dynamic>{
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
});

/// Экран уведомлений
class NotificationsScreenEnhanced extends ConsumerStatefulWidget {
  const NotificationsScreenEnhanced({super.key});

  @override
  ConsumerState<NotificationsScreenEnhanced> createState() => _NotificationsScreenEnhancedState();
}

class _NotificationsScreenEnhancedState extends ConsumerState<NotificationsScreenEnhanced> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("NOTIFICATIONS_OPENED");
    });
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("NOTIF_OPENED");
    });
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;
    final targetId = notification['targetId'] as String?;
    final targetType = notification['targetType'] as String?;

    debugLog("NOTIF_TAP:$type:$targetId");

    if (targetId == null) return;

    switch (targetType) {
      case 'profile':
        context.push('/profile/$targetId');
        break;
      case 'request':
        context.push('/requests/$targetId');
        break;
      case 'chat':
        context.push('/chat/$targetId');
        break;
      default:
        break;
    }

    // Помечаем как прочитанное
    if (notification['id'] != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification['id'])
          .update({'seen': true});
    }
  }

  Future<void> _refresh() async {
    try {
      ref.invalidate(notificationsProvider);
      await Future.delayed(const Duration(milliseconds: 500));
      debugLog("REFRESH_OK:notifications");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Обновлено'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugLog("REFRESH_ERR:notifications:$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Уведомления'),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Нет уведомлений',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _NotificationCard(
                    notification: notif,
                    onTap: () => _handleNotificationTap(notif),
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
                  Text('Ошибка загрузки: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(notificationsProvider),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] ?? 'Уведомление';
    final body = notification['body'] ?? '';
    final timestamp = notification['timestamp'] as Timestamp?;
    final seen = notification['seen'] ?? false;
    final type = notification['type'] as String?;

    IconData icon = Icons.notifications;
    if (type != null) {
      switch (type) {
        case 'follow':
          icon = Icons.person_add;
          break;
        case 'message':
          icon = Icons.message;
          break;
        case 'request':
          icon = Icons.assignment;
          break;
        case 'like':
          icon = Icons.favorite;
          break;
        default:
          icon = Icons.notifications;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: seen ? null : Colors.blue[50],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(icon, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: seen ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (timestamp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate()),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!seen)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

