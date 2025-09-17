import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../core/feature_flags.dart';

/// Модель данных VK профиля
class VKProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String? description;
  final List<String> recentPosts;
  final int followersCount;
  final bool isVerified;

  const VKProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.description,
    required this.recentPosts,
    required this.followersCount,
    required this.isVerified,
  });

  /// Создать из Map
  factory VKProfile.fromMap(Map<String, dynamic> data) {
    return VKProfile(
      id: data['id']?.toString() ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      photoUrl: data['photo_200'] ?? data['photo_100'],
      description: data['status'] ?? data['about'],
      recentPosts: List<String>.from(data['recent_posts'] ?? []),
      followersCount: data['followers_count'] ?? 0,
      isVerified: data['verified'] == 1,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'photo_200': photoUrl,
      'status': description,
      'recent_posts': recentPosts,
      'followers_count': followersCount,
      'verified': isVerified ? 1 : 0,
    };
  }

  /// Получить полное имя
  String get fullName => '$firstName $lastName';

  /// Получить отображаемое имя
  String get displayName => fullName;
}

/// Модель VK поста
class VKPost {
  final String id;
  final String text;
  final List<String> attachments;
  final DateTime date;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;

  const VKPost({
    required this.id,
    required this.text,
    required this.attachments,
    required this.date,
    required this.likesCount,
    required this.commentsCount,
    required this.repostsCount,
  });

  /// Создать из Map
  factory VKPost.fromMap(Map<String, dynamic> data) {
    return VKPost(
      id: data['id']?.toString() ?? '',
      text: data['text'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] * 1000),
      likesCount: data['likes']?['count'] ?? 0,
      commentsCount: data['comments']?['count'] ?? 0,
      repostsCount: data['reposts']?['count'] ?? 0,
    );
  }
}

/// Сервис интеграции с VK
class VKIntegrationService {
  static const String _baseUrl = 'https://api.vk.com/method';
  static const String _version = '5.131';

  // В реальном приложении эти ключи должны быть в конфигурации
  static const String _accessToken = 'YOUR_VK_ACCESS_TOKEN';
  static const String _appId = 'YOUR_VK_APP_ID';

  /// Получить профиль VK по ссылке
  Future<VKProfile?> getVKProfileFromUrl(String vkUrl) async {
    if (!FeatureFlags.vkIntegrationEnabled) {
      return null;
    }

    try {
      final userId = _extractUserIdFromUrl(vkUrl);
      if (userId == null) {
        throw Exception('Неверная ссылка VK');
      }

      return await getVKProfile(userId);
    } catch (e) {
      debugPrint('Error getting VK profile from URL: $e');
      return null;
    }
  }

