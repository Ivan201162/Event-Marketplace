import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../services/admin_service.dart';
import '../providers/admin_providers.dart';

/// Экран админ-панели
class AdminPanelPage extends ConsumerStatefulWidget {
  const AdminPanelPage({super.key});

  @override
  ConsumerState<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends ConsumerState<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.adminPanelEnabled) {
      return _buildDisabledView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Пользователи'),
            Tab(text: 'События'),
            Tab(text: 'Статистика'),
            Tab(text: 'Настройки'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildEventsTab(),
          _buildStatsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildDisabledView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings_off, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'Админ-панель отключена',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Функции администрирования временно недоступны.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<List<AppUser>>(
      stream: _adminService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка загрузки пользователей: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data ?? [];

        return Column(
          children: [
            // Фильтры
            _buildUserFilters(),
            
            // Список пользователей
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildUserCard(user);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return StreamBuilder<List<Event>>(
      stream: _adminService.getAllEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка загрузки событий: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];

        return Column(
          children: [
            // Фильтры
            _buildEventFilters(),
            
            // Список событий
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventCard(event);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _adminService.getAdminStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка загрузки статистики: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Общая статистика
              _buildStatsCard('Общая статистика', {
                'Всего пользователей': stats['totalUsers'] ?? 0,
                'Активных пользователей': stats['activeUsers'] ?? 0,
                'Всего событий': stats['totalEvents'] ?? 0,
                'Активных событий': stats['activeEvents'] ?? 0,
                'Всего бронирований': stats['totalBookings'] ?? 0,
              }),
              
              const SizedBox(height: 16),
              
              // Статистика по пользователям
              _buildStatsCard('Пользователи', {
                'Новых за неделю': stats['newUsersThisWeek'] ?? 0,
                'Заблокированных': stats['bannedUsers'] ?? 0,
                'Верифицированных': stats['verifiedUsers'] ?? 0,
              }),
              
              const SizedBox(height: 16),
              
              // Статистика по событиям
              _buildStatsCard('События', {
                'Созданных за неделю': stats['newEventsThisWeek'] ?? 0,
                'Скрытых': stats['hiddenEvents'] ?? 0,
                'Завершенных': stats['completedEvents'] ?? 0,
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Настройки модерации
          _buildSettingsCard('Модерация', [
            _buildSwitchTile(
              'Автомодерация событий',
              'Автоматически скрывать события с подозрительным контентом',
              false,
              (value) => _updateSetting('autoModerateEvents', value),
            ),
            _buildSwitchTile(
              'Автомодерация пользователей',
              'Автоматически блокировать пользователей с подозрительной активностью',
              false,
              (value) => _updateSetting('autoModerateUsers', value),
            ),
          ]),
          
          const SizedBox(height: 16),
          
          // Настройки уведомлений
          _buildSettingsCard('Уведомления', [
            _buildSwitchTile(
              'Уведомления о новых пользователях',
              'Получать уведомления о регистрации новых пользователей',
              true,
              (value) => _updateSetting('notifyNewUsers', value),
            ),
            _buildSwitchTile(
              'Уведомления о новых событиях',
              'Получать уведомления о создании новых событий',
              true,
              (value) => _updateSetting('notifyNewEvents', value),
            ),
            _buildSwitchTile(
              'Уведомления о жалобах',
              'Получать уведомления о жалобах пользователей',
              true,
              (value) => _updateSetting('notifyReports', value),
            ),
          ]),
          
          const SizedBox(height: 16),
          
          // Настройки системы
          _buildSettingsCard('Система', [
            _buildSwitchTile(
              'Режим обслуживания',
              'Временно отключить регистрацию новых пользователей',
              false,
              (value) => _updateSetting('maintenanceMode', value),
            ),
            _buildSwitchTile(
              'Строгая модерация',
              'Включить дополнительные проверки контента',
              false,
              (value) => _updateSetting('strictModeration', value),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildUserFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск пользователей...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // TODO: Implement user search
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: 'all',
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Все')),
              DropdownMenuItem(value: 'active', child: Text('Активные')),
              DropdownMenuItem(value: 'banned', child: Text('Заблокированные')),
              DropdownMenuItem(value: 'verified', child: Text('Верифицированные')),
            ],
            onChanged: (value) {
              // TODO: Implement user filtering
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск событий...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // TODO: Implement event search
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: 'all',
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Все')),
              DropdownMenuItem(value: 'active', child: Text('Активные')),
              DropdownMenuItem(value: 'hidden', child: Text('Скрытые')),
              DropdownMenuItem(value: 'completed', child: Text('Завершенные')),
            ],
            onChanged: (value) {
              // TODO: Implement event filtering
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoUrl != null 
              ? NetworkImage(user.photoUrl!) 
              : null,
          child: user.photoUrl == null 
              ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
              : null,
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            if (user.bio.isNotEmpty) Text(user.bio),
            Row(
              children: [
                if (user.isVerified)
                  const Chip(
                    label: Text('Верифицирован'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                if (user.isBanned)
                  const Chip(
                    label: Text('Заблокирован'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Просмотр'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'verify',
              child: ListTile(
                leading: Icon(Icons.verified),
                title: Text('Верифицировать'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'ban',
              child: ListTile(
                leading: Icon(Icons.block),
                title: Text('Заблокировать'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'unban',
              child: ListTile(
                leading: Icon(Icons.check_circle),
                title: Text('Разблокировать'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: event.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  event.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.event, size: 60),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            Text('${event.date.day}.${event.date.month}.${event.date.year}'),
            if (event.isHidden)
              const Chip(
                label: Text('Скрыто'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleEventAction(value, event),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Просмотр'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'hide',
              child: ListTile(
                leading: Icon(Icons.visibility_off),
                title: Text('Скрыть'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'show',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Показать'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Удалить'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _handleUserAction(String action, AppUser user) async {
    try {
      switch (action) {
        case 'view':
          // TODO: Navigate to user profile
          break;
        case 'verify':
          await _adminService.verifyUser(user.id);
          _showSuccessMessage('Пользователь верифицирован');
          break;
        case 'ban':
          await _adminService.banUser(user.id, 'Нарушение правил');
          _showSuccessMessage('Пользователь заблокирован');
          break;
        case 'unban':
          await _adminService.unbanUser(user.id);
          _showSuccessMessage('Пользователь разблокирован');
          break;
      }
    } catch (e, stackTrace) {
      SafeLog.error('AdminPanelPage: Error handling user action', e, stackTrace);
      _showErrorMessage('Ошибка: $e');
    }
  }

  Future<void> _handleEventAction(String action, Event event) async {
    try {
      switch (action) {
        case 'view':
          // TODO: Navigate to event details
          break;
        case 'hide':
          await _adminService.hideEvent(event.id, 'Нарушение правил');
          _showSuccessMessage('Событие скрыто');
          break;
        case 'show':
          await _adminService.showEvent(event.id);
          _showSuccessMessage('Событие показано');
          break;
        case 'delete':
          await _adminService.deleteEvent(event.id);
          _showSuccessMessage('Событие удалено');
          break;
      }
    } catch (e, stackTrace) {
      SafeLog.error('AdminPanelPage: Error handling event action', e, stackTrace);
      _showErrorMessage('Ошибка: $e');
    }
  }

  void _updateSetting(String key, bool value) {
    // TODO: Implement settings update
    SafeLog.info('AdminPanelPage: Setting $key updated to $value');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
