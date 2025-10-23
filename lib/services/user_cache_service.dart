import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

/// Сервис для кеширования данных пользователя
class UserCacheService {
  static const String _userDataKey = 'cached_user_data';
  static const String _userAvatarKey = 'cached_user_avatar';
  static const String _userSettingsKey = 'cached_user_settings';
  static const String _lastUpdateKey = 'last_user_update';

  /// Кешировать данные пользователя
  static Future<void> cacheUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = jsonEncode(userData);

      await prefs.setString(_userDataKey, userDataJson);
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ User data cached successfully');
    } catch (e) {
      debugPrint('❌ Error caching user data: $e');
    }
  }

  /// Получить кешированные данные пользователя
  static Future<Map<String, dynamic>?> getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(_userDataKey);

      if (userDataJson != null) {
        return jsonDecode(userDataJson) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting cached user data: $e');
      return null;
    }
  }

  /// Кешировать аватар пользователя
  static Future<void> cacheUserAvatar(String avatarUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userAvatarKey, avatarUrl);

      debugPrint('✅ User avatar cached successfully');
    } catch (e) {
      debugPrint('❌ Error caching user avatar: $e');
    }
  }

  /// Получить кешированный аватар
  static Future<String?> getCachedUserAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userAvatarKey);
    } catch (e) {
      debugPrint('❌ Error getting cached user avatar: $e');
      return null;
    }
  }

  /// Кешировать настройки пользователя
  static Future<void> cacheUserSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings);

      await prefs.setString(_userSettingsKey, settingsJson);

      debugPrint('✅ User settings cached successfully');
    } catch (e) {
      debugPrint('❌ Error caching user settings: $e');
    }
  }

  /// Получить кешированные настройки
  static Future<Map<String, dynamic>?> getCachedUserSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_userSettingsKey);

      if (settingsJson != null) {
        return jsonDecode(settingsJson) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting cached user settings: $e');
      return null;
    }
  }

  /// Проверить, нужно ли обновить кеш
  static Future<bool> shouldUpdateCache(
      {Duration maxAge = const Duration(hours: 1)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);

      if (lastUpdate == null) return true;

      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);

      return difference > maxAge;
    } catch (e) {
      debugPrint('❌ Error checking cache age: $e');
      return true;
    }
  }

  /// Очистить кеш пользователя
  static Future<void> clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_userAvatarKey);
      await prefs.remove(_userSettingsKey);
      await prefs.remove(_lastUpdateKey);

      debugPrint('✅ User cache cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing user cache: $e');
    }
  }

  /// Обновить данные пользователя из Firebase
  static Future<Map<String, dynamic>?> updateUserDataFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'emailVerified': user.emailVerified,
        'isAnonymous': user.isAnonymous,
        'metadata': {
          'creationTime': user.metadata.creationTime?.toIso8601String(),
          'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
        },
      };

      await cacheUserData(userData);
      return userData;
    } catch (e) {
      debugPrint('❌ Error updating user data from Firebase: $e');
      return null;
    }
  }

  /// Получить отображаемое имя пользователя
  static Future<String> getDisplayName() async {
    try {
      // Сначала пытаемся получить из кеша
      final cachedData = await getCachedUserData();
      if (cachedData != null) {
        final displayName = cachedData['displayName'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }

      // Если в кеше нет, получаем из Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final displayName = user.displayName;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }

        // Если displayName пустой, используем email
        final email = user.email;
        if (email != null && email.isNotEmpty) {
          return email.split('@')[0];
        }
      }

      return 'Пользователь';
    } catch (e) {
      debugPrint('❌ Error getting display name: $e');
      return 'Пользователь';
    }
  }

  /// Получить URL аватара пользователя
  static Future<String?> getAvatarUrl() async {
    try {
      // Сначала пытаемся получить из кеша
      final cachedAvatar = await getCachedUserAvatar();
      if (cachedAvatar != null && cachedAvatar.isNotEmpty) {
        return cachedAvatar;
      }

      // Если в кеше нет, получаем из Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final photoURL = user.photoURL;
        if (photoURL != null && photoURL.isNotEmpty) {
          await cacheUserAvatar(photoURL);
          return photoURL;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting avatar URL: $e');
      return null;
    }
  }

  /// Получить email пользователя
  static Future<String?> getEmail() async {
    try {
      // Сначала пытаемся получить из кеша
      final cachedData = await getCachedUserData();
      if (cachedData != null) {
        final email = cachedData['email'] as String?;
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }

      // Если в кеше нет, получаем из Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final email = user.email;
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting email: $e');
      return null;
    }
  }

  /// Получить инициалы пользователя
  static Future<String> getInitials() async {
    try {
      final displayName = await getDisplayName();

      if (displayName.isEmpty) return 'П';

      final words = displayName.trim().split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else {
        return displayName[0].toUpperCase();
      }
    } catch (e) {
      debugPrint('❌ Error getting initials: $e');
      return 'П';
    }
  }

  /// Проверить, есть ли кешированные данные
  static Future<bool> hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userDataKey);
    } catch (e) {
      debugPrint('❌ Error checking cached data: $e');
      return false;
    }
  }

  /// Получить размер кеша
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int size = 0;

      final userData = prefs.getString(_userDataKey);
      if (userData != null) size += userData.length;

      final avatar = prefs.getString(_userAvatarKey);
      if (avatar != null) size += avatar.length;

      final settings = prefs.getString(_userSettingsKey);
      if (settings != null) size += settings.length;

      return size;
    } catch (e) {
      debugPrint('❌ Error getting cache size: $e');
      return 0;
    }
  }

  /// Оптимизировать кеш
  static Future<void> optimizeCache() async {
    try {
      final cacheSize = await getCacheSize();
      const maxCacheSize = 1024 * 1024; // 1MB

      if (cacheSize > maxCacheSize) {
        await clearUserCache();
        debugPrint('✅ Cache optimized (cleared due to size)');
      }
    } catch (e) {
      debugPrint('❌ Error optimizing cache: $e');
    }
  }
}
