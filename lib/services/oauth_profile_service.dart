import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';
import '../utils/transliterate.dart';

/// Сервис для обработки OAuth пользователей и создания профилей
class OAuthProfileService {
  factory OAuthProfileService() => _instance;
  OAuthProfileService._internal();
  static final OAuthProfileService _instance = OAuthProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Обрабатывает OAuth пользователя и создает профиль если необходимо
  Future<AppUser?> handleOAuthUser(User firebaseUser) async {
    try {
      final userId = firebaseUser.uid;
      final userMetadata =
          firebaseUser.providerData.isNotEmpty ? firebaseUser.providerData.first : null;

      // Получаем данные из метаданных
      final name = _extractName(firebaseUser, userMetadata);
      final avatarUrl = _extractAvatarUrl(firebaseUser, userMetadata);
      final city = _extractCity(userMetadata);
      final email = firebaseUser.email ?? '';

      // Генерируем username
      final username = TransliterateUtils.transliterateNameToUsername(name);

      // Проверяем, существует ли профиль
      final existingProfile = await _getExistingProfile(userId);

      if (existingProfile != null) {
        return existingProfile;
      }

      // Создаем новый профиль
      final newProfile = await _createProfile(
        userId: userId,
        name: name,
        username: username,
        email: email,
        avatarUrl: avatarUrl,
        city: city,
        provider: _getProvider(userMetadata),
      );

      return newProfile;
    } catch (e) {
      print('Ошибка обработки OAuth пользователя: $e');
      return null;
    }
  }

  /// Извлекает имя из данных пользователя
  String _extractName(User firebaseUser, UserInfo? userMetadata) {
    // Пробуем разные источники имени
    final displayName = firebaseUser.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    // Из email (до @)
    final email = firebaseUser.email;
    if (email != null && email.isNotEmpty) {
      final emailName = email.split('@').first;
      if (emailName.isNotEmpty) {
        return emailName.replaceAll(RegExp('[._-]'), ' ');
      }
    }

    return 'Пользователь';
  }

  /// Извлекает URL аватара
  String _extractAvatarUrl(User firebaseUser, UserInfo? userMetadata) {
    final photoUrl = firebaseUser.photoURL;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return photoUrl;
    }
    return '';
  }

  /// Извлекает город из метаданных
  String _extractCity(UserInfo? userMetadata) {
    // Для VK может быть доступен город
    // Для других провайдеров обычно нет
    return '';
  }

  /// Определяет провайдера OAuth
  String _getProvider(UserInfo? userMetadata) {
    if (userMetadata == null) return 'unknown';

    final providerId = userMetadata.providerId;
    switch (providerId) {
      case 'google.com':
        return 'google';
      case 'github.com':
        return 'github';
      case 'vk.com':
        return 'vk';
      default:
        return providerId;
    }
  }

  /// Получает существующий профиль
  Future<AppUser?> _getExistingProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения профиля: $e');
      return null;
    }
  }

  /// Создает новый профиль
  Future<AppUser> _createProfile({
    required String userId,
    required String name,
    required String username,
    required String email,
    required String avatarUrl,
    required String city,
    required String provider,
  }) async {
    try {
      // Проверяем уникальность username
      final uniqueUsername = await _ensureUniqueUsername(username);

      final userData = {
        'id': userId,
        'name': name,
        'username': uniqueUsername,
        'email': email,
        'avatarUrl': avatarUrl,
        'city': city,
        'role': UserRole.customer.name,
        'bio': '',
        'categories': <String>[],
        'rating': 0.0,
        'followersCount': 0,
        'followingCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'provider': provider,
        'isVerified': false,
        'isActive': true,
      };

      await _firestore.collection('users').doc(userId).set(userData);

      return AppUser.fromMap(userData);
    } catch (e) {
      print('Ошибка создания профиля: $e');
      rethrow;
    }
  }

  /// Обеспечивает уникальность username
  Future<String> _ensureUniqueUsername(String baseUsername) async {
    var username = baseUsername;
    var counter = 1;

    while (await _isUsernameTaken(username)) {
      // Убираем старый суффикс если есть
      final parts = username.split('_');
      if (parts.length > 1 && RegExp(r'^\d{4}$').hasMatch(parts.last)) {
        parts.removeLast();
        username = parts.join('_');
      }

      // Добавляем новый суффикс
      username = '${username}_${counter.toString().padLeft(4, '0')}';
      counter++;
    }

    return username;
  }

  /// Проверяет, занят ли username
  Future<bool> _isUsernameTaken(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Ошибка проверки username: $e');
      return false;
    }
  }

  /// Обновляет профиль пользователя
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      print('Ошибка обновления профиля: $e');
      rethrow;
    }
  }

  /// Получает профиль по username
  Future<AppUser?> getProfileByUsername(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return AppUser.fromDocument(query.docs.first);
      }
      return null;
    } catch (e) {
      print('Ошибка получения профиля по username: $e');
      return null;
    }
  }
}
