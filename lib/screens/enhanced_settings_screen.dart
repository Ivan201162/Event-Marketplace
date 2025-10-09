import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/calendar_reminders_screen.dart';
import '../screens/event_organizer_screen.dart';
import '../screens/pro_subscription_screen.dart';
import '../screens/testing_monitoring_screen.dart';
import '../widgets/advertising_widgets.dart';
import '../widgets/enhanced_animations.dart';
import '../widgets/swipe_back_mixin.dart';

/// Расширенный экран настроек
class EnhancedSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedSettingsScreen> createState() =>
      _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends ConsumerState<EnhancedSettingsScreen>
    with SwipeBackMixin {
  bool _notificationsEnabled = true;
  bool _doNotDisturbMode = false;
  final bool _offlineMode = false;
  bool _twoFactorEnabled = false;
  String _selectedLanguage = 'ru';
  String _selectedTheme = 'system';
  double _notificationFrequency = 0.5;

  final List<LanguageOption> _languages = [
    const LanguageOption(code: 'ru', name: 'Русский', flag: '🇷🇺'),
    const LanguageOption(code: 'en', name: 'English', flag: '🇺🇸'),
    const LanguageOption(code: 'kk', name: 'Қазақша', flag: '🇰🇿'),
  ];

  final List<ThemeOption> _themes = [
    const ThemeOption(code: 'light', name: 'Светлая', icon: Icons.light_mode),
    const ThemeOption(code: 'dark', name: 'Тёмная', icon: Icons.dark_mode),
    const ThemeOption(
        code: 'system', name: 'Системная', icon: Icons.brightness_auto),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Настройки'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: wrapWithSwipeBack(
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSection(),
                const SizedBox(height: 24),
                _buildAppearanceSection(),
                const SizedBox(height: 24),
                _buildNotificationsSection(),
                const SizedBox(height: 24),
                _buildPrivacySection(),
                const SizedBox(height: 24),
                _buildSecuritySection(),
                const SizedBox(height: 24),
                _buildMonetizationSection(),
                const SizedBox(height: 24),
                _buildAdvancedSection(),
                const SizedBox(height: 24),
                _buildAccountSection(),
                const SizedBox(height: 24),
                _buildAboutSection(),
              ],
            ),
          ),
        ),
      );

  Widget _buildProfileSection() => FadeInWidget(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Профиль',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Text(
                        'U',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Пользователь',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'user@example.com',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Переход к редактированию профиля
                      },
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildAppearanceSection() => FadeInWidget(
        delay: const Duration(milliseconds: 100),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Внешний вид',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildLanguageSelector(),
                const SizedBox(height: 16),
                _buildThemeSelector(),
              ],
            ),
          ),
        ),
      );

  Widget _buildLanguageSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Язык',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: _languages
                .map(
                  (language) => DropdownMenuItem(
                    value: language.code,
                    child: Row(
                      children: [
                        Text(language.flag,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(language.name),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
              // TODO: Изменить язык приложения
            },
          ),
        ],
      );

  Widget _buildThemeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Тема',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedTheme,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: _themes
                .map(
                  (theme) => DropdownMenuItem(
                    value: theme.code,
                    child: Row(
                      children: [
                        Icon(theme.icon),
                        const SizedBox(width: 8),
                        Text(theme.name),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedTheme = value!;
              });
              // TODO: Изменить тему приложения
            },
          ),
        ],
      );

  Widget _buildNotificationsSection() => FadeInWidget(
        delay: const Duration(milliseconds: 200),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Уведомления',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSwitchTile(
                  title: 'Уведомления',
                  subtitle: 'Получать push-уведомления',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Режим "Не беспокоить"',
                  subtitle: 'Отключить все уведомления',
                  value: _doNotDisturbMode,
                  onChanged: (value) {
                    setState(() {
                      _doNotDisturbMode = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Частота уведомлений',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Slider(
                  value: _notificationFrequency,
                  onChanged: (value) {
                    setState(() {
                      _notificationFrequency = value;
                    });
                  },
                  divisions: 4,
                  label: _getNotificationFrequencyLabel(_notificationFrequency),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildPrivacySection() => FadeInWidget(
        delay: const Duration(milliseconds: 300),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Конфиденциальность',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildListTile(
                  title: 'Политика конфиденциальности',
                  subtitle: 'Ознакомиться с политикой',
                  icon: Icons.privacy_tip,
                  onTap: () {
                    // TODO: Открыть политику конфиденциальности
                  },
                ),
                _buildListTile(
                  title: 'Условия использования',
                  subtitle: 'Ознакомиться с условиями',
                  icon: Icons.description,
                  onTap: () {
                    // TODO: Открыть условия использования
                  },
                ),
                _buildListTile(
                  title: 'Управление данными',
                  subtitle: 'Экспорт и удаление данных',
                  icon: Icons.data_usage,
                  onTap: () {
                    // TODO: Открыть управление данными
                  },
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildSecuritySection() => FadeInWidget(
        delay: const Duration(milliseconds: 400),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Безопасность',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSwitchTile(
                  title: 'Двухфакторная аутентификация',
                  subtitle: 'Дополнительная защита аккаунта',
                  value: _twoFactorEnabled,
                  onChanged: (value) {
                    setState(() {
                      _twoFactorEnabled = value;
                    });
                    if (value) {
                      _showTwoFactorSetup();
                    }
                  },
                ),
                _buildListTile(
                  title: 'Изменить пароль',
                  subtitle: 'Обновить пароль аккаунта',
                  icon: Icons.lock,
                  onTap: _showChangePasswordDialog,
                ),
                _buildListTile(
                  title: 'История входов',
                  subtitle: 'Просмотр активности аккаунта',
                  icon: Icons.history,
                  onTap: () {
                    // TODO: Открыть историю входов
                  },
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildMonetizationSection() => FadeInWidget(
        delay: const Duration(milliseconds: 500),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Монетизация',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildListTile(
                  title: 'PRO Подписка',
                  subtitle: 'Расширенные возможности для специалистов',
                  icon: Icons.star,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProSubscriptionScreen(
                          userId:
                              'current_user_id', // TODO: Получить реальный ID пользователя
                        ),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  title: 'Реклама',
                  subtitle: 'Создать рекламное объявление',
                  icon: Icons.campaign,
                  onTap: _showCreateAdDialog,
                ),
                _buildListTile(
                  title: 'Статистика доходов',
                  subtitle: 'Просмотр аналитики',
                  icon: Icons.analytics,
                  onTap: () {
                    // TODO: Открыть статистику доходов
                  },
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildAccountSection() => FadeInWidget(
        delay: const Duration(milliseconds: 600),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Аккаунт',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildListTile(
                  title: 'Временно деактивировать',
                  subtitle: 'Временно отключить аккаунт',
                  icon: Icons.pause_circle,
                  onTap: _showDeactivateDialog,
                ),
                _buildListTile(
                  title: 'Удалить аккаунт',
                  subtitle: 'Безвозвратно удалить аккаунт',
                  icon: Icons.delete_forever,
                  textColor: Colors.red,
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildAboutSection() => FadeInWidget(
        delay: const Duration(milliseconds: 700),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'О приложении',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildListTile(
                  title: 'Версия',
                  subtitle: '1.0.0',
                  icon: Icons.info,
                  onTap: () {
                    // TODO: Показать информацию о версии
                  },
                ),
                _buildListTile(
                  title: 'Обратная связь',
                  subtitle: 'Сообщить о проблеме',
                  icon: Icons.feedback,
                  onTap: () {
                    // TODO: Открыть форму обратной связи
                  },
                ),
                _buildListTile(
                  title: 'Выйти',
                  subtitle: 'Выйти из аккаунта',
                  icon: Icons.logout,
                  textColor: Colors.red,
                  onTap: _showLogoutDialog,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      );

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
  }) =>
      ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
      );

  String _getNotificationFrequencyLabel(double value) {
    if (value <= 0.2) return 'Редко';
    if (value <= 0.4) return 'Иногда';
    if (value <= 0.6) return 'Обычно';
    if (value <= 0.8) return 'Часто';
    return 'Всегда';
  }

  void _showTwoFactorSetup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройка 2FA'),
        content: const Text(
          'Двухфакторная аутентификация будет настроена в следующей версии приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить пароль'),
        content: const Text(
          'Функция изменения пароля будет доступна в следующей версии приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Деактивация аккаунта'),
        content: const Text(
          'Вы уверены, что хотите временно деактивировать аккаунт? Вы сможете восстановить его позже.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Деактивировать аккаунт
            },
            child: const Text('Деактивировать'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление аккаунта'),
        content: const Text(
          'ВНИМАНИЕ! Это действие необратимо. Все ваши данные будут удалены навсегда.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Удалить аккаунт
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Выйти из аккаунта
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _showCreateAdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать рекламу'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: CreateAdvertisementWidget(
            advertiserId:
                'current_user_id', // TODO: Получить реальный ID пользователя
            onCreated: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Реклама создана успешно!'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  /// Секция расширенных функций
  Widget _buildAdvancedSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Расширенные функции',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Тестирование и мониторинг
              ListTile(
                leading: const Icon(Icons.analytics, color: Colors.blue),
                title: const Text('Тестирование и мониторинг'),
                subtitle: const Text('Производительность, ошибки, оптимизация'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TestingMonitoringScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              // Организаторы мероприятий
              ListTile(
                leading: const Icon(Icons.business, color: Colors.purple),
                title: const Text('Организаторы мероприятий'),
                subtitle: const Text('Управление событиями и заказами'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EventOrganizerScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              // Календарь и напоминания
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                title: const Text('Календарь и напоминания'),
                subtitle: const Text('События, синхронизация, уведомления'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CalendarRemindersScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
}

/// Опция языка
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });

  final String code;
  final String name;
  final String flag;
}

/// Опция темы
class ThemeOption {
  const ThemeOption({
    required this.code,
    required this.name,
    required this.icon,
  });

  final String code;
  final String name;
  final IconData icon;
}
