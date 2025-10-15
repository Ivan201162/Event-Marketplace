import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_data/mock_data.dart';

/// Утилита для заполнения локальных данных
class LocalDataSeeder {
  static const String _dataKey = 'local_data_seeded';

  /// Проверяет, были ли уже заполнены данные
  static Future<bool> hasLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dataKey) ?? false;
  }

  /// Заполняет локальные данные
  static Future<void> seedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Проверяем, не заполнены ли уже данные
    if (await hasLocalData()) {
      return;
    }

    // Создаем тестовые данные
    final data = {
      'currentUser': {
        'id': 'user_1',
        'displayName': 'Тестовый Пользователь',
        'email': 'test@example.com',
        'avatarUrl':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        'city': 'Москва',
        'phone': '+7 (999) 123-45-67',
      },
      'specialists': MockData.specialists.map((s) => s.toJson()).toList(),
      'events': MockData.events.map((e) => e.toJson()).toList(),
      'reviews': MockData.reviews.map((r) => r.toJson()).toList(),
      'feedPosts': MockData.feedPosts.map((p) => p.toJson()).toList(),
      'ideas': MockData.ideas.map((i) => i.toJson()).toList(),
      'requests': [
        {
          'id': 'req_1',
          'title': 'Нужен фотограф на свадьбу',
          'description': 'Ищем профессионального фотографа на свадьбу 15 июня',
          'budget': 50000,
          'status': 'active',
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'req_2',
          'title': 'DJ для корпоратива',
          'description': 'Требуется DJ для корпоративного мероприятия',
          'budget': 25000,
          'status': 'pending',
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        },
      ],
      'chats': [
        {
          'id': 'chat_1',
          'participantId': 'specialist_1',
          'participantName': 'Анна Петрова',
          'participantAvatar':
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
          'lastMessage': 'Здравствуйте! Интересует ваша услуга',
          'lastMessageTime': DateTime.now()
              .subtract(const Duration(minutes: 5))
              .toIso8601String(),
          'unreadCount': 2,
        },
        {
          'id': 'chat_2',
          'participantId': 'specialist_2',
          'participantName': 'Михаил Смирнов',
          'participantAvatar':
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          'lastMessage': 'Спасибо за заказ!',
          'lastMessageTime': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'unreadCount': 0,
        },
      ],
    };

    // Сохраняем данные
    await prefs.setString('local_data', jsonEncode(data));
    await prefs.setBool(_dataKey, true);
  }

  /// Загружает локальные данные
  static Future<Map<String, dynamic>?> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('local_data');

    if (dataString == null) {
      return null;
    }

    try {
      return jsonDecode(dataString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Очищает локальные данные
  static Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_data');
    await prefs.remove(_dataKey);
  }
}
