import 'package:flutter/material.dart';
import 'security_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'blocked_users_screen.dart';
import 'feedback_screen.dart';
import '../../widgets/common/custom_app_bar.dart';

/// Главный экран настроек
class SettingsMainScreen extends StatelessWidget {
  const SettingsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Настройки'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Профиль
          _buildProfileSection(context),
          const SizedBox(height: 16),

          // Безопасность
          _buildSecuritySection(context),
          const SizedBox(height: 16),

          // Внешний вид
          _buildAppearanceSection(context),
          const SizedBox(height: 16),

          // Уведомления
          _buildNotificationsSection(context),
          const SizedBox(height: 16),

          // Конфиденциальность
          _buildPrivacySection(context),
          const SizedBox(height: 16),

          // PRO-аккаунт
          _buildProAccountSection(context),
          const SizedBox(height: 16),

          // Блокировки
          _buildBlockingSection(context),
          const SizedBox(height: 16),

          // Обратная связь
          _buildFeedbackSection(context),
          const SizedBox(height: 16),

          // О приложении
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Card(
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
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Редактировать профиль'),
              subtitle: const Text('Имя, биография, аватарка, видео'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).pushNamed('/edit-profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.green),
              title: const Text('Предпросмотр профиля'),
              subtitle: const Text('Как видят ваш профиль другие'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showInfoSnackBar(
                    context, 'Предпросмотр профиля будет реализован');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return Card(
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
            ListTile(
              leading: const Icon(Icons.security, color: Colors.red),
              title: const Text('Безопасность аккаунта'),
              subtitle: const Text('Пароль, 2FA, сессии, история входов'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SecuritySettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return Card(
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
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.purple),
              title: const Text('Темы и оформление'),
              subtitle: const Text('Темы, шрифты, анимации'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppearanceSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Card(
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
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text('Настройки уведомлений'),
              subtitle: const Text('Push, email, тихие часы'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return Card(
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
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.blue),
              title: const Text('Настройки приватности'),
              subtitle:
                  const Text('Кто может писать, комментировать, упоминать'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProAccountSection(BuildContext context) {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'PRO-аккаунт',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text('PRO-функции'),
              subtitle: const Text('Монетизация, аналитика, продвижение'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).pushNamed('/pro-account');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Блокировки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Заблокированные пользователи'),
              subtitle: const Text('Управление заблокированными'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BlockedUsersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Поддержка',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.green),
              title: const Text('Обратная связь'),
              subtitle: const Text('Сообщить о проблеме, предложить функцию'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
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
            ListTile(
              leading: const Icon(Icons.info, color: Colors.grey),
              title: const Text('Версия приложения'),
              subtitle: const Text('1.0.0'),
              onTap: () {
                _showInfoSnackBar(context, 'Версия 1.0.0');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.blue),
              title: const Text('Помощь'),
              subtitle: const Text('FAQ и инструкции'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showInfoSnackBar(context, 'Помощь будет реализована');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.orange),
              title: const Text('Условия использования'),
              subtitle: const Text('Пользовательское соглашение'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showInfoSnackBar(
                    context, 'Условия использования будут реализованы');
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.purple),
              title: const Text('Политика конфиденциальности'),
              subtitle: const Text('Обработка персональных данных'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showInfoSnackBar(
                    context, 'Политика конфиденциальности будет реализована');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
