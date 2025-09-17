/// Константы приложения
class AppConstants {
  // Название приложения
  static const String appName = 'Event Marketplace';
  static const String appVersion = '1.0.0';

  // API конфигурация
  static const String apiBaseUrl = 'https://api.eventmarketplace.com';
  static const int apiTimeoutSeconds = 30;

  // Firebase коллекции
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String bookingsCollection = 'bookings';
  static const String reviewsCollection = 'reviews';
  static const String specialistsCollection = 'specialists';
  static const String paymentsCollection = 'payments';
  static const String notificationsCollection = 'notifications';
  static const String chatsCollection = 'chats';

  // Лимиты
  static const int maxFileSizeMB = 10;
  static const int maxImageSizeMB = 5;
  static const int maxVideoSizeMB = 100;
  static const int maxParticipantsPerEvent = 1000;
  static const int maxEventsPerUser = 50;

  // Время кэширования
  static const Duration cacheExpiration = Duration(hours: 1);
  static const Duration imageCacheExpiration = Duration(days: 7);

  // UI константы
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Анимации
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Социальные сети
  static const String vkAppId = 'your_vk_app_id';
  static const String googleClientId = 'your_google_client_id';

  // Платежи
  static const String stripePublishableKey = 'your_stripe_key';
  static const String yooMoneyShopId = 'your_yoomoney_shop_id';

  // Карты
  static const String yandexMapsApiKey = 'your_yandex_maps_key';
  static const String googleMapsApiKey = 'your_google_maps_key';

  // Аналитика
  static const String firebaseAnalyticsEnabled = 'true';
  static const String crashlyticsEnabled = 'true';

  // Уведомления
  static const String fcmServerKey = 'your_fcm_server_key';
  static const String fcmSenderId = 'your_fcm_sender_id';
}
