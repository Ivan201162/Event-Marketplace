import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
// import '../models/admin_panel.dart';
import '../services/admin_panel_service.dart';

/// Экран управления пользователями в админ-панели
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final AdminPanelService _adminService = AdminPanelService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserRole? _selectedRole;
  bool _showBannedOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Фильтры и поиск
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Поиск
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск пользователей...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Фильтры
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<UserRole?>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Роль',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Все роли'),
                          ),
                          const DropdownMenuItem(
                            value: UserRole.customer,
                            child: Text('Заказчики'),
                          ),
                          const DropdownMenuItem(
                            value: UserRole.specialist,
                            child: Text('Специалисты'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    FilterChip(
                      label: const Text('Заблокированные'),
                      selected: _showBannedOnly,
                      onSelected: (selected) {
                        setState(() {
                          _showBannedOnly = selected;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Список пользователей
          Expanded(
            child: StreamBuilder<List<AppUser>>(
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
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Ошибка: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }

                final allUsers = snapshot.data ?? [];
                final filteredUsers = _filterUsers(allUsers);

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Пользователи не найдены',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AppUser> _filterUsers(List<AppUser> users) {
    return users.where((user) {
      // Поиск по имени или email
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!(user.displayName?.toLowerCase().contains(query) ?? false) &&
            !user.email.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Фильтр по роли
      if (_selectedRole != null && user.role != _selectedRole) {
        return false;
      }

      // Фильтр по статусу блокировки
      if (_showBannedOnly && user.isActive) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildUserCard(AppUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: !user.isActive ? Colors.red : Theme.of(context).primaryColor,
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null
              ? Text(
                  (user.displayName?.isNotEmpty ?? false)
                      ? user.displayName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName ?? 'Без имени',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: !user.isActive ? Colors.red : null,
                ),
              ),
            ),
            if (!user.isActive)
              const Icon(Icons.block, color: Colors.red, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleChip(user.role),
                const SizedBox(width: 8),
                Text(
                  'Создан: ${_formatDate(user.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleUserAction(action, user),
          itemBuilder: (context) => [
            if (user.isActive)
              const PopupMenuItem(
                value: 'ban',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Заблокировать'),
                  ],
                ),
              )
            if (!user.isActive)
              const PopupMenuItem(
                value: 'unban',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Разблокировать'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Подробнее'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Редактировать'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role) {
    Color color;
    String text;
    
    switch (role) {
      case UserRole.customer:
        color = Colors.blue;
        text = 'Заказчик';
        break;
      case UserRole.specialist:
        color = Colors.green;
        text = 'Специалист';
        break;
      case UserRole.guest:
        color = Colors.orange;
        text = 'Гость';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleUserAction(String action, AppUser user) {
    switch (action) {
      case 'ban':
        _showBanUserDialog(user);
        break;
      case 'unban':
        _unbanUser(user);
        break;
      case 'view':
        _showUserDetails(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
    }
  }

  void _showUserDetails(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Пользователь: ${user.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Роль', _getRoleText(user.role)),
              _buildDetailRow('Статус', user.isBanned ? 'Заблокирован' : 'Активен'),
              _buildDetailRow('Дата создания', _formatDate(user.createdAt)),
              if (user.lastLogin != null)
                _buildDetailRow('Последний вход', _formatDate(user.lastLogin!)),
              if (user.isBanned && user.banReason != null)
                _buildDetailRow('Причина блокировки', user.banReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          if (!user.isBanned)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showBanUserDialog(user);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Заблокировать'),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _unbanUser(user);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Разблокировать'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showBanUserDialog(AppUser user) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокировать пользователя'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Вы уверены, что хотите заблокировать пользователя ${user.displayName}?'),
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
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _banUser(user, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактирование пользователя'),
        content: const Text('Функция редактирования пользователя будет добавлена в следующих версиях.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _banUser(AppUser user, String reason) async {
    try {
      // TODO: Получить ID текущего администратора
      final adminId = 'demo_admin_id';
      
      final success = await _adminService.banUser(user.uid, adminId, reason);
      
      if (success) {
        _showSuccessSnackBar('Пользователь ${user.displayName} заблокирован');
      } else {
        _showErrorSnackBar('Ошибка блокировки пользователя');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка: $e');
    }
  }

  Future<void> _unbanUser(AppUser user) async {
    try {
      // TODO: Получить ID текущего администратора
      final adminId = 'demo_admin_id';
      
      final success = await _adminService.unbanUser(user.uid, adminId);
      
      if (success) {
        _showSuccessSnackBar('Пользователь ${user.displayName} разблокирован');
      } else {
        _showErrorSnackBar('Ошибка разблокировки пользователя');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка: $e');
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Заказчик';
      case UserRole.specialist:
        return 'Специалист';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
}
