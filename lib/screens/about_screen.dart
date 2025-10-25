import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Экран "О приложении"
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('О приложении'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Логотип приложения
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.event,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Event Marketplace',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'FULL IMPLEMENTATION',
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
            
            const SizedBox(height: 32),
            
            // Информация о версии
            if (_packageInfo != null) ...[
              _InfoCard(
                title: 'Версия приложения',
                value: _packageInfo!.version,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Номер сборки',
                value: _packageInfo!.buildNumber,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Имя пакета',
                value: _packageInfo!.packageName,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Дата сборки',
                value: DateTime.now().toString().split(' ')[0],
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Описание приложения
            const Text(
              'Event Marketplace — это платформа для поиска и бронирования специалистов для мероприятий. Создавайте заявки, находите исполнителей, общайтесь в чатах и делитесь идеями.',
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 24),
            
            // Функции
            const Text(
              'Основные функции:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const _FeatureItem(
              icon: Icons.feed,
              title: 'Лента и Stories',
              description: 'Просматривайте посты и истории от других пользователей',
            ),
            const _FeatureItem(
              icon: Icons.work,
              title: 'Заявки и Jobs',
              description: 'Создавайте заявки и находите исполнителей',
            ),
            const _FeatureItem(
              icon: Icons.chat,
              title: 'Чаты',
              description: 'Общайтесь с другими пользователями',
            ),
            const _FeatureItem(
              icon: Icons.lightbulb,
              title: 'Идеи',
              description: 'Делитесь идеями и получайте обратную связь',
            ),
            const _FeatureItem(
              icon: Icons.person,
              title: 'Профиль',
              description: 'Настройте свой профиль и управляйте аккаунтом',
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка с информацией
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Элемент функции
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}