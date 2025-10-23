import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_overlay.dart';

/// Экран заблокированных пользователей
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _userProfileService = UserProfileService();

  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  /// Загрузить список заблокированных пользователей
  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Реализовать загрузку заблокированных пользователей
      await Future.delayed(const Duration(seconds: 1)); // Заглушка
      
      // Заглушка данных
      setState(() {
        _blockedUsers = [
          BlockedUser(
            id: '1',
            name: 'Иван Петров',
            username: '@ivan_petrov',
            avatarUrl: null,
            blockedAt: DateTime.now().subtract(const Duration(days: 5)),
            reason: 'Спам',
          ),
          BlockedUser(
            id: '2',
            name: 'Мария Сидорова',
            username: '@maria_sid',
            avatarUrl: null,
            blockedAt: DateTime.now().subtract(const Duration(days: 10)),
            reason: 'Неприемлемое поведение',
          ),
        ];
      });
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки списка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Разблокировать пользователя
  Future<void> _unblockUser(BlockedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Разблокировать пользователя'),
        content: Text(
          'Вы уверены, что хотите разблокировать ${user.name}? '
          'Пользователь снова сможет видеть ваш контент и писать вам сообщения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Разблокировать'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        // TODO: Реализовать разблокировку пользователя
        await Future.delayed(const Duration(seconds: 1)); // Заглушка
        
        setState(() {
          _blockedUsers.remove(user);
        });
        
        _showSuccessSnackBar('Пользователь разблокирован');
      } catch (e) {
        _showErrorSnackBar('Ошибка разблокировки: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Заблокировать пользователя
  Future<void> _blockUser() async {
    // TODO: Реализовать поиск и блокировку пользователя
    _showInfoSnackBar('Поиск и блокировка пользователей будет реализована');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Заблокированные',
        actions: [
          IconButton(
            onPressed: _blockUser,
            icon: const Icon(Icons.person_add_disabled),
            tooltip: 'Заблокировать пользователя',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _blockedUsers.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _blockedUsers.length,
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  return _buildBlockedUserCard(user);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Заблокированных пользователей нет',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Здесь будут отображаться пользователи, которых вы заблокировали',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserCard(BlockedUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: user.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    user.avatarUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
                  ),
                )
              : const Icon(Icons.person),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.username),
            const SizedBox(height: 4),
            Text(
              'Заблокирован ${_formatDate(user.blockedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (user.reason != null) ...[
              const SizedBox(height: 2),
              Text(
                'Причина: ${user.reason}',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'unblock') {
              _unblockUser(user);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'unblock',
              child: Row(
                children: [
                  Icon(Icons.lock_open, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Разблокировать'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}

/// Модель заблокированного пользователя
class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.blockedAt,
    this.reason,
  });

  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final DateTime blockedAt;
  final String? reason;
}
