class AppConstants {
  // API URLs
  static const String baseUrl = 'https://api.eventmarketplace.com';

  // Storage keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';

  // Default values
  static const int defaultPageSize = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // UI Constants
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 24;
  static const double borderRadius = 12;
  static const double cardElevation = 2;

  // Animation durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Error messages
  static const String networkErrorMessage =
      'Ошибка сети. Проверьте подключение к интернету.';
  static const String unknownErrorMessage = 'Произошла неизвестная ошибка.';
  static const String authErrorMessage = 'Ошибка авторизации.';

  // Success messages
  static const String successMessage = 'Операция выполнена успешно.';
  static const String profileUpdatedMessage = 'Профиль обновлен.';
  static const String passwordChangedMessage = 'Пароль изменен.';
}

