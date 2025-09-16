import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/integration_service.dart';

/// Экран настроек шаринга
class SharingSettingsScreen extends ConsumerStatefulWidget {
  const SharingSettingsScreen({super.key});

  @override
  ConsumerState<SharingSettingsScreen> createState() =>
      _SharingSettingsScreenState();
}

class _SharingSettingsScreenState extends ConsumerState<SharingSettingsScreen> {
  final IntegrationService _integrationService = IntegrationService();

  bool _shareEvents = true;
  bool _shareProfile = true;
  bool _shareReviews = true;
  bool _shareIdeas = true;
  bool _shareBookings = false;
  bool _shareAnalytics = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки шаринга'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основные настройки
            _buildMainSettings(),

            const SizedBox(height: 24),

            // Быстрые действия
            _buildQuickActions(),

            const SizedBox(height: 24),

            // Шаблоны шаринга
            _buildSharingTemplates(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Что можно делиться',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // События
            SwitchListTile(
              title: const Text('События'),
              subtitle: const Text('Разрешить делиться событиями'),
              value: _shareEvents,
              onChanged: (value) {
                setState(() {
                  _shareEvents = value;
                });
              },
            ),

            // Профиль
            SwitchListTile(
              title: const Text('Профиль'),
              subtitle: const Text('Разрешить делиться профилем'),
              value: _shareProfile,
              onChanged: (value) {
                setState(() {
                  _shareProfile = value;
                });
              },
            ),

            // Отзывы
            SwitchListTile(
              title: const Text('Отзывы'),
              subtitle: const Text('Разрешить делиться отзывами'),
              value: _shareReviews,
              onChanged: (value) {
                setState(() {
                  _shareReviews = value;
                });
              },
            ),

            // Идеи
            SwitchListTile(
              title: const Text('Идеи'),
              subtitle: const Text('Разрешить делиться идеями'),
              value: _shareIdeas,
              onChanged: (value) {
                setState(() {
                  _shareIdeas = value;
                });
              },
            ),

            // Бронирования
            SwitchListTile(
              title: const Text('Бронирования'),
              subtitle: const Text('Разрешить делиться бронированиями'),
              value: _shareBookings,
              onChanged: (value) {
                setState(() {
                  _shareBookings = value;
                });
              },
            ),

            // Аналитика
            SwitchListTile(
              title: const Text('Аналитика'),
              subtitle: const Text('Разрешить делиться аналитикой'),
              value: _shareAnalytics,
              onChanged: (value) {
                setState(() {
                  _shareAnalytics = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Быстрые действия',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Поделиться приложением
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Поделиться приложением'),
              subtitle: const Text('Пригласить друзей в приложение'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _shareApp,
            ),

            const Divider(),

            // Поделиться профилем
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Поделиться профилем'),
              subtitle: const Text('Поделиться ссылкой на ваш профиль'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _shareProfile,
            ),

            const Divider(),

            // Поделиться событием
            ListTile(
              leading: const Icon(Icons.event, color: Colors.orange),
              title: const Text('Поделиться событием'),
              subtitle: const Text('Поделиться ссылкой на событие'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _shareEvent,
            ),

            const Divider(),

            // Поделиться отзывом
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Поделиться отзывом'),
              subtitle: const Text('Поделиться ссылкой на отзыв'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _shareReview,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingTemplates() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Шаблоны шаринга',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Шаблон для события
            _buildSharingTemplate(
              title: 'Шаблон для события',
              template:
                  'Приглашаю на событие: {eventName}\n{eventDescription}\nДата: {eventDate}\nМесто: {eventLocation}\n\nСкачай приложение Event Marketplace!',
              onEdit: () => _editSharingTemplate('event'),
            ),

            const SizedBox(height: 16),

            // Шаблон для профиля
            _buildSharingTemplate(
              title: 'Шаблон для профиля',
              template:
                  'Привет! Посмотри мой профиль в Event Marketplace: {profileName}\n{profileDescription}\n\nСкачай приложение Event Marketplace!',
              onEdit: () => _editSharingTemplate('profile'),
            ),

            const SizedBox(height: 16),

            // Шаблон для отзыва
            _buildSharingTemplate(
              title: 'Шаблон для отзыва',
              template:
                  'Оставил отзыв о {specialistName} в Event Marketplace:\n{reviewText}\n\nСкачай приложение Event Marketplace!',
              onEdit: () => _editSharingTemplate('review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingTemplate({
    required String title,
    required String template,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: const Text('Изменить'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareApp() async {
    const content = '''
Привет! Я использую отличное приложение Event Marketplace для поиска и организации событий.

Скачай его и присоединяйся:
https://eventmarketplace.com

#EventMarketplace #События #Организация
''';

    final success = await _integrationService.shareContent(content);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось поделиться приложением'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareProfile() async {
    const content = '''
Привет! Посмотри мой профиль в Event Marketplace:

Имя: {profileName}
Описание: {profileDescription}
Рейтинг: {profileRating}

Скачай приложение Event Marketplace!
https://eventmarketplace.com

#EventMarketplace #Профиль
''';

    final success = await _integrationService.shareContent(content);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось поделиться профилем'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareEvent() async {
    const content = '''
Приглашаю на событие в Event Marketplace:

Название: {eventName}
Описание: {eventDescription}
Дата: {eventDate}
Место: {eventLocation}
Цена: {eventPrice}

Скачай приложение Event Marketplace!
https://eventmarketplace.com

#EventMarketplace #Событие
''';

    final success = await _integrationService.shareContent(content);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось поделиться событием'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareReview() async {
    const content = '''
Оставил отзыв о {specialistName} в Event Marketplace:

{reviewText}
Рейтинг: {reviewRating}

Скачай приложение Event Marketplace!
https://eventmarketplace.com

#EventMarketplace #Отзыв
''';

    final success = await _integrationService.shareContent(content);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось поделиться отзывом'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editSharingTemplate(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать шаблон для $type'),
        content:
            const Text('Функция редактирования шаблонов пока не реализована'),
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
