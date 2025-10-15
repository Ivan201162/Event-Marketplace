import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';

class EnhancedSettingsScreen extends ConsumerWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Настройки темы
          _SettingsSection(
            title: 'Внешний вид',
            children: [
              _ThemeSelector(themeMode: themeMode),
            ],
          ),

          // Уведомления
          _SettingsSection(
            title: 'Уведомления',
            children: [
              _SettingsTile(
                icon: Icons.notifications,
                title: 'Push-уведомления',
                subtitle: 'Получать уведомления о новых заявках и сообщениях',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // Обработка переключения уведомлений
                  },
                ),
              ),
              _SettingsTile(
                icon: Icons.email,
                title: 'Email-уведомления',
                subtitle: 'Получать уведомления на email',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // Обработка переключения email уведомлений
                  },
                ),
              ),
            ],
          ),

          // Безопасность
          _SettingsSection(
            title: 'Безопасность',
            children: [
              _SettingsTile(
                icon: Icons.lock,
                title: 'Восстановление пароля',
                subtitle: 'Изменить или восстановить пароль',
                onTap: () => _showPasswordRecoveryDialog(context),
              ),
              _SettingsTile(
                icon: Icons.security,
                title: 'Двухфакторная аутентификация',
                subtitle: 'Дополнительная защита аккаунта',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // Обработка переключения 2FA
                  },
                ),
              ),
            ],
          ),

          // Помощь и поддержка
          _SettingsSection(
            title: 'Помощь и поддержка',
            children: [
              _SettingsTile(
                icon: Icons.help,
                title: 'Справка',
                subtitle: 'Часто задаваемые вопросы',
                onTap: () => context.push('/help'),
              ),
              _SettingsTile(
                icon: Icons.support,
                title: 'Поддержка',
                subtitle: 'Связаться с поддержкой',
                onTap: () => context.push('/support'),
              ),
              _SettingsTile(
                icon: Icons.bug_report,
                title: 'Сообщить об ошибке',
                subtitle: 'Помогите улучшить приложение',
                onTap: () => context.push('/bug-report'),
              ),
              _SettingsTile(
                icon: Icons.auto_fix_high,
                title: 'Демо транслитерации',
                subtitle: 'Тестирование генерации username',
                onTap: () => context.push('/transliterate-demo'),
              ),
            ],
          ),

          // О приложении
          _SettingsSection(
            title: 'О приложении',
            children: [
              _SettingsTile(
                icon: Icons.info,
                title: 'Версия приложения',
                subtitle: '1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip,
                title: 'Политика конфиденциальности',
                subtitle: 'Как мы обрабатываем ваши данные',
                onTap: () => _openPrivacyPolicy(context),
              ),
              _SettingsTile(
                icon: Icons.description,
                title: 'Условия использования',
                subtitle: 'Правила использования приложения',
                onTap: () => _openTermsOfService(context),
              ),
            ],
          ),

          // Выход
          _SettingsSection(
            children: [
              _SettingsTile(
                icon: Icons.logout,
                title: 'Выйти из аккаунта',
                subtitle: 'Завершить текущую сессию',
                textColor: Colors.red,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showPasswordRecoveryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановление пароля'),
        content: const Text(
          'Введите email адрес, на который будет отправлена ссылка для восстановления пароля.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Отправка ссылки восстановления
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Ссылка для восстановления отправлена на email'),
                ),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Event Marketplace',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.event,
        size: 64,
        color: Colors.blue,
      ),
      children: const [
        Text(
          'Приложение для организации мероприятий и поиска специалистов.',
        ),
      ],
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    const url = 'https://example.com/privacy-policy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть политику конфиденциальности'),
        ),
      );
    }
  }

  Future<void> _openTermsOfService(BuildContext context) async {
    const url = 'https://example.com/terms-of-service';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть условия использования'),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text(
          'Вы уверены, что хотите выйти из аккаунта?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Выход из аккаунта
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {

  const _SettingsSection({
    this.title,
    required this.children,
  });
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
}

class _SettingsTile extends StatelessWidget {

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: textColor?.withValues(alpha: 0.7) ?? Colors.grey[600],
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
}

class _ThemeSelector extends ConsumerWidget {

  const _ThemeSelector({required this.themeMode});
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
      children: [
        _SettingsTile(
          icon: Icons.light_mode,
          title: 'Светлая тема',
          subtitle: 'Использовать светлую цветовую схему',
          trailing: Radio<ThemeMode>(
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setLightTheme();
              }
            },
          ),
          onTap: () => ref.read(themeProvider.notifier).setLightTheme(),
        ),
        _SettingsTile(
          icon: Icons.dark_mode,
          title: 'Тёмная тема',
          subtitle: 'Использовать тёмную цветовую схему',
          trailing: Radio<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setDarkTheme();
              }
            },
          ),
          onTap: () => ref.read(themeProvider.notifier).setDarkTheme(),
        ),
        _SettingsTile(
          icon: Icons.brightness_auto,
          title: 'Автоматическая',
          subtitle: 'Следовать системным настройкам',
          trailing: Radio<ThemeMode>(
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setSystemTheme();
              }
            },
          ),
          onTap: () => ref.read(themeProvider.notifier).setSystemTheme(),
        ),
      ],
    );
}
