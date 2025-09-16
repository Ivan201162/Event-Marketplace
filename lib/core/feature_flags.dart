/// Система фичефлагов для безопасного включения/отключения функций
class FeatureFlags {
  // Карты и геолокация
  static const bool mapsEnabled = false;
  static const bool geolocationEnabled = false;

  // Платежи
  static const bool paymentsEnabled = false;
  static const bool subscriptionPaymentsEnabled = false;

  // Продвинутые функции
  static const bool analyticsEnabled = true;
  static const bool pushNotificationsEnabled = true;
  static const bool fileUploadEnabled = true;
  static const bool chatAttachmentsEnabled = true;

  // Админские функции
  static const bool adminPanelEnabled = true;
  static const bool userModerationEnabled = false;

  // Экспорт и шаринг
  static const bool calendarExportEnabled = true;
  static const bool calendarSyncEnabled = false;
  static const bool shareEnabled = true;

  // Подписки
  static const bool subscriptionsEnabled = false;

  // Идеи и коллекции
  static const bool ideasEnabled = false;

  // Гостевой режим
  static const bool guestModeEnabled = false;

  // VK интеграция
  static const bool vkIntegrationEnabled = false;

  // Отслеживание годовщин
  static const bool anniversaryTrackingEnabled = false;

  // Плейлисты диджеев
  static const bool djPlaylistsEnabled = false;

  // Фильтр по занятости
  static const bool availabilityFilterEnabled = false;

  // Предложения по функционалу
  static const bool featureRequestsEnabled = false;

  // Социальные функции
  static const bool socialLoginEnabled = true;
  static const bool vkLoginEnabled = false;

  // Отладка
  static const bool debugMode = true;
  static const bool verboseLogging = false;

  /// Проверить, включена ли функция
  static bool isEnabled(String feature) {
    switch (feature) {
      case 'maps':
        return mapsEnabled;
      case 'geolocation':
        return geolocationEnabled;
      case 'payments':
        return paymentsEnabled;
      case 'subscription_payments':
        return subscriptionPaymentsEnabled;
      case 'analytics':
        return analyticsEnabled;
      case 'push_notifications':
        return pushNotificationsEnabled;
      case 'file_upload':
        return fileUploadEnabled;
      case 'chat_attachments':
        return chatAttachmentsEnabled;
      case 'admin_panel':
        return adminPanelEnabled;
      case 'user_moderation':
        return userModerationEnabled;
      case 'calendar_export':
        return calendarExportEnabled;
      case 'calendar_sync':
        return calendarSyncEnabled;
      case 'share':
        return shareEnabled;
      case 'subscriptions':
        return subscriptionsEnabled;
      case 'ideas':
        return ideasEnabled;
      case 'guest_mode':
        return guestModeEnabled;
      case 'vk_integration':
        return vkIntegrationEnabled;
      case 'anniversary_tracking':
        return anniversaryTrackingEnabled;
      case 'dj_playlists':
        return djPlaylistsEnabled;
      case 'availability_filter':
        return availabilityFilterEnabled;
      case 'feature_requests':
        return featureRequestsEnabled;
      case 'social_login':
        return socialLoginEnabled;
      case 'vk_login':
        return vkLoginEnabled;
      case 'debug':
        return debugMode;
      case 'verbose_logging':
        return verboseLogging;
      default:
        return false;
    }
  }

  /// Получить все включенные функции
  static List<String> getEnabledFeatures() {
    final features = <String>[];

    if (mapsEnabled) features.add('maps');
    if (geolocationEnabled) features.add('geolocation');
    if (paymentsEnabled) features.add('payments');
    if (subscriptionPaymentsEnabled) features.add('subscription_payments');
    if (analyticsEnabled) features.add('analytics');
    if (pushNotificationsEnabled) features.add('push_notifications');
    if (fileUploadEnabled) features.add('file_upload');
    if (chatAttachmentsEnabled) features.add('chat_attachments');
    if (adminPanelEnabled) features.add('admin_panel');
    if (userModerationEnabled) features.add('user_moderation');
    if (calendarExportEnabled) features.add('calendar_export');
    if (calendarSyncEnabled) features.add('calendar_sync');
    if (shareEnabled) features.add('share');
    if (subscriptionsEnabled) features.add('subscriptions');
    if (ideasEnabled) features.add('ideas');
    if (guestModeEnabled) features.add('guest_mode');
    if (vkIntegrationEnabled) features.add('vk_integration');
    if (anniversaryTrackingEnabled) features.add('anniversary_tracking');
    if (djPlaylistsEnabled) features.add('dj_playlists');
    if (availabilityFilterEnabled) features.add('availability_filter');
    if (featureRequestsEnabled) features.add('feature_requests');
    if (socialLoginEnabled) features.add('social_login');
    if (vkLoginEnabled) features.add('vk_login');
    if (debugMode) features.add('debug');
    if (verboseLogging) features.add('verbose_logging');

    return features;
  }

  /// Получить статус всех функций
  static Map<String, bool> getAllFlags() {
    return {
      'maps': mapsEnabled,
      'geolocation': geolocationEnabled,
      'payments': paymentsEnabled,
      'subscription_payments': subscriptionPaymentsEnabled,
      'analytics': analyticsEnabled,
      'push_notifications': pushNotificationsEnabled,
      'file_upload': fileUploadEnabled,
      'chat_attachments': chatAttachmentsEnabled,
      'admin_panel': adminPanelEnabled,
      'user_moderation': userModerationEnabled,
      'calendar_export': calendarExportEnabled,
      'calendar_sync': calendarSyncEnabled,
      'share': shareEnabled,
      'subscriptions': subscriptionsEnabled,
      'ideas': ideasEnabled,
      'guest_mode': guestModeEnabled,
      'vk_integration': vkIntegrationEnabled,
      'anniversary_tracking': anniversaryTrackingEnabled,
      'dj_playlists': djPlaylistsEnabled,
      'availability_filter': availabilityFilterEnabled,
      'feature_requests': featureRequestsEnabled,
      'social_login': socialLoginEnabled,
      'vk_login': vkLoginEnabled,
      'debug': debugMode,
      'verbose_logging': verboseLogging,
    };
  }
}
