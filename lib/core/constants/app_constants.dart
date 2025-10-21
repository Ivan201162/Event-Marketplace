/// Константы приложения
class AppConstants {
  // Основная информация
  static const String appName = 'Event Marketplace';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appDescription =
      'Маркетплейс для поиска и бронирования специалистов для мероприятий';

  // Контакты
  static const String supportEmail = 'support@eventmarketplace.app';
  static const String supportPhone = '+7 (800) 123-45-67';
  static const String websiteUrl = 'https://eventmarketplace.app';

  // Социальные сети
  static const String telegramUrl = 'https://t.me/eventmarketplace';
  static const String instagramUrl = 'https://instagram.com/eventmarketplace';
  static const String vkUrl = 'https://vk.com/eventmarketplace';

  // Настройки по умолчанию
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int defaultTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Ограничения
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 100;
  static const int maxFileSizeMB = 50;
  static const int maxMessageLength = 1000;
  static const int maxDescriptionLength = 5000;
  static const int maxTagsCount = 10;

  // Время кэширования (в секундах)
  static const int cacheExpirationSeconds = 300; // 5 минут
  static const int longCacheExpirationSeconds = 3600; // 1 час
  static const int veryLongCacheExpirationSeconds = 86400; // 24 часа

  // Интервалы обновления
  static const int refreshIntervalSeconds = 60;
  static const int syncIntervalSeconds = 300; // 5 минут
  static const int backupIntervalHours = 24;

  // Цены и лимиты
  static const double minPrice = 0;
  static const double maxPrice = 1000000;
  static const int maxBookingsPerDay = 10;
  static const int maxReviewsPerUser = 100;

  // Безопасность
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
  static const int sessionTimeoutMinutes = 60;
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;

  // Уведомления
  static const int maxNotificationsPerDay = 50;
  static const int notificationRetentionDays = 30;
  static const int pushNotificationRetentionDays = 7;

  // Аналитика
  static const int analyticsBatchSize = 100;
  static const int analyticsFlushIntervalSeconds = 30;
  static const int maxAnalyticsEventsPerSession = 1000;

  // Производительность
  static const int maxConcurrentRequests = 10;
  static const int requestTimeoutSeconds = 30;
  static const int maxMemoryUsageMB = 512;

  // Интеграции
  static const int maxIntegrationsPerUser = 10;
  static const int integrationSyncTimeoutSeconds = 60;
  static const int maxIntegrationRetries = 3;

  // Контент
  static const int maxMediaFilesPerUser = 1000;
  static const int maxGalleriesPerUser = 50;
  static const int maxMediaProcessingTimeSeconds = 300;

  // Пользователи
  static const int maxUsersPerPage = 100;
  static const int maxUserSearchResults = 500;
  static const int maxUserActionsHistory = 1000;

  // Настройки
  static const int maxSettingsPerCategory = 1000;
  static const int maxConfigurationVersions = 10;
  static const int settingsHistoryRetentionDays = 90;