  /// Получить профиль VK по ID
  Future<VKProfile?> getVKProfile(String userId) async {
    if (!FeatureFlags.vkIntegrationEnabled) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/users.get?user_ids=$userId&fields=photo_200,status,about,verified,followers_count&access_token=$_accessToken&v=$_version'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['response'] != null && data['response'].isNotEmpty) {
          final userData = data['response'][0];

          // Получаем последние посты
          final recentPosts = await _getRecentPosts(userId);

          return VKProfile.fromMap({
            ...userData,
            'recent_posts': recentPosts,
          });
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting VK profile: $e');
      return null;
    }
  }

  /// Получить последние посты пользователя
  Future<List<String>> _getRecentPosts(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/wall.get?owner_id=$userId&count=5&access_token=$_accessToken&v=$_version'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['response'] != null && data['response']['items'] != null) {
          final posts = data['response']['items'] as List;
          return posts
              .map((post) => post['text'] as String)
              .where((text) => text.isNotEmpty)
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Error getting recent posts: $e');
      return [];
    }
  }

  /// Извлечь ID пользователя из URL VK
  String? _extractUserIdFromUrl(String url) {
    try {
      // Поддерживаемые форматы:
      // https://vk.com/id123456
      // https://vk.com/username
      // vk.com/id123456
      // vk.com/username

      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');

      if (uri.host.contains('vk.com')) {
        final path = uri.path;

        // Если это ID (id123456)
        if (path.startsWith('/id')) {
          return path.substring(3);
        }

        // Если это username
        if (path.startsWith('/') && path.length > 1) {
          final username = path.substring(1);
          // Для username нужно получить ID через API
          // Пока что возвращаем null, так как это асинхронная операция
          return null;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting user ID from URL: $e');
      return null;
    }
  }

  /// Получить ID пользователя по username
  Future<String?> _getUserIdByUsername(String username) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/users.get?user_ids=$username&access_token=$_accessToken&v=$_version'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['response'] != null && data['response'].isNotEmpty) {
          return data['response'][0]['id']?.toString();
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user ID by username: $e');
      return null;
    }
  }

  /// Обновить профиль специалиста данными из VK
  Future<AppUser> updateSpecialistProfileFromVK(
      AppUser specialist, VKProfile vkProfile) async {
    return specialist.copyWith(
      displayName: vkProfile.displayName,
      photoURL: vkProfile.photoUrl,
      // TODO: Обновить другие поля профиля специалиста
      // description: vkProfile.description,
      // socialProvider: 'vk',
      // socialId: vkProfile.id,
    );
  }

  /// Проверить валидность VK ссылки
  bool isValidVKUrl(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.contains('vk.com') && uri.path.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Получить статистику VK профиля
  Future<Map<String, dynamic>> getVKProfileStats(String userId) async {
    if (!FeatureFlags.vkIntegrationEnabled) {
      return {};
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/users.get?user_ids=$userId&fields=followers_count,counters&access_token=$_accessToken&v=$_version'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['response'] != null && data['response'].isNotEmpty) {
          final userData = data['response'][0];
          final counters = userData['counters'] ?? {};

          return {
            'followers_count': userData['followers_count'] ?? 0,
            'friends_count': counters['friends'] ?? 0,
            'photos_count': counters['photos'] ?? 0,
            'videos_count': counters['videos'] ?? 0,
            'audios_count': counters['audios'] ?? 0,
            'groups_count': counters['groups'] ?? 0,
          };
        }
      }

      return {};
    } catch (e) {
      debugPrint('Error getting VK profile stats: $e');
      return {};
    }
  }

  /// Получить посты пользователя с пагинацией
  Future<List<VKPost>> getVKPosts(String userId,
      {int offset = 0, int count = 10}) async {
    if (!FeatureFlags.vkIntegrationEnabled) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/wall.get?owner_id=$userId&offset=$offset&count=$count&access_token=$_accessToken&v=$_version'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['response'] != null && data['response']['items'] != null) {
          final posts = data['response']['items'] as List;
          return posts.map((post) => VKPost.fromMap(post)).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Error getting VK posts: $e');
      return [];
    }
  }

  /// Создать mock данные для демонстрации
  VKProfile createMockVKProfile() {
    return VKProfile(
      id: '123456789',
      firstName: 'Анна',
      lastName: 'Петрова',
      photoUrl: 'https://via.placeholder.com/200x200/4CAF50/FFFFFF?text=AP',
      description:
          'Фотограф и организатор мероприятий. Создаю незабываемые моменты! 📸✨',
      recentPosts: [
        'Новая фотосессия в студии! Результат превзошел все ожидания 📸',
        'Свадебная церемония в загородном клубе. Эмоции через край! 💒',
        'Мастер-класс по портретной съемке прошел на ура! Спасибо всем участникам 🎓',
        'Подготовка к новому проекту. Скоро покажу результат! 🔥',
        'Выходные в горах с семьей. Перезагрузка перед новыми проектами 🏔️',
      ],
      followersCount: 1250,
      isVerified: true,
    );
  }

  /// Создать mock посты для демонстрации
  List<VKPost> createMockVKPosts() {
    return [
      VKPost(
        id: '1',
        text: 'Новая фотосессия в студии! Результат превзошел все ожидания 📸',
        attachments: ['photo1.jpg'],
        date: DateTime.now().subtract(const Duration(hours: 2)),
        likesCount: 45,
        commentsCount: 12,
        repostsCount: 8,
      ),
      VKPost(
        id: '2',
        text: 'Свадебная церемония в загородном клубе. Эмоции через край! 💒',
        attachments: ['photo2.jpg', 'photo3.jpg'],
        date: DateTime.now().subtract(const Duration(days: 1)),
        likesCount: 78,
        commentsCount: 23,
        repostsCount: 15,
      ),
      VKPost(
        id: '3',
        text:
            'Мастер-класс по портретной съемке прошел на ура! Спасибо всем участникам 🎓',
        attachments: ['photo4.jpg'],
        date: DateTime.now().subtract(const Duration(days: 3)),
        likesCount: 32,
        commentsCount: 8,
        repostsCount: 5,
      ),
    ];
  }
}
