import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/user.dart';
import '../widgets/auth_guard_widget.dart';
import 'profile_edit_screen.dart';

/// Страница профиля пользователя
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) => AuthGuard(
        child: UserInfoWidget(
          builder: (user) => _buildProfileContent(context, user),
          fallbackWidget: const Scaffold(
            body: Center(
              child: Text('Пользователь не авторизован'),
            ),
          ),
        ),
      );

  Widget _buildProfileContent(BuildContext context, AppUser appUser) =>
      Scaffold(
        body: CustomScrollView(
          slivers: [
            // Современный AppBar с градиентом
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Мой профиль',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: BrandColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 40, left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Мой профиль',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: _navigateToEditProfile,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Основной контент
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Аватар пользователя
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).primaryColor,
                      backgroundImage: appUser.photoURL != null
                          ? NetworkImage(appUser.photoURL!)
                          : null,
                      child: appUser.photoURL == null
                          ? Text(
                              (appUser.displayName?.isNotEmpty ?? false)
                                  ? appUser.displayName![0].toUpperCase()
                                  : appUser.email.isNotEmpty
                                      ? appUser.email[0].toUpperCase()
                                      : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // Имя пользователя
                    Text(
                      appUser.displayNameOrEmail,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),

                    const SizedBox(height: 8),

                    // Email
                    Text(
                      appUser.email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Роль пользователя
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(appUser.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getRoleColor(appUser.role).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getRoleText(appUser.role),
                        style: TextStyle(
                          color: _getRoleColor(appUser.role),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Кнопка редактирования профиля
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToEditProfile,
                        icon: const Icon(Icons.edit),
                        label: const Text('Редактировать профиль'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Информация о регистрации
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Информация о профиле',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Дата регистрации',
                              _formatDate(appUser.createdAt),
                            ),
                            if (appUser.lastLoginAt != null)
                              _buildInfoRow(
                                'Последний вход',
                                _formatDate(appUser.lastLoginAt!),
                              ),
                            _buildInfoRow(
                              'Статус',
                              appUser.isActive ? 'Активен' : 'Заблокирован',
                            ),
                            if (appUser.socialProvider != null)
                              _buildInfoRow(
                                'Вход через',
                                _getSocialProviderText(appUser.socialProvider!),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return Colors.blue;
      case UserRole.specialist:
        return Colors.green;
      case UserRole.guest:
        return Colors.orange;
      case UserRole.admin:
        return Colors.purple;
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Заказчик';
      case UserRole.specialist:
        return 'Специалист';
      case UserRole.guest:
        return 'Гость';
      case UserRole.admin:
        return 'Администратор';
    }
  }

  String _getSocialProviderText(String provider) {
    switch (provider) {
      case 'google':
        return 'Google';
      case 'vk':
        return 'ВКонтакте';
      case 'email':
        return 'Email';
      default:
        return provider;
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
      ),
    );
  }
}