  // Форматы файлов
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
  static const List<String> supportedVideoFormats = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'];
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'ogg', 'aac', 'm4a'];
  static const List<String> supportedDocumentFormats = ['pdf', 'doc', 'docx', 'txt', 'rtf'];

  // Размеры изображений
  static const int thumbnailSize = 150;
  static const int mediumImageSize = 500;
  static const int largeImageSize = 1200;
  static const int maxImageWidth = 2048;
  static const int maxImageHeight = 2048;

  // Качество сжатия
  static const int imageCompressionQuality = 85;
  static const int videoCompressionQuality = 80;
  static const int audioCompressionQuality = 90;

  // Геолокация
  static const double defaultLatitude = 55.7558; // Москва
  static const double defaultLongitude = 37.6176;
  static const double defaultRadiusKm = 50;
  static const double maxRadiusKm = 500;

  // Валюты
  static const String defaultCurrency = 'RUB';
  static const List<String> supportedCurrencies = ['RUB', 'USD', 'EUR', 'KZT'];

  // Языки
  static const String defaultLanguage = 'ru';
  static const List<String> supportedLanguages = ['ru', 'en', 'kk'];

  // Часовые пояса
  static const String defaultTimezone = 'Europe/Moscow';
  static const List<String> supportedTimezones = [
    'Europe/Moscow',
    'Europe/London',
    'America/New_York',
    'Asia/Almaty',
  ];

  // Статусы
  static const List<String> bookingStatuses = [
    'pending',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled',
    'disputed',
  ];

  static const List<String> userStatuses = [
    'active',
    'inactive',
    'blocked',
    'pending',
    'suspended',
  ];

  static const List<String> specialistCategories = [
    'photographer',
    'videographer',
    'host',
    'musician',
    'content_creator',
    'photo_studio',
    'other',
  ];

  // Роли пользователей
  static const List<String> userRoles = [
    'admin',
    'moderator',
    'specialist',
    'organizer',
    'customer',
    'guest',
  ];

  // Разрешения
  static const List<String> permissions = [
    'users.manage',
    'roles.manage',
    'permissions.manage',
    'content.moderate',
    'analytics.view',
    'settings.manage',
    'system.manage',
    'users.moderate',
    'reports.view',
    'profile.manage',
    'services.manage',
    'bookings.manage',
    'content.upload',
    'events.manage',
    'proposals.create',
    'bookings.create',
    'reviews.create',
    'content.view',
  ];

  // Типы уведомлений
  static const List<String> notificationTypes = [
    'booking_update',
    'discount_offer',
    'proposal',
    'price_reminder',
    'system',
    'chat_message',
    'other',
  ];

  // Каналы уведомлений
  static const List<String> notificationChannels = ['in_app', 'push', 'email', 'sms'];

  // Типы отчетов
  static const List<String> reportTypes = [
    'financial',
    'user_activity',
    'performance',
    'booking_summary',
    'specialist_earnings',
    'other',
  ];

  // Форматы отчетов
  static const List<String> reportFormats = ['csv', 'pdf', 'json'];

  // Типы интеграций
  static const List<String> integrationTypes = [
    'api',
    'webhook',
    'sftp',
    'email',
    'sms',
    'payment',
    'calendar',
    'social',
    'analytics',
    'crm',
    'erp',
    'other',
  ];

  // Типы аутентификации
  static const List<String> authenticationTypes = [
    'none',
    'api_key',
    'basic',
    'bearer',
    'oauth2',
    'custom',
  ];

  // Статусы интеграций
  static const List<String> integrationStatuses = [
    'active',
    'inactive',
    'error',
    'maintenance',
    'deprecated',
  ];

  // Направления синхронизации
  static const List<String> syncDirections = ['inbound', 'outbound', 'bidirectional'];

  // Статусы синхронизации
  static const List<String> syncStatuses = [
    'pending',
    'in_progress',
    'completed',
    'failed',
    'cancelled',
  ];

  // Типы медиа
  static const List<String> mediaTypes = ['image', 'video', 'audio', 'document', 'other'];

  // Статусы контента
  static const List<String> contentStatuses = [
    'uploaded',
    'processing',
    'processed',
    'published',
    'archived',
    'error',
  ];

  // Типы галерей
  static const List<String> galleryTypes = [
    'portfolio',
    'event',
    'showcase',
    'archive',
    'temporary',
  ];

  // Типы обработки
  static const List<String> processingTypes = [
    'thumbnail',
    'resize',
    'compress',
    'watermark',
    'filter',
    'crop',
    'rotate',
    'convert',
  ];

  // Статусы обработки
  static const List<String> processingStatuses = [
    'pending',
    'in_progress',
    'completed',
    'failed',
    'cancelled',
  ];

  // Типы настроек
  static const List<String> settingTypes = [
    'string',
    'number',
    'boolean',
    'array',
    'object',
    'color',
    'url',
    'email',
    'date',
    'json',
  ];

  // Типы конфигураций
  static const List<String> configurationTypes = [
    'general',
    'ui',
    'api',
    'database',
    'security',
    'notifications',
    'payments',
    'integrations',
    'features',
    'environment',
  ];

  // Категории настроек
  static const List<String> settingCategories = [
    'general',
    'ui',
    'api',
    'database',
    'security',
    'notifications',
    'payments',
    'integrations',
    'features',
    'performance',
    'analytics',
    'backup',
    'cache',
    'logging',
  ];

  // Уровни логирования
  static const List<String> logLevels = ['debug', 'info', 'warning', 'error', 'critical'];

  // Типы разрешений
  static const List<String> permissionTypes = ['read', 'write', 'delete', 'manage', 'moderate'];

  // Окружения
  static const List<String> environments = ['development', 'staging', 'production', 'testing'];

  // Режимы темы
  static const List<String> themeModes = ['light', 'dark', 'system'];

  // Размеры экранов
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Анимации
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Отступы
  static const double smallPadding = 8;
  static const double mediumPadding = 16;
  static const double largePadding = 24;
  static const double extraLargePadding = 32;

  // Радиусы
  static const double smallRadius = 4;
  static const double mediumRadius = 8;
  static const double largeRadius = 12;
  static const double extraLargeRadius = 16;

  // Высоты
  static const double smallHeight = 32;
  static const double mediumHeight = 48;
  static const double largeHeight = 64;
  static const double extraLargeHeight = 80;

  // Ширины
  static const double smallWidth = 100;
  static const double mediumWidth = 200;
  static const double largeWidth = 300;
  static const double extraLargeWidth = 400;

  // Z-индексы
  static const int bottomSheetZIndex = 1000;
  static const int dialogZIndex = 2000;
  static const int snackbarZIndex = 3000;
  static const int tooltipZIndex = 4000;
  static const int overlayZIndex = 5000;
}
