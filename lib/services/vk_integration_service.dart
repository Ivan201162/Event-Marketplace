import 'package:event_marketplace_app/core/feature_flags.dart';

/// Сервис интеграции с VK для работы с плейлистами
class VkIntegrationService {
  /// Проверить, является ли ссылка валидной ссылкой на VK плейлист
  bool isValidVkPlaylistUrl(String url) {
    if (!FeatureFlags.vkIntegrationEnabled) {
      return false;
    }

    // Паттерны для VK плейлистов
    final patterns = [
      RegExp(r'https?://vk\.com/audio\?id=\d+'),
      RegExp(r'https?://vk\.com/audio\?owner_id=\d+&id=\d+'),
      RegExp(r'https?://vk\.com/audio\?playlist_id=\d+'),
      RegExp(r'https?://vk\.com/audio\?owner_id=\d+&playlist_id=\d+'),
      RegExp(r'https?://m\.vk\.com/audio\?id=\d+'),
      RegExp(r'https?://m\.vk\.com/audio\?owner_id=\d+&id=\d+'),
    ];

    return patterns.any((pattern) => pattern.hasMatch(url));
  }

  /// Извлечь ID плейлиста из URL
  String? extractPlaylistId(String url) {
    if (!isValidVkPlaylistUrl(url)) {
      return null;
    }

    // Извлекаем ID плейлиста из различных форматов URL
    final playlistIdMatch = RegExp(r'playlist_id=(\d+)').firstMatch(url);
    if (playlistIdMatch != null) {
      return playlistIdMatch.group(1);
    }

    final idMatch = RegExp(r'id=(\d+)').firstMatch(url);
    if (idMatch != null) {
      return idMatch.group(1);
    }

    return null;
  }

  /// Извлечь owner_id из URL
  String? extractOwnerId(String url) {
    if (!isValidVkPlaylistUrl(url)) {
      return null;
    }

    final ownerIdMatch = RegExp(r'owner_id=(\d+)').firstMatch(url);
    return ownerIdMatch?.group(1);
  }

  /// Создать стандартизированную ссылку на плейлист
  String? normalizePlaylistUrl(String url) {
    if (!isValidVkPlaylistUrl(url)) {
      return null;
    }

    final playlistId = extractPlaylistId(url);
    final ownerId = extractOwnerId(url);

    if (playlistId == null) {
      return null;
    }

    if (ownerId != null) {
      return 'https://vk.com/audio?owner_id=$ownerId&playlist_id=$playlistId';
    } else {
      return 'https://vk.com/audio?playlist_id=$playlistId';
    }
  }

  /// Получить информацию о плейлисте (заглушка)
  Future<Map<String, dynamic>?> getPlaylistInfo(String url) async {
    if (!FeatureFlags.vkIntegrationEnabled) {
      return null;
    }

    // TODO(developer): Реализовать получение информации о плейлисте через VK API
    // Пока возвращаем заглушку
    final playlistId = extractPlaylistId(url);
    final ownerId = extractOwnerId(url);

    if (playlistId == null) {
      return null;
    }

    return {
      'id': playlistId,
      'ownerId': ownerId,
      'title': 'Плейлист VK',
      'description': 'Музыкальный плейлист из ВКонтакте',
      'trackCount': 0, // TODO(developer): Получить реальное количество треков
      'url': normalizePlaylistUrl(url),
      'thumbnail': null, // TODO(developer): Получить обложку плейлиста
    };
  }

  /// Проверить доступность плейлиста
  Future<bool> isPlaylistAccessible(String url) async {
    if (!FeatureFlags.vkIntegrationEnabled) {
      return false;
    }

    // TODO(developer): Реализовать проверку доступности плейлиста
    // Пока возвращаем true для валидных URL
    return isValidVkPlaylistUrl(url);
  }

  /// Получить треки из плейлиста (заглушка)
  Future<List<Map<String, dynamic>>> getPlaylistTracks(String url) async {
    if (!FeatureFlags.vkIntegrationEnabled) {
      return [];
    }

    // TODO(developer): Реализовать получение треков через VK API
    // Пока возвращаем пустой список
    return [];
  }

  /// Создать ссылку для предпросмотра плейлиста
  String? createPreviewUrl(String url) {
    if (!isValidVkPlaylistUrl(url)) {
      return null;
    }

    // Создаем ссылку для предпросмотра
    final normalizedUrl = normalizePlaylistUrl(url);
    return normalizedUrl;
  }

  /// Валидировать и обработать URL плейлиста
  Map<String, dynamic> validateAndProcessUrl(String url) {
    final isValid = isValidVkPlaylistUrl(url);
    final normalizedUrl = isValid ? normalizePlaylistUrl(url) : null;
    final playlistId = isValid ? extractPlaylistId(url) : null;
    final ownerId = isValid ? extractOwnerId(url) : null;

    return {
      'isValid': isValid,
      'normalizedUrl': normalizedUrl,
      'playlistId': playlistId,
      'ownerId': ownerId,
      'error': isValid ? null : 'Неверный формат ссылки на плейлист VK',
    };
  }

  /// Получить примеры валидных URL плейлистов
  List<String> getExampleUrls() => [
        'https://vk.com/audio?playlist_id=123456789',
        'https://vk.com/audio?owner_id=123456789&playlist_id=987654321',
        'https://m.vk.com/audio?playlist_id=123456789',
      ];
}
