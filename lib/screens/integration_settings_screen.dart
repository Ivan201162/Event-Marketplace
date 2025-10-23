import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connection_settings_screen.dart';
import 'integrations_screen.dart';
import 'location_settings_screen.dart';
import 'sharing_settings_screen.dart';

/// Экран настроек интеграций
class IntegrationSettingsScreen extends ConsumerWidget {
  const IntegrationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Интеграции')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Основные интеграции
            _buildSection(
              title: 'Основные интеграции',
              children: [
                _buildSettingsTile(
                  icon: Icons.extension,
                  title: 'Все интеграции',
                  subtitle: 'Управление всеми доступными интеграциями',
                  onTap: () =>
                      _navigateToScreen(context, const IntegrationsScreen()),
                ),
                _buildSettingsTile(
                  icon: Icons.location_on,
                  title: 'Геолокация',
                  subtitle: 'Настройки определения местоположения',
                  onTap: () => _navigateToScreen(
                      context, const LocationSettingsScreen()),
                ),
                _buildSettingsTile(
                  icon: Icons.share,
                  title: 'Шаринг',
                  subtitle: 'Настройки совместного использования контента',
                  onTap: () =>
                      _navigateToScreen(context, const SharingSettingsScreen()),
                ),
                _buildSettingsTile(
                  icon: Icons.wifi,
                  title: 'Подключение',
                  subtitle: 'Настройки сетевого подключения',
                  onTap: () => _navigateToScreen(
                      context, const ConnectionSettingsScreen()),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Дополнительные интеграции
            _buildSection(
              title: 'Дополнительные интеграции',
              children: [
                _buildSettingsTile(
                  icon: Icons.payment,
                  title: 'Платежные системы',
                  subtitle: 'Интеграция с платежными сервисами',
                  onTap: () => _showComingSoon(context, 'Платежные системы'),
                ),
                _buildSettingsTile(
                  icon: Icons.calendar_today,
                  title: 'Календарь',
                  subtitle: 'Синхронизация с календарными приложениями',
                  onTap: () => _showComingSoon(context, 'Календарь'),
                ),
                _buildSettingsTile(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: 'Настройки электронной почты',
                  onTap: () => _showComingSoon(context, 'Email'),
                ),
                _buildSettingsTile(
                  icon: Icons.sms,
                  title: 'SMS',
                  subtitle: 'Настройки SMS уведомлений',
                  onTap: () => _showComingSoon(context, 'SMS'),
                ),
                _buildSettingsTile(
                  icon: Icons.analytics,
                  title: 'Аналитика',
                  subtitle: 'Интеграция с аналитическими сервисами',
                  onTap: () => _showComingSoon(context, 'Аналитика'),
                ),
                _buildSettingsTile(
                  icon: Icons.cloud,
                  title: 'Облачное хранилище',
                  subtitle: 'Синхронизация с облачными сервисами',
                  onTap: () => _showComingSoon(context, 'Облачное хранилище'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Социальные сети
            _buildSection(
              title: 'Социальные сети',
              children: [
                _buildSettingsTile(
                  icon: Icons.facebook,
                  title: 'Facebook',
                  subtitle: 'Интеграция с Facebook',
                  onTap: () => _showComingSoon(context, 'Facebook'),
                ),
                _buildSettingsTile(
                  icon: Icons.camera_alt,
                  title: 'Instagram',
                  subtitle: 'Интеграция с Instagram',
                  onTap: () => _showComingSoon(context, 'Instagram'),
                ),
                _buildSettingsTile(
                  icon: Icons.chat,
                  title: 'Telegram',
                  subtitle: 'Интеграция с Telegram',
                  onTap: () => _showComingSoon(context, 'Telegram'),
                ),
                _buildSettingsTile(
                  icon: Icons.video_call,
                  title: 'WhatsApp',
                  subtitle: 'Интеграция с WhatsApp',
                  onTap: () => _showComingSoon(context, 'WhatsApp'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Помощь и поддержка
            _buildSection(
              title: 'Помощь и поддержка',
              children: [
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Справка по интеграциям',
                  subtitle: 'Как настроить и использовать интеграции',
                  onTap: () =>
                      _showComingSoon(context, 'Справка по интеграциям'),
                ),
                _buildSettingsTile(
                  icon: Icons.bug_report,
                  title: 'Сообщить об ошибке',
                  subtitle: 'Сообщить о проблеме с интеграцией',
                  onTap: () => _showComingSoon(context, 'Сообщить об ошибке'),
                ),
                _buildSettingsTile(
                  icon: Icons.feedback,
                  title: 'Обратная связь',
                  subtitle: 'Предложить улучшение интеграций',
                  onTap: () => _showComingSoon(context, 'Обратная связь'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSection(
          {required String title, required List<Widget> children}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      );

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => screen));
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скоро будет доступно'),
        content: Text(
            'Функция "$feature" будет доступна в следующих обновлениях приложения.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно')),
        ],
      ),
    );
  }
}
