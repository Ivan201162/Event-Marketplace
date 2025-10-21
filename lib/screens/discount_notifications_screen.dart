import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discount_notification.dart';
import '../providers/auth_providers.dart';
import '../services/discount_notification_service.dart';
import '../widgets/discount_notification_card.dart';

/// Экран уведомлений о скидках
class DiscountNotificationsScreen extends ConsumerStatefulWidget {
  const DiscountNotificationsScreen({super.key});

  @override
  ConsumerState<DiscountNotificationsScreen> createState() => _DiscountNotificationsScreenState();
}

class _DiscountNotificationsScreenState extends ConsumerState<DiscountNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DiscountNotificationService _notificationService = DiscountNotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления о скидках'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.watchUnreadCount(currentUser.value?.uid ?? ''),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(currentUser.value?.uid ?? ''),
            tooltip: 'Отметить все как прочитанные',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Новые'),
            Tab(text: 'Все'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnreadNotifications(currentUser.value?.uid ?? ''),
          _buildAllNotifications(currentUser.value?.uid ?? ''),
        ],
      ),
    );
  }

  Widget _buildUnreadNotifications(String userId) => StreamBuilder<List<DiscountNotification>>(
    stream: _notificationService.watchUnreadCustomerNotifications(userId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: ${snapshot.error}'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => setState(() {}), child: const Text('Повторить')),
            ],
          ),
        );
      }

      final notifications = snapshot.data ?? [];

      if (notifications.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Нет новых уведомлений', style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text(
                'Когда специалисты предложат скидки, они появятся здесь',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return DiscountNotificationCard(
              notification: notification,
              onRead: () {
                setState(() {});
              },
              onDelete: () {
                setState(() {});
              },
            );
          },
        ),
      );
    },
  );

  Widget _buildAllNotifications(String userId) => StreamBuilder<List<DiscountNotification>>(
    stream: _notificationService.watchCustomerNotifications(userId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: ${snapshot.error}'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => setState(() {}), child: const Text('Повторить')),
            ],
          ),
        );
      }

      final notifications = snapshot.data ?? [];

      if (notifications.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Нет уведомлений о скидках', style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text(
                'Уведомления о скидках от специалистов будут отображаться здесь',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return DiscountNotificationCard(
              notification: notification,
              onRead: () {
                setState(() {});
              },
              onDelete: () {
                setState(() {});
              },
              showActions: !notification.isRead,
            );
          },
        ),
      );
    },
  );

  Future<void> _markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Все уведомления отмечены как прочитанные'),
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
    }
  }
}
