import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'security_settings_screen.dart';
import 'security_audit_screen.dart';

/// Главный экран безопасности
class SecurityMainScreen extends ConsumerWidget {
  const SecurityMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Безопасность'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Основные настройки
          _buildSection(
            title: 'Основные настройки',
            children: [
              _buildSettingsTile(
                icon: Icons.security,
                title: 'Настройки безопасности',
                subtitle: 'Управление аутентификацией и шифрованием',
                onTap: () => _navigateToScreen(context, const SecuritySettingsScreen()),
              ),
              _buildSettingsTile(
                icon: Icons.audit,
                title: 'Аудит безопасности',
                subtitle: 'Просмотр событий безопасности',
                onTap: () => _navigateToScreen(context, const SecurityAuditScreen()),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Быстрые действия
          _buildSection(
            title: 'Быстрые действия',
            children: [
              _buildQuickActionTile(
                icon: Icons.fingerprint,
                title: 'Биометрическая аутентификация',
                subtitle: 'Настроить отпечаток пальца или Face ID',
                color: Colors.purple,
                onTap: () => _setupBiometricAuth(context),
              ),
              _buildQuickActionTile(
                icon: Icons.pin,
                title: 'PIN-код',
                subtitle: 'Установить или изменить PIN-код',
                color: Colors.teal,
                onTap: () => _setupPinCode(context),
              ),
              _buildQuickActionTile(
                icon: Icons.lock,
                title: 'Двухфакторная аутентификация',
                subtitle: 'Дополнительная защита аккаунта',
                color: Colors.indigo,
                onTap: () => _setupTwoFactorAuth(context),
              ),
              _buildQuickActionTile(
                icon: Icons.devices,
                title: 'Управление устройствами',
                subtitle: 'Просмотр и управление подключенными устройствами',
                color: Colors.cyan,
                onTap: () => _manageDevices(context),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Статистика безопасности
          _buildSection(
            title: 'Статистика безопасности',
            children: [
              _buildSecurityStatsCard(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Рекомендации
          _buildSection(
            title: 'Рекомендации по безопасности',
            children: [
              _buildRecommendationsCard(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Информация
          _buildSection(
            title: 'Информация',
            children: [
              _buildInfoCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSecurityStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Общая статистика',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Статистика по типам событий
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.login,
                    title: 'Входы',
                    value: '12',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.security,
                    title: 'Аутентификация',
                    value: '8',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.warning,
                    title: 'Предупреждения',
                    value: '2',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Уровень безопасности
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Высокий уровень безопасности',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Все основные меры защиты активны',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '95%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Рекомендации',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Рекомендации
            _buildRecommendationItem(
              icon: Icons.fingerprint,
              title: 'Включить биометрическую аутентификацию',
              description: 'Используйте отпечаток пальца или Face ID для быстрого и безопасного входа',
              action: 'Включить',
              onAction: () => _setupBiometricAuth(context),
            ),
            
            const Divider(),
            
            _buildRecommendationItem(
              icon: Icons.pin,
              title: 'Установить PIN-код',
              description: 'Добавьте дополнительный уровень защиты с помощью PIN-кода',
              action: 'Установить',
              onAction: () => _setupPinCode(context),
            ),
            
            const Divider(),
            
            _buildRecommendationItem(
              icon: Icons.lock,
              title: 'Включить двухфакторную аутентификацию',
              description: 'Защитите свой аккаунт с помощью двухфакторной аутентификации',
              action: 'Включить',
              onAction: () => _setupTwoFactorAuth(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required String title,
    required String description,
    required String action,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          TextButton(
            onPressed: onAction,
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'О безопасности',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Приложение использует современные методы защиты для обеспечения безопасности ваших данных:',
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 12),
            
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Шифрование AES-256 для всех данных'),
                Text('• Биометрическая аутентификация'),
                Text('• Безопасное хранилище ключей'),
                Text('• Аудит всех событий безопасности'),
                Text('• Управление подключенными устройствами'),
                Text('• Автоматическая блокировка приложения'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Все ваши данные защищены и никогда не передаются третьим лицам без вашего согласия.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _setupBiometricAuth(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Биометрическая аутентификация'),
        content: const Text('Перейти к настройкам биометрической аутентификации?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToScreen(context, const SecuritySettingsScreen());
            },
            child: const Text('Настроить'),
          ),
        ],
      ),
    );
  }

  void _setupPinCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN-код'),
        content: const Text('Перейти к настройкам PIN-кода?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToScreen(context, const SecuritySettingsScreen());
            },
            child: const Text('Настроить'),
          ),
        ],
      ),
    );
  }

  void _setupTwoFactorAuth(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Двухфакторная аутентификация'),
        content: const Text('Функция двухфакторной аутентификации будет доступна в следующих обновлениях.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _manageDevices(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Управление устройствами'),
        content: const Text('Функция управления устройствами будет доступна в следующих обновлениях.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}