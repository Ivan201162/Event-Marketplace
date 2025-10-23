import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/profile_edit_dialog.dart';

/// User profile screen with editing capabilities
class UserProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const UserProfileScreen({super.key, this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final isOwnProfile = widget.userId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'Мой профиль' : 'Профиль'),
        actions: [
          if (isOwnProfile) ...[
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  _editProfile();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Navigate to settings
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(
                    content: Text('Настройки пока не реализованы')));
              },
            ),
          ],
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(user),

                const SizedBox(height: 24),

                // Profile Info
                _buildProfileInfo(user),

                const SizedBox(height: 24),

                // Statistics
                _buildStatistics(user),

                const SizedBox(height: 24),

                // Actions
                if (isOwnProfile) _buildActions(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки профиля',
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              AvatarWidget(
                  imageUrl: user.avatarUrl, name: user.name, size: 100),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 20),
                      onPressed: _changeAvatar,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Name and Status
          Text(
            user.name,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),

          const SizedBox(height: 8),

          Text(user.city,
              style: const TextStyle(fontSize: 16, color: Colors.white70)),

          const SizedBox(height: 8),

          // User Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.type.displayName,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(AppUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Информация',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Имя',
              value: user.name,
              onTap: _isEditing ? () => _editField('name', user.name) : null,
            ),
            _buildInfoRow(
              icon: Icons.location_city,
              label: 'Город',
              value: user.city,
              onTap: _isEditing ? () => _editField('city', user.city) : null,
            ),
            _buildInfoRow(
              icon: Icons.category,
              label: 'Тип',
              value: user.type.displayName,
              onTap:
                  _isEditing ? () => _editField('type', user.type.name) : null,
            ),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Дата регистрации',
              value: _formatDate(user.createdAt),
            ),
            if (user.status != null)
              _buildInfoRow(
                icon: Icons.info,
                label: 'Статус',
                value: user.status!,
                onTap: _isEditing
                    ? () => _editField('status', user.status!)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.edit, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(AppUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Статистика',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    label: 'Подписчики',
                    value: user.followersCount.toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                      icon: Icons.star, label: 'Рейтинг', value: '4.8'),
                ),
                Expanded(
                  child: _buildStatItem(
                      icon: Icons.work, label: 'Заказы', value: '12'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      {required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Действия',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.favorite,
              label: 'Избранные специалисты',
              onTap: () {
                // TODO: Navigate to favorites
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(
                    content: Text('Избранные пока не реализованы')));
              },
            ),
            _buildActionButton(
              icon: Icons.history,
              label: 'История заказов',
              onTap: () {
                // TODO: Navigate to order history
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('История заказов пока не реализована')),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.payment,
              label: 'Способы оплаты',
              onTap: () {
                // TODO: Navigate to payment methods
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(
                    content: Text('Способы оплаты пока не реализованы')));
              },
            ),
            _buildActionButton(
              icon: Icons.help,
              label: 'Помощь и поддержка',
              onTap: () {
                // TODO: Navigate to help
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(
                    content: Text('Помощь пока не реализована')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveProfile() {
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Профиль сохранен')));
  }

  void _changeAvatar() {
    // TODO: Implement avatar change
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Смена аватара пока не реализована')));
  }

  void _editField(String field, String currentValue) {
    showDialog(
      context: context,
      builder: (context) => ProfileEditDialog(
        field: field,
        currentValue: currentValue,
        onSave: (newValue) {
          // TODO: Update user profile
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$field обновлен: $newValue')));
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
