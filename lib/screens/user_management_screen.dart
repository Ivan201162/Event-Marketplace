import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../models/user_management.dart';
import '../services/user_management_service.dart';
import '../ui/ui.dart' hide ResponsiveCard;
import '../widgets/responsive_layout.dart';

/// Экран управления пользователями и ролями
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final UserManagementService _userService = UserManagementService();
  List<ManagedUser> _users = [];
  List<UserRoleDefinition> _roles = [];
  List<Permission> _permissions = [];
  bool _isLoading = true;
  String _selectedTab = 'users';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'users'
                      ? _buildUsersTab()
                      : _selectedTab == 'roles'
                          ? _buildRolesTab()
                          : _selectedTab == 'permissions'
                              ? _buildPermissionsTab()
                              : _buildStatisticsTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
                child: _buildTabButton('users', 'Пользователи', Icons.people)),
            Expanded(
                child: _buildTabButton(
                    'roles', 'Роли', Icons.admin_panel_settings)),
            Expanded(
                child: _buildTabButton(
                    'permissions', 'Разрешения', Icons.security)),
            Expanded(
                child: _buildTabButton(
                    'statistics', 'Статистика', Icons.analytics)),
          ],
        ),
      );

  Widget _buildTabButton(String tab, String title, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected
                  ? Colors.blue
                  : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() => Column(
        children: [
          // Заголовок с фильтрами
          ResponsiveCard(
            child: Row(
              children: [
                const ResponsiveText('Пользователи', isTitle: true),
                const Spacer(),
                DropdownButton<UserRole?>(
                  hint: const Text('Все роли'),
                  items: [
                    const DropdownMenuItem<UserRole?>(child: Text('Все роли')),
                    ...UserRole.values.map(
                      (role) => DropdownMenuItem<UserRole?>(
                        value: role,
                        child: Row(
                          children: [
                            Text(role.icon),
                            const SizedBox(width: 8),
                            Text(role.displayName)
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    // TODO(developer): Реализовать фильтрацию
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список пользователей
          Expanded(
            child: _users.isEmpty
                ? const Center(child: Text('Пользователи не найдены'))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return _buildUserCard(user);
                    },
                  ),
          ),
        ],
      );

  Widget _buildUserCard(ManagedUser user) {
    final statusColor = _getStatusColor(user.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(
                        user.displayName?.isNotEmpty ?? false
                            ? user.displayName![0].toUpperCase()
                            : user.email[0].toUpperCase(),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(user.email, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              _buildStatusChip(user.status),
              PopupMenuButton<String>(
                onSelected: (value) => _handleUserAction(value, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Просмотр')),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Редактировать')),
                  ),
                  if (user.isBlocked) ...[
                    const PopupMenuItem(
                      value: 'unblock',
                      child: ListTile(
                        leading: Icon(Icons.lock_open),
                        title: Text('Разблокировать'),
                      ),
                    ),
                  ] else ...[
                    const PopupMenuItem(
                      value: 'block',
                      child: ListTile(
                          leading: Icon(Icons.block),
                          title: Text('Заблокировать')),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'permissions',
                    child: ListTile(
                        leading: Icon(Icons.security),
                        title: Text('Разрешения')),
                  ),
                  const PopupMenuItem(
                    value: 'actions',
                    child: ListTile(
                        leading: Icon(Icons.history), title: Text('Действия')),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Роль', user.role.roleDisplayName, Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip(
                  'Разрешения', '${user.permissions.length}', Colors.green),
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(user.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (user.lastLoginAt != null) ...[
                const Spacer(),
                Text(
                  'Последний вход: ${_formatDateTime(user.lastLoginAt!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                const ResponsiveText('Роли пользователей', isTitle: true),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateRoleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать роль'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список ролей
          Expanded(
            child: _roles.isEmpty
                ? const Center(child: Text('Роли не найдены'))
                : ListView.builder(
                    itemCount: _roles.length,
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      return _buildRoleCard(role);
                    },
                  ),
          ),
        ],
      );

  Widget _buildRoleCard(UserRoleDefinition role) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: role.isSystemRole ? Colors.orange : Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(role.description,
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                if (role.isSystemRole)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'Системная',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleRoleAction(value, role),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('Просмотр')),
                    ),
                    if (!role.isSystemRole) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Редактировать')),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Удалить')),
                      ),
                    ],
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Разрешения
            Text(
              'Разрешения (${role.permissions.length}):',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: role.permissions
                  .take(5)
                  .map(
                    (permission) => Chip(
                      label: Text(permission),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                  .toList(),
            ),

            if (role.permissions.length > 5) ...[
              const SizedBox(height: 4),
              Text(
                'и еще ${role.permissions.length - 5}...',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic),
              ),
            ],

            const SizedBox(height: 12),

            // Время создания
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Создана: ${_formatDateTime(role.createdAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildPermissionsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                const ResponsiveText('Разрешения', isTitle: true),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreatePermissionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать разрешение'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список разрешений
          Expanded(
            child: _permissions.isEmpty
                ? const Center(child: Text('Разрешения не найдены'))
                : ListView.builder(
                    itemCount: _permissions.length,
                    itemBuilder: (context, index) {
                      final permission = _permissions[index];
                      return _buildPermissionCard(permission);
                    },
                  ),
          ),
        ],
      );

  Widget _buildPermissionCard(Permission permission) {
    final typeColor = _getPermissionTypeColor(permission.type);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(_getPermissionTypeIcon(permission.type),
                  color: typeColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permission.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(permission.description,
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor),
                ),
                child: Text(
                  permission.type.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Категория
          Row(
            children: [
              _buildInfoChip('Категория', permission.category, Colors.green),
              if (permission.isSystemPermission) ...[
                const SizedBox(width: 8),
                _buildInfoChip('Системное', 'Да', Colors.orange),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Время создания
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создано: ${_formatDateTime(permission.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final stats = _userService.getUserStatistics();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Основная статистика
          ResponsiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ResponsiveText('Статистика пользователей', isTitle: true),

                const SizedBox(height: 16),

                // Основные метрики
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Всего пользователей',
                        '${stats['total'] ?? 0}',
                        Colors.blue,
                        Icons.people,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Активных',
                        '${stats['active'] ?? 0}',
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Заблокированных',
                        '${stats['blocked'] ?? 0}',
                        Colors.red,
                        Icons.block,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Статистика по ролям
                Text(
                  'Пользователи по ролям:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),

                const SizedBox(height: 8),

                ...UserRole.values.map((role) {
                  final count =
                      stats['role_${role.toString().split('.').last}'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(role.icon),
                                const SizedBox(width: 8),
                                Text(role.displayName),
                              ],
                            ),
                            Text('$count'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: stats['total'] != null && stats['total']! > 0
                              ? count / stats['total']!
                              : 0.0,
                          backgroundColor: Colors.grey.withValues(alpha: 0.3),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
          String title, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildStatusChip(UserStatus status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style:
            TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      );

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.inactive:
        return Colors.grey;
      case UserStatus.blocked:
        return Colors.red;
      case UserStatus.pending:
        return Colors.orange;
      case UserStatus.suspended:
        return Colors.yellow;
    }
  }

  Color _getPermissionTypeColor(PermissionType type) {
    switch (type) {
      case PermissionType.read:
        return Colors.blue;
      case PermissionType.write:
        return Colors.green;
      case PermissionType.delete:
        return Colors.red;
      case PermissionType.manage:
        return Colors.purple;
      case PermissionType.moderate:
        return Colors.orange;
    }
  }

  IconData _getPermissionTypeIcon(PermissionType type) {
    switch (type) {
      case PermissionType.read:
        return Icons.visibility;
      case PermissionType.write:
        return Icons.edit;
      case PermissionType.delete:
        return Icons.delete;
      case PermissionType.manage:
        return Icons.admin_panel_settings;
      case PermissionType.moderate:
        return Icons.security;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.initialize();
      setState(() {
        _users = _userService.getAllUsers();
        _roles = _userService.getAllRoles();
        _permissions = _userService.getAllPermissions();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleUserAction(String action, ManagedUser user) {
    switch (action) {
      case 'view':
        _viewUser(user);
        break;
      case 'edit':
        _editUser(user);
        break;
      case 'block':
        _blockUser(user);
        break;
      case 'unblock':
        _unblockUser(user);
        break;
      case 'permissions':
        _manageUserPermissions(user);
        break;
      case 'actions':
        _viewUserActions(user);
        break;
    }
  }

  void _viewUser(ManagedUser user) {
    // TODO(developer): Реализовать просмотр пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Просмотр пользователя "${user.email}" будет реализован')),
    );
  }

  void _editUser(ManagedUser user) {
    // TODO(developer): Реализовать редактирование пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Редактирование пользователя "${user.email}" будет реализовано')),
    );
  }

  void _blockUser(ManagedUser user) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();

        return AlertDialog(
          title: const Text('Заблокировать пользователя'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Заблокировать пользователя "${user.email}"?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Причина блокировки',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _userService.blockUser(
                    user.id,
                    reasonController.text,
                    'current_user', // TODO(developer): Получить ID текущего пользователя
                  );
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Пользователь заблокирован'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка блокировки пользователя: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Заблокировать'),
            ),
          ],
        );
      },
    );
  }

  void _unblockUser(ManagedUser user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Разблокировать пользователя'),
        content: Text('Разблокировать пользователя "${user.email}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.unblockUser(
                  user.id,
                  'current_user', // TODO(developer): Получить ID текущего пользователя
                );
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Пользователь разблокирован'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка разблокировки пользователя: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Разблокировать'),
          ),
        ],
      ),
    );
  }

  void _manageUserPermissions(ManagedUser user) {
    // TODO(developer): Реализовать управление разрешениями пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Управление разрешениями пользователя "${user.email}" будет реализовано'),
      ),
    );
  }

  void _viewUserActions(ManagedUser user) {
    // TODO(developer): Реализовать просмотр действий пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Просмотр действий пользователя "${user.email}" будет реализован')),
    );
  }

  void _handleRoleAction(String action, UserRoleDefinition role) {
    switch (action) {
      case 'view':
        _viewRole(role);
        break;
      case 'edit':
        _editRole(role);
        break;
      case 'delete':
        _deleteRole(role);
        break;
    }
  }

  void _viewRole(UserRoleDefinition role) {
    // TODO(developer): Реализовать просмотр роли
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Просмотр роли "${role.name}" будет реализован')));
  }

  void _editRole(UserRoleDefinition role) {
    // TODO(developer): Реализовать редактирование роли
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Редактирование роли "${role.name}" будет реализовано')));
  }

  void _deleteRole(UserRoleDefinition role) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить роль'),
        content: Text('Вы уверены, что хотите удалить роль "${role.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.deleteRole(
                  role.id,
                  'current_user', // TODO(developer): Получить ID текущего пользователя
                );
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Роль удалена'),
                      backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Ошибка удаления роли: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showCreateRoleDialog() {
    // TODO(developer): Реализовать диалог создания роли
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Создание роли будет реализовано')));
  }

  void _showCreatePermissionDialog() {
    // TODO(developer): Реализовать диалог создания разрешения
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Создание разрешения будет реализовано')));
  }
}
