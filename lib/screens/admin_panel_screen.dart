import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_panel.dart';
import '../services/admin_panel_service.dart';
import 'admin_users_screen.dart';
import 'admin_specialists_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_analytics_screen.dart';

/// Главный экран админ-панели
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with TickerProviderStateMixin {
  final AdminPanelService _adminService = AdminPanelService();
  late TabController _tabController;
  AdminStats? _stats;
  AdminPanel? _adminInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // TODO: Получить ID текущего пользователя
      final currentUserId = 'demo_admin_id';
      
      final futures = await Future.wait([
        _adminService.getAdminInfo(currentUserId),
        _adminService.getStats(),
      ]);

      setState(() {
        _adminInfo = futures[0] as AdminPanel?;
        _stats = futures[1] as AdminStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки данных: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_adminInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Доступ запрещен')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'У вас нет прав доступа к админ-панели',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Админ-панель (${_adminInfo!.adminName})'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Обзор', icon: Icon(Icons.dashboard)),
            Tab(text: 'Пользователи', icon: Icon(Icons.people)),
            Tab(text: 'Специалисты', icon: Icon(Icons.business)),
            Tab(text: 'Бронирования', icon: Icon(Icons.event)),
            Tab(text: 'Платежи', icon: Icon(Icons.payment)),
            Tab(text: 'Отзывы', icon: Icon(Icons.star)),
            Tab(text: 'Аналитика', icon: Icon(Icons.analytics)),
            Tab(text: 'Настройки', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Профиль'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Выйти'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          const AdminUsersScreen(),
          const AdminSpecialistsScreen(),
          const AdminBookingsScreen(),
          const AdminPaymentsScreen(),
          const AdminReviewsScreen(),
          const AdminAnalyticsScreen(),
          const AdminSettingsScreen(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Приветствие
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      _adminInfo!.adminName.isNotEmpty 
                          ? _adminInfo!.adminName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Добро пожаловать, ${_adminInfo!.adminName}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Роль: ${_getRoleText(_adminInfo!.role)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Статистика
          Text(
            'Общая статистика',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Карточки статистики
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Пользователи',
                _stats!.totalUsers.toString(),
                Icons.people,
                Colors.blue,
                subtitle: 'Активных: ${_stats!.activeUsers}',
              ),
              _buildStatCard(
                'Специалисты',
                _stats!.totalSpecialists.toString(),
                Icons.business,
                Colors.green,
              ),
              _buildStatCard(
                'Бронирования',
                _stats!.totalBookings.toString(),
                Icons.event,
                Colors.orange,
                subtitle: 'Ожидают: ${_stats!.pendingBookings}',
              ),
              _buildStatCard(
                'Платежи',
                _stats!.totalPayments.toString(),
                Icons.payment,
                Colors.purple,
                subtitle: 'Доход: ${_stats!.totalRevenue.toStringAsFixed(0)} ₽',
              ),
              _buildStatCard(
                'Отзывы',
                _stats!.totalReviews.toString(),
                Icons.star,
                Colors.amber,
                subtitle: 'На модерации: ${_stats!.pendingReviews}',
              ),
              _buildStatCard(
                'Заблокированные',
                _stats!.bannedUsers.toString(),
                Icons.block,
                Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Быстрые действия
          Text(
            'Быстрые действия',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard(
                'Модерация отзывов',
                Icons.rate_review,
                Colors.amber,
                () => _tabController.animateTo(5),
              ),
              _buildActionCard(
                'Верификация специалистов',
                Icons.verified,
                Colors.green,
                () => _tabController.animateTo(2),
              ),
              _buildActionCard(
                'Управление пользователями',
                Icons.people_alt,
                Colors.blue,
                () => _tabController.animateTo(1),
              ),
              _buildActionCard(
                'Настройки системы',
                Icons.settings,
                Colors.grey,
                () => _tabController.animateTo(7),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Последние действия
          Text(
            'Последние действия',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<List<AdminAction>>(
            stream: _adminService.getAdminActions(limit: 10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final actions = snapshot.data ?? [];
              if (actions.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Нет последних действий'),
                  ),
                );
              }

              return Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return ListTile(
                      leading: Icon(_getActionIcon(action.type)),
                      title: Text(action.description),
                      subtitle: Text(
                        '${action.adminName} • ${_formatDate(action.timestamp)}',
                      ),
                      trailing: Text(
                        _getActionTypeText(action.type),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleText(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Супер-администратор';
      case AdminRole.admin:
        return 'Администратор';
      case AdminRole.moderator:
        return 'Модератор';
      case AdminRole.support:
        return 'Поддержка';
    }
  }

  IconData _getActionIcon(AdminActionType type) {
    switch (type) {
      case AdminActionType.userBanned:
        return Icons.block;
      case AdminActionType.userUnbanned:
        return Icons.check_circle;
      case AdminActionType.specialistVerified:
        return Icons.verified;
      case AdminActionType.specialistUnverified:
        return Icons.cancel;
      case AdminActionType.bookingCancelled:
        return Icons.event_busy;
      case AdminActionType.reviewModerated:
        return Icons.rate_review;
      case AdminActionType.settingsUpdated:
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  String _getActionTypeText(AdminActionType type) {
    switch (type) {
      case AdminActionType.userBanned:
        return 'Блокировка';
      case AdminActionType.userUnbanned:
        return 'Разблокировка';
      case AdminActionType.specialistVerified:
        return 'Верификация';
      case AdminActionType.specialistUnverified:
        return 'Отмена верификации';
      case AdminActionType.bookingCancelled:
        return 'Отмена бронирования';
      case AdminActionType.reviewModerated:
        return 'Модерация';
      case AdminActionType.settingsUpdated:
        return 'Настройки';
      default:
        return 'Другое';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Сегодня в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        _showProfileDialog();
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Профиль администратора'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Имя: ${_adminInfo!.adminName}'),
            Text('Роль: ${_getRoleText(_adminInfo!.role)}'),
            Text('Разрешения: ${_adminInfo!.permissions.length}'),
            Text('Последний вход: ${_formatDate(_adminInfo!.lastLogin)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из админ-панели?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Реализовать выход
              _showInfoSnackBar('Выход из админ-панели');
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
