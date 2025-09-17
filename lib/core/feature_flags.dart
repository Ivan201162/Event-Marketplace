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
  static const bool crashlyticsEnabled = true;
  static const bool performanceMonitoringEnabled = true;

  // Админские функции
  static const bool adminPanelEnabled = true;
  static const bool userModerationEnabled = false;

  // Экспорт и шаринг
  static const bool calendarExportEnabled = true;
  static const bool calendarSyncEnabled = false;
  static const bool shareEnabled = true;

  // Подписки
  static const bool subscriptionsEnabled = false;

  // Отзывы
  static const bool reviewsEnabled = true;

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

  // Автоматическое формирование договоров
  static const bool contractsEnabled = false;

  // Социальные функции
  static const bool socialLoginEnabled = true;
  static const bool vkLoginEnabled = false;
  static const bool socialPostsEnabled = true;
  static const bool storiesEnabled = true;
  static const bool audioMessagesEnabled = true;
  static const bool callsEnabled = false; // включим позже (WebRTC)
  static const bool arPreviewsEnabled = false; // включим позже

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
      case 'crashlytics':
        return crashlyticsEnabled;
      case 'performance_monitoring':
        return performanceMonitoringEnabled;
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
      case 'reviews':
        return reviewsEnabled;
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
      case 'contracts':
        return contractsEnabled;
      case 'social_login':
        return socialLoginEnabled;
      case 'vk_login':
        return vkLoginEnabled;
      case 'social_posts':
        return socialPostsEnabled;
      case 'stories':
        return storiesEnabled;
      case 'audio_messages':
        return audioMessagesEnabled;
      case 'calls':
        return callsEnabled;
      case 'ar_previews':
        return arPreviewsEnabled;
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
    if (crashlyticsEnabled) features.add('crashlytics');
    if (performanceMonitoringEnabled) features.add('performance_monitoring');
    if (adminPanelEnabled) features.add('admin_panel');
    if (userModerationEnabled) features.add('user_moderation');
    if (calendarExportEnabled) features.add('calendar_export');
    if (calendarSyncEnabled) features.add('calendar_sync');
    if (shareEnabled) features.add('share');
    if (subscriptionsEnabled) features.add('subscriptions');
    if (reviewsEnabled) features.add('reviews');
    if (ideasEnabled) features.add('ideas');
    if (guestModeEnabled) features.add('guest_mode');
    if (vkIntegrationEnabled) features.add('vk_integration');
    if (anniversaryTrackingEnabled) features.add('anniversary_tracking');
    if (djPlaylistsEnabled) features.add('dj_playlists');
    if (availabilityFilterEnabled) features.add('availability_filter');
    if (featureRequestsEnabled) features.add('feature_requests');
    if (contractsEnabled) features.add('contracts');
    if (socialLoginEnabled) features.add('social_login');
    if (vkLoginEnabled) features.add('vk_login');
    if (socialPostsEnabled) features.add('social_posts');
    if (storiesEnabled) features.add('stories');
    if (audioMessagesEnabled) features.add('audio_messages');
    if (callsEnabled) features.add('calls');
    if (arPreviewsEnabled) features.add('ar_previews');
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
      'crashlytics': crashlyticsEnabled,
      'performance_monitoring': performanceMonitoringEnabled,
      'admin_panel': adminPanelEnabled,
      'user_moderation': userModerationEnabled,
      'calendar_export': calendarExportEnabled,
      'calendar_sync': calendarSyncEnabled,
      'share': shareEnabled,
      'subscriptions': subscriptionsEnabled,
      'reviews': reviewsEnabled,
      'ideas': ideasEnabled,
      'guest_mode': guestModeEnabled,
      'vk_integration': vkIntegrationEnabled,
      'anniversary_tracking': anniversaryTrackingEnabled,
      'dj_playlists': djPlaylistsEnabled,
      'availability_filter': availabilityFilterEnabled,
      'feature_requests': featureRequestsEnabled,
      'contracts': contractsEnabled,
      'social_login': socialLoginEnabled,
      'vk_login': vkLoginEnabled,
      'social_posts': socialPostsEnabled,
      'stories': storiesEnabled,
      'audio_messages': audioMessagesEnabled,
      'calls': callsEnabled,
      'ar_previews': arPreviewsEnabled,
      'debug': debugMode,
      'verbose_logging': verboseLogging,
    };
  }
}
