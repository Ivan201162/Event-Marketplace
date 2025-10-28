import 'package:event_marketplace_app/core/i18n/app_localizations.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/providers/locale_provider.dart';
import 'package:event_marketplace_app/screens/admin_analytics_screen.dart';
import 'package:event_marketplace_app/screens/admin_panel_screen.dart';
import 'package:event_marketplace_app/screens/user_reports_screen.dart';
import 'package:event_marketplace_app/services/analytics_service.dart';
import 'package:event_marketplace_app/widgets/theme_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Экран настроек
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);

    // Логируем открытие настроек
    AnalyticsService().logOpenSettings();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не авторизован'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Профиль пользователя
                _buildProfileSection(context, user),

                const SizedBox(height: 24),

                // Настройки уведомлений
                _buildNotificationsSection(context),

                const SizedBox(height: 24),

                // Настройки языка
                _buildLanguageSection(context),

                const SizedBox(height: 24),

                // Настройки темы
                _buildThemeSection(context),

                const SizedBox(height: 24),

                // Админ-панель (только для администраторов)
                if (user.isAdmin) ...[
                  _buildAdminSection(context),
                  const SizedBox(height: 24),
                ],

                // Дополнительные настройки
                _buildAdditionalSettingsSection(context),

                const SizedBox(height: 24),

                // Выход
                _buildLogoutSection(context, ref),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AppUser user) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Профиль',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayNameOrEmail[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24),
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
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,),
                        ),
                        const SizedBox(height: 4),
                        Text(user.email,
                            style: TextStyle(color: Colors.grey[600]),),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4,),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.roleDisplayName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
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
            ],
          ),
        ),
      );

  Widget _buildNotificationsSection(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Уведомления',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Push-уведомления'),
                subtitle: const Text('Получать уведомления о новых событиях'),
                value:
                    true, // TODO(developer): Получить из настроек пользователя
                onChanged: (value) {
                  // TODO(developer): Сохранить настройку
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Push-уведомления ${value ? 'включены' : 'отключены'}',),),
                  );
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Email-уведомления'),
                subtitle: const Text('Получать уведомления на email'),
                value:
                    true, // TODO(developer): Получить из настроек пользователя
                onChanged: (value) {
                  // TODO(developer): Сохранить настройку
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Email-уведомления ${value ? 'включены' : 'отключены'}',),),
                  );
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Уведомления о бронированиях'),
                subtitle:
                    const Text('Получать уведомления о новых бронированиях'),
                value:
                    true, // TODO(developer): Получить из настроек пользователя
                onChanged: (value) {
                  // TODO(developer): Сохранить настройку
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Уведомления о бронированиях ${value ? 'включены' : 'отключены'}',),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('История уведомлений'),
                subtitle: const Text('Просмотреть все уведомления'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  context.push('/notifications');
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildLanguageSection(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Язык',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Русский'),
                subtitle: const Text('Язык'),
                trailing: const Icon(Icons.check, color: Colors.green),
                onTap: () {
                  // TODO(developer): Implement locale change
                  // ref
                  //     .read(localeProvider.notifier)
                  //     .setLocale(const Locale('ru'));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                      const SnackBar(content: Text('Язык изменен на русский')),);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('English'),
                subtitle: const Text('Язык'),
                trailing: Consumer(
                  builder: (context, ref, child) =>
                      ref.watch(localeProvider).languageCode == 'en'
                          ? const Icon(Icons.check, color: Colors.green)
                          : const SizedBox.shrink(),
                ),
                onTap: () {
                  // TODO(developer): Implement locale change
                  // ref
                  //     .read(localeProvider.notifier)
                  //     .setLocale(const Locale('en'));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(
                      content: Text('Язык изменен на английский'),),);
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildThemeSection(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Тема приложения',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              SizedBox(height: 16),
              ThemeSwitch(showLabel: false),
            ],
          ),
        ),
      );

  Widget _buildAdminSection(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Администрирование',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings,
                    color: Colors.orange,),
                title: const Text('Админ-панель'),
                subtitle: const Text('Управление событиями и пользователями'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (context) => const AdminPanelScreen(),),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.analytics, color: Colors.blue),
                title: const Text('Аналитика и отчёты'),
                subtitle: const Text('Статистика и аналитика платформы'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (context) => const AdminAnalyticsScreen(),),
                  );
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildAdditionalSettingsSection(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Дополнительно',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Мои отчёты'),
                subtitle: const Text('Статистика и аналитика'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (context) => const UserReportsScreen(),),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Помощь'),
                subtitle: const Text('FAQ и поддержка'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  context.go('/help');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.monitor_heart),
                title: const Text('Мониторинг'),
                subtitle: const Text('Статус приложения и метрики'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  context.go('/monitoring');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('О приложении'),
                subtitle: const Text('Версия 1.0.0'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Политика конфиденциальности'),
                subtitle: const Text('Как мы используем ваши данные'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO(developer): Открыть политику конфиденциальности
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                      const SnackBar(content: Text('Функция в разработке')),);
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Аккаунт',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Выйти'),
                subtitle: const Text('Завершить текущую сессию'),
                onTap: () {
                  _showLogoutDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      );

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Event Marketplace',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.event, size: 48),
      children: [
        const Text('Приложение для поиска и бронирования мероприятий.'),
        const SizedBox(height: 16),
        const Text('Создано с помощью Flutter и Firebase.'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Логируем выход
                await AnalyticsService().logLogout();

                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Вы вышли из аккаунта'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Ошибка выхода: $e'),
                        backgroundColor: Colors.red,),
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
}
