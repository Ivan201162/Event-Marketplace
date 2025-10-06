import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для проверки обновлений приложения
class AppUpdateService {
  static const String _lastCheckKey = 'last_update_check';
  static const String _updateInfoKey = 'update_info';
  static const String _dismissedVersionKey = 'dismissed_version';
  static const String _updateCheckUrl =
      'https://api.github.com/repos/your-org/event_marketplace_app/releases/latest';

  /// Проверить наличие обновлений
  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Проверяем, не проверяли ли мы недавно
      final lastCheck = await _getLastCheckTime();
      final now = DateTime.now();
      if (lastCheck != null && now.difference(lastCheck).inHours < 24) {
        // Возвращаем кэшированную информацию
        return await _getCachedUpdateInfo();
      }

      // Получаем информацию о последней версии
      final response = await http.get(
        Uri.parse(_updateCheckUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['tag_name']?.replaceAll('v', '') ?? '';
        final releaseNotes = data['body'] ?? '';
        final downloadUrl = data['assets']?.isNotEmpty == true
            ? data['assets'][0]['browser_download_url']
            : null;

        final updateInfo = UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          isUpdateAvailable: _isNewerVersion(latestVersion, currentVersion),
          checkTime: now,
        );

        // Кэшируем информацию
        await _cacheUpdateInfo(updateInfo);
        await _updateLastCheckTime(now);

        return updateInfo;
      }
    } catch (e) {
      debugPrint('Ошибка проверки обновлений: $e');
    }

    return null;
  }

  /// Принудительная проверка обновлений
  static Future<UpdateInfo?> forceCheckForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(_updateCheckUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['tag_name']?.replaceAll('v', '') ?? '';
        final releaseNotes = data['body'] ?? '';
        final downloadUrl = data['assets']?.isNotEmpty == true
            ? data['assets'][0]['browser_download_url']
            : null;

        final updateInfo = UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          isUpdateAvailable: _isNewerVersion(latestVersion, currentVersion),
          checkTime: DateTime.now(),
        );

        await _cacheUpdateInfo(updateInfo);
        await _updateLastCheckTime(DateTime.now());

        return updateInfo;
      }
    } catch (e) {
      debugPrint('Ошибка принудительной проверки обновлений: $e');
    }

    return null;
  }

  /// Проверить, является ли версия новой
  static bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latest = _parseVersion(latestVersion);
      final current = _parseVersion(currentVersion);

      for (var i = 0; i < 3; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('Ошибка сравнения версий: $e');
      return false;
    }
  }

  /// Парсить версию в массив чисел
  static List<int> _parseVersion(String version) =>
      version.split('.').map((v) => int.tryParse(v) ?? 0).toList();

  /// Получить время последней проверки
  static Future<DateTime?> _getLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastCheckKey);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      debugPrint('Ошибка получения времени последней проверки: $e');
      return null;
    }
  }

  /// Обновить время последней проверки
  static Future<void> _updateLastCheckTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, time.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Ошибка обновления времени проверки: $e');
    }
  }

  /// Кэшировать информацию об обновлении
  static Future<void> _cacheUpdateInfo(UpdateInfo updateInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_updateInfoKey, jsonEncode(updateInfo.toJson()));
    } catch (e) {
      debugPrint('Ошибка кэширования информации об обновлении: $e');
    }
  }

  /// Получить кэшированную информацию об обновлении
  static Future<UpdateInfo?> _getCachedUpdateInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_updateInfoKey);
      if (cached != null) {
        final data = jsonDecode(cached);
        return UpdateInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('Ошибка получения кэшированной информации: $e');
    }
    return null;
  }

  /// Отметить версию как отклоненную
  static Future<void> dismissVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedVersionKey, version);
    } catch (e) {
      debugPrint('Ошибка отметки версии как отклоненной: $e');
    }
  }

  /// Проверить, была ли версия отклонена
  static Future<bool> isVersionDismissed(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(_dismissedVersionKey);
      return dismissed == version;
    } catch (e) {
      debugPrint('Ошибка проверки отклоненной версии: $e');
      return false;
    }
  }

  /// Очистить кэш обновлений
  static Future<void> clearUpdateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastCheckKey);
      await prefs.remove(_updateInfoKey);
      await prefs.remove(_dismissedVersionKey);
    } catch (e) {
      debugPrint('Ошибка очистки кэша обновлений: $e');
    }
  }

  /// Получить информацию о текущей версии
  static Future<PackageInfo> getCurrentVersionInfo() async =>
      PackageInfo.fromPlatform();

  /// Открыть страницу загрузки
  static Future<void> openDownloadPage(String? downloadUrl) async {
    if (downloadUrl != null) {
      // TODO(developer): Реализовать открытие страницы загрузки
      debugPrint('Открытие страницы загрузки: $downloadUrl');
    }
  }

  /// Получить тип обновления
  static UpdateType getUpdateType(String currentVersion, String latestVersion) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(latestVersion);

    if (latest[0] > current[0]) {
      return UpdateType.major;
    } else if (latest[1] > current[1]) {
      return UpdateType.minor;
    } else {
      return UpdateType.patch;
    }
  }
}

/// Информация об обновлении
class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    this.downloadUrl,
    required this.isUpdateAvailable,
    required this.checkTime,
  });

  /// Создать из JSON
  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        currentVersion: json['currentVersion'] ?? '',
        latestVersion: json['latestVersion'] ?? '',
        releaseNotes: json['releaseNotes'] ?? '',
        downloadUrl: json['downloadUrl'],
        isUpdateAvailable: json['isUpdateAvailable'] ?? false,
        checkTime: DateTime.fromMillisecondsSinceEpoch(json['checkTime'] ?? 0),
      );
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String? downloadUrl;
  final bool isUpdateAvailable;
  final DateTime checkTime;

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() => {
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'releaseNotes': releaseNotes,
        'downloadUrl': downloadUrl,
        'isUpdateAvailable': isUpdateAvailable,
        'checkTime': checkTime.millisecondsSinceEpoch,
      };

  /// Получить тип обновления
  UpdateType get updateType =>
      AppUpdateService.getUpdateType(currentVersion, latestVersion);

  /// Получить описание типа обновления
  String get updateTypeDescription {
    switch (updateType) {
      case UpdateType.major:
        return 'Крупное обновление';
      case UpdateType.minor:
        return 'Обновление функций';
      case UpdateType.patch:
        return 'Исправления ошибок';
    }
  }

  /// Получить цвет типа обновления
  int get updateTypeColor {
    switch (updateType) {
      case UpdateType.major:
        return 0xFFE91E63; // Розовый
      case UpdateType.minor:
        return 0xFF2196F3; // Синий
      case UpdateType.patch:
        return 0xFF4CAF50; // Зеленый
    }
  }

  /// Получить время проверки в читаемом виде
  String get formattedCheckTime {
    final now = DateTime.now();
    final difference = now.difference(checkTime);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else {
      return '${difference.inDays} дн. назад';
    }
  }
}

/// Типы обновлений
enum UpdateType {
  major,
  minor,
  patch,
}
