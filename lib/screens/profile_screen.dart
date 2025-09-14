import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../models/user.dart';
import '../widgets/theme_switch.dart';
import '../widgets/animated_page_transition.dart';
import 'customer_profile_edit_screen.dart';
import 'specialist_profile_edit_screen.dart';
import 'notification_settings_screen.dart';
import 'badges_screen.dart';
import 'inspiration_photos_screen.dart';
import 'customer_notes_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Профиль"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          const ThemeSwitch(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация о пользователе
                _buildUserInfoCard(context, user),
                
                const SizedBox(height: 24),
                
                // Профиль пользователя
                if (userRole != null)
                  _buildUserProfileCard(context, ref, user, userRole),
                
                const SizedBox(height: 24),
                
                // Настройки
                _buildSettingsCard(context, ref, user),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки профиля: $error'),
            ],
          ),
        ),
      ),
    );
  }

  /// Построение карточки профиля пользователя
  Widget _buildUserProfileCard(BuildContext context, WidgetRef ref, AppUser user, UserRole role) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Профиль ${role == UserRole.customer ? 'заказчика' : 'специалиста'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (role == UserRole.customer) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CustomerProfileEditScreen(),
                        ),
                      );
                    } else if (role == UserRole.specialist) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SpecialistProfileEditScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Отображение профиля в зависимости от роли
            if (role == UserRole.customer)
              _buildCustomerProfilePreview(context, ref, user)
            else if (role == UserRole.specialist)
              _buildSpecialistProfilePreview(context, ref, user),
          ],
        ),
      ),
    );
  }

  /// Предварительный просмотр профиля заказчика
  Widget _buildCustomerProfilePreview(BuildContext context, WidgetRef ref, AppUser user) {
    final profileAsync = ref.watch(customerProfileProvider(user.id));
    
    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Text('Профиль не создан. Нажмите "Редактировать" для создания.');
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile.bio != null) ...[
              Text('О себе:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Text(profile.bio!),
              const SizedBox(height: 8),
            ],
            if (profile.maritalStatus != null) ...[
              Text('Семейное положение:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Text(profile.maritalStatusDisplayName),
              const SizedBox(height: 8),
            ],
            if (profile.interests.isNotEmpty) ...[
              Text('Интересы:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Wrap(
                spacing: 4,
                children: profile.interests.map((interest) => Chip(
                  label: Text(interest),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка загрузки профиля: $error'),
    );
  }

  /// Предварительный просмотр профиля специалиста
  Widget _buildSpecialistProfilePreview(BuildContext context, WidgetRef ref, AppUser user) {
    final profileAsync = ref.watch(specialistProfileProvider(user.id));
    
    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Text('Профиль не создан. Нажмите "Редактировать" для создания.');
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile.bio != null) ...[
              Text('О себе:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Text(profile.bio!),
              const SizedBox(height: 8),
            ],
            if (profile.categories.isNotEmpty) ...[
              Text('Категории:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Wrap(
                spacing: 4,
                children: profile.categoryDisplayNames.map((category) => Chip(
                  label: Text(category),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Text('Опыт: ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text('${profile.experienceYears} лет'),
                const SizedBox(width: 16),
                Text('Рейтинг: ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text('${profile.rating.toStringAsFixed(1)} ⭐'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Почасовая ставка: ${profile.hourlyRate.toStringAsFixed(0)} ₽', 
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка загрузки профиля: $error'),
    );
  }

  /// Карточка с информацией о пользователе
  Widget _buildUserInfoCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: user.photoURL != null 
                      ? NetworkImage(user.photoURL!) 
                      : null,
                  child: user.photoURL == null
                      ? Text(
                          user.displayNameOrEmail.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayNameOrEmail,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getRoleColor(user.role).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          user.roleDisplayName,
                          style: TextStyle(
                            color: _getRoleColor(user.role),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow('Дата регистрации', _formatDate(user.createdAt)),
            if (user.lastLoginAt != null)
              _buildInfoRow('Последний вход', _formatDate(user.lastLoginAt!)),
            _buildInfoRow('Статус', user.isActive ? 'Активен' : 'Заблокирован'),
          ],
        ),
      ),
    );
  }

  /// Карточка настроек
  Widget _buildSettingsCard(BuildContext context, WidgetRef ref, AppUser user) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Настройки',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать профиль'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showEditProfileDialog(context, ref, user),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Изменить пароль'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showChangePasswordDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Уведомления'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Бейджи и достижения'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BadgesScreen(),
                ),
              ),
            ),
            if (user.role == UserRole.customer) ...[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Фотоальбом вдохновения'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => InspirationPhotosScreen(userId: user.id),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.note),
                title: const Text('Мои заметки'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CustomerNotesScreen(userId: user.id),
                  ),
                ),
              ),
            ],
            if (user.role == UserRole.guest)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Создать аккаунт'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showCreateAccountDialog(context, ref),
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить аккаунт', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка тестовых данных
  Widget _buildTestDataCard(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тестовые данные',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Для разработки и тестирования',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ref.read(firestoreServiceProvider).addTestBookings();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Тестовые заявки добавлены')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить тестовые заявки'),
            ),
          ],
        ),
      ),
    );
  }

  /// Строка информации
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Получить цвет роли
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return Colors.blue;
      case UserRole.specialist:
        return Colors.green;
      case UserRole.guest:
        return Colors.orange;
    }
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Показать диалог выхода
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(authServiceProvider).signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка выхода: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  /// Показать диалог редактирования профиля
  void _showEditProfileDialog(BuildContext context, WidgetRef ref, AppUser user) {
    // TODO: Реализовать редактирование профиля
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция в разработке')),
    );
  }

  /// Показать диалог изменения пароля
  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    // TODO: Реализовать изменение пароля
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция в разработке')),
    );
  }

  /// Показать диалог создания аккаунта
  void _showCreateAccountDialog(BuildContext context, WidgetRef ref) {
    // TODO: Реализовать создание аккаунта для гостя
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция в разработке')),
    );
  }

  /// Показать диалог удаления аккаунта
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление аккаунта'),
        content: const Text(
          'Вы уверены, что хотите удалить аккаунт? Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(authServiceProvider).deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка удаления: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
