import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../models/admin_user.dart';
import '../services/admin_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран админ-панели
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  int _selectedIndex = 0;
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
        largeDesktop: _buildLargeDesktopLayout(context),
      );

  Widget _buildMobileLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Админ-панель'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: _buildContent(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Панель',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Пользователи',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report),
              label: 'Жалобы',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Настройки',
            ),
          ],
        ),
      );

  Widget _buildTabletLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Админ-панель'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ResponsiveContainer(
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: _buildSidebar(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      );

  Widget _buildDesktopLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Админ-панель'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ResponsiveContainer(
          child: Row(
            children: [
              SizedBox(
                width: 250,
                child: _buildSidebar(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      );

  Widget _buildLargeDesktopLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Админ-панель'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ResponsiveContainer(
          child: Row(
            children: [
              SizedBox(
                width: 300,
                child: _buildSidebar(),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _buildContent(),
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 300,
                child: _buildRightPanel(),
              ),
            ],
          ),
        ),
      );

  Widget _buildSidebar() => ResponsiveCard(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const ResponsiveText(
              'Админ-панель',
              isTitle: true,
            ),
            const SizedBox(height: 24),
            _buildSidebarItem(0, Icons.dashboard, 'Панель управления'),
            _buildSidebarItem(1, Icons.people, 'Пользователи'),
            _buildSidebarItem(2, Icons.report, 'Жалобы'),
            _buildSidebarItem(3, Icons.settings, 'Настройки'),
          ],
        ),
      );

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
        ),
        title: ResponsiveText(
          title,
          style: TextStyle(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onTap: () => setState(() => _selectedIndex = index),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedTileColor:
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildUsersManagement();
      case 2:
        return _buildReportsManagement();
      case 3:
        return _buildSettings();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Панель управления',
              isTitle: true,
            ),
            const SizedBox(height: 24),

            // Статистика
            FutureBuilder<Map<String, int>>(
              future: _adminService.getUserStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }

                final stats = snapshot.data ?? {};
                return ResponsiveGrid(
                  children: [
                    _buildStatCard(
                      'Всего пользователей',
                      '${stats['total'] ?? 0}',
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Активных',
                      '${stats['active'] ?? 0}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Заблокированных',
                      '${stats['suspended'] ?? 0}',
                      Icons.block,
                      Colors.red,
                    ),
                    _buildStatCard(
                      'На рассмотрении',
                      '${stats['pending'] ?? 0}',
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      ResponsiveCard(
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            ResponsiveText(
              value,
              isTitle: true,
              style: TextStyle(color: color),
            ),
            const SizedBox(height: 4),
            ResponsiveText(
              title,
              isSubtitle: true,
            ),
          ],
        ),
      );

  Widget _buildUsersManagement() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ResponsiveText(
                  'Управление пользователями',
                  isTitle: true,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Реализовать поиск пользователей
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Поиск'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Список пользователей
            Expanded(
              child: FutureBuilder<List<ManagedUser>>(
                future: _adminService.getUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Ошибка: ${snapshot.error}');
                  }

                  final users = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(user);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildUserCard(ManagedUser user) => ResponsiveCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(user.firstName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ResponsiveText(
                    user.email,
                    isSubtitle: true,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(user.statusColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(user.statusColor)),
                    ),
                    child: ResponsiveText(
                      user.statusDescription,
                      style: TextStyle(
                        color: Color(user.statusColor),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleUserAction(value, user),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Text('Просмотр'),
                ),
                const PopupMenuItem(
                  value: 'ban',
                  child: Text('Заблокировать'),
                ),
                const PopupMenuItem(
                  value: 'unban',
                  child: Text('Разблокировать'),
                ),
                const PopupMenuItem(
                  value: 'verify',
                  child: Text('Верифицировать'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildReportsManagement() => const ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Управление жалобами',
              isTitle: true,
            ),
            SizedBox(height: 24),
            Center(
              child: Text('Функция в разработке'),
            ),
          ],
        ),
      );

  Widget _buildSettings() => const ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Настройки админ-панели',
              isTitle: true,
            ),
            SizedBox(height: 24),
            Center(
              child: Text('Функция в разработке'),
            ),
          ],
        ),
      );

  Widget _buildRightPanel() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Быстрые действия',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Реализовать массовые действия
              },
              icon: const Icon(Icons.block),
              label: const Text('Массовая блокировка'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Реализовать экспорт данных
              },
              icon: const Icon(Icons.download),
              label: const Text('Экспорт данных'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Реализовать резервное копирование
              },
              icon: const Icon(Icons.backup),
              label: const Text('Резервное копирование'),
            ),
          ],
        ),
      );

  void _handleUserAction(String action, ManagedUser user) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'ban':
        _showBanDialog(user);
        break;
      case 'unban':
        _unbanUser(user);
        break;
      case 'verify':
        _verifyUser(user);
        break;
    }
  }

  void _showUserDetails(ManagedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            Text('Статус: ${user.statusDescription}'),
            Text('Создан: ${user.createdAt.toString()}'),
            if (user.lastLoginAt != null)
              Text('Последний вход: ${user.lastLoginAt.toString()}'),
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

  void _showBanDialog(ManagedUser user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Заблокировать ${user.fullName}'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Причина блокировки',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              _banUser(user, reasonController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }

  Future<void> _banUser(ManagedUser user, String reason) async {
    try {
      await _adminService.banUser(user.id, reason);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пользователь ${user.fullName} заблокирован')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _unbanUser(ManagedUser user) async {
    try {
      await _adminService.unbanUser(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пользователь ${user.fullName} разблокирован')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _verifyUser(ManagedUser user) {
    // TODO: Реализовать верификацию пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Пользователь ${user.fullName} верифицирован')),
    );
  }
}
