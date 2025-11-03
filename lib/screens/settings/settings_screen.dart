import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Полноценный экран настроек
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _pushNotifications = true;
  final bool _emailNotifications = true;
  String _language = 'ru';
  String _currency = 'RUB';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Профиль
          _buildSectionHeader('Профиль'),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Редактировать профиль',
            subtitle: 'Имя, фото, био',
            onTap: () => context.push('/profile/edit'),
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Безопасность',
            subtitle: 'Пароль, 2FA, сессии',
            onTap: () => context.push('/settings/security'),
          ),

          // Внешний вид
          _buildSectionHeader('Внешний вид'),
          _buildSettingsTile(
            icon: Icons.dark_mode,
            title: 'Тёмная тема',
            subtitle: _isDarkMode ? 'Включена' : 'Выключена',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) => setState(() => _isDarkMode = value),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Язык',
            subtitle: _language == 'ru' ? 'Русский' : 'English',
            onTap: _showLanguageDialog,
          ),

          // Уведомления
          _buildSectionHeader('Уведомления'),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Уведомления',
            subtitle: _notificationsEnabled ? 'Включены' : 'Выключены',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) =>
                  setState(() => _notificationsEnabled = value),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.push_pin,
            title: 'Push-уведомления',
            subtitle: _pushNotifications ? 'Включены' : 'Выключены',
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
            ),
          ),

          // Конфиденциальность
          _buildSectionHeader('Конфиденциальность'),
          _buildSettingsTile(
            icon: Icons.visibility,
            title: 'Приватность',
            subtitle: 'Кто может видеть профиль',
            onTap: () => context.push('/settings/privacy'),
          ),
          _buildSettingsTile(
            icon: Icons.block,
            title: 'Заблокированные',
            subtitle: 'Управление блокировками',
            onTap: () => context.push('/settings/blocked'),
          ),

          // Pro-аккаунт
          _buildSectionHeader('Pro-аккаунт'),
          _buildSettingsTile(
            icon: Icons.star,
            title: 'Pro-подписка',
            subtitle: 'Активировать Pro-функции',
            onTap: () => context.push('/settings/pro'),
          ),
          _buildSettingsTile(
            icon: Icons.analytics,
            title: 'Аналитика',
            subtitle: 'Статистика профиля',
            onTap: () => context.push('/settings/analytics'),
          ),

          // Монетизация
          _buildSectionHeader('Монетизация'),
          _buildSettingsTile(
            icon: Icons.monetization_on,
            title: 'Монетизация',
            subtitle: 'Настройки монетизации',
            onTap: () => context.push('/monetization'),
          ),
          _buildSettingsTile(
            icon: Icons.payment,
            title: 'Платежи',
            subtitle: 'История и настройки',
            onTap: () => context.push('/settings/payments'),
          ),
          _buildSettingsTile(
            icon: Icons.attach_money,
            title: 'Валюта',
            subtitle: _currency,
            onTap: _showCurrencyDialog,
          ),

          // Поддержка
          _buildSectionHeader('Поддержка'),
          _buildSettingsTile(
            icon: Icons.help,
            title: 'Помощь',
            subtitle: 'FAQ и инструкции',
            onTap: () => context.push('/help'),
          ),
          _buildSettingsTile(
            icon: Icons.bug_report,
            title: 'Сообщить о проблеме',
            subtitle: 'Отправить отчёт',
            onTap: () => context.push('/settings/report'),
          ),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'О приложении',
            subtitle: 'Версия 1.0.1 (2)',
            onTap: _showAboutDialog,
          ),

          // Выход
          _buildSectionHeader(''),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Выйти',
            subtitle: 'Завершить сессию',
            textColor: Colors.red,
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    if (title.isEmpty) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(subtitle),
        trailing: trailing ??
            (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите язык'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Русский'),
              onTap: () {
                setState(() => _language = 'ru');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                setState(() => _language = 'en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите валюту'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('RUB'),
              onTap: () {
                setState(() => _currency = 'RUB');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('USD'),
              onTap: () {
                setState(() => _currency = 'USD');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('EUR'),
              onTap: () {
                setState(() => _currency = 'EUR');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Event Marketplace',
      applicationVersion: '1.0.1 (2)',
      applicationIcon: const Icon(Icons.event, size: 48),
      children: [
        const Text('Полнофункциональное приложение для организации событий'),
        const SizedBox(height: 16),
        const Text('Версия: 1.0.1 (2)'),
        const Text('Сборка: FULL IMPLEMENTATION'),
        const Text('Дата: 2024-10-24'),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
