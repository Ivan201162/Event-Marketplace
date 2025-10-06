import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/app_constants.dart';

/// Экран "О приложении"
class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('О приложении'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Логотип приложения
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event,
                  size: 60,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),

              const SizedBox(height: 24),

              // Название приложения
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              // Версия приложения
              if (_packageInfo != null) ...[
                Text(
                  'Версия ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
              ],

              // Описание приложения
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Описание',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Event Marketplace - это платформа для поиска и бронирования '
                        'специалистов для различных мероприятий. Найдите идеального '
                        'ведущего, фотографа, музыканта или другого специалиста для '
                        'вашего события.',
                        style: TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Основные функции
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Основные функции',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        context,
                        Icons.search,
                        'Поиск специалистов',
                        'Найдите подходящего специалиста по категории, местоположению и отзывам',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.event,
                        'Бронирование',
                        'Забронируйте специалиста на удобное время и дату',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.chat,
                        'Общение',
                        'Общайтесь с специалистами через встроенный чат',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.star,
                        'Отзывы',
                        'Оставляйте отзывы и читайте мнения других пользователей',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.payment,
                        'Платежи',
                        'Безопасная система оплаты услуг',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Информация о разработчике
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Информация о разработчике',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Разработчик',
                        'Event Marketplace Team',
                      ),
                      _buildInfoRow(
                        context,
                        'Email',
                        'support@eventmarketplace.com',
                      ),
                      _buildInfoRow(
                        context,
                        'Веб-сайт',
                        'www.eventmarketplace.com',
                      ),
                      _buildInfoRow(context, 'Поддержка', '24/7'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Кнопки действий
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showPrivacyPolicy,
                      icon: const Icon(Icons.privacy_tip),
                      label: const Text('Политика конфиденциальности'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showTermsOfService,
                      icon: const Icon(Icons.description),
                      label: const Text('Условия использования'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showOpenSourceLicenses,
                      icon: const Icon(Icons.code),
                      label: const Text('Лицензии'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Копирайт
              Text(
                '© 2024 Event Marketplace. Все права защищены.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      );

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
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
          ],
        ),
      );

  Widget _buildInfoRow(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Политика конфиденциальности'),
        content: const SingleChildScrollView(
          child: Text(
            'Здесь будет размещена политика конфиденциальности приложения. '
            'Этот документ описывает, как мы собираем, используем и защищаем '
            'вашу личную информацию.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Условия использования'),
        content: const SingleChildScrollView(
          child: Text(
            'Здесь будут размещены условия использования приложения. '
            'Этот документ описывает правила и условия использования '
            'нашей платформы.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showOpenSourceLicenses() {
    showLicensePage(context: context);
  }
}
